$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not ('System.Security.Cryptography.ProtectedData' -as [type])) {
    Add-Type -AssemblyName System.Security -ErrorAction Stop
}
if (-not ('System.Security.Cryptography.ProtectedData' -as [type])) {
    throw 'system-security-dpapi-unavailable'
}

$InboxRoot = 'C:\Users\Public\pcryoxy-xacct\inbox'
$OutboxRoot = 'C:\Users\Public\pcryoxy-xacct\outbox'
$ExchangeRoot = 'C:\Users\Public\pcryoxy-xacct\x'
$ExchangeZhnX = Join-Path $ExchangeRoot 'zhn_x'
$ExchangePcxT2 = Join-Path $ExchangeRoot 'pcx-t2'
$PublicRoot = 'C:\Users\Public\pcryoxy-xacct'
$ExpectedAccountSuffix = '\pcx-t2'
$W5CredentialPrefix = 'pCryoxy/pc03-xacct/'
$MaxRequestSeconds = 1500
$MaxCaseSeconds = 600
$MaxRequestBytes = 65536
$TaskKillPath = Join-Path $env:SystemRoot 'System32\taskkill.exe'

$TestMatrix = @{
    'tests::native_create_delete_distinct_targets_keep_new_credentials' = 'W4'
    'tests::concurrent_distinct_provisioning_preserves_all_live_keys' = 'W4'
    'tests::actual_cross_process_provisioning_and_commits_survive_test_cleanup' = 'W1'
    'tests::actual_windows_large_secret_restart_hmac_and_staging' = 'W1'
    'tests::missing_master_key_preserves_old_ciphertext_and_does_not_reprovision' = 'W2'
    'tests::authenticated_tamper_and_version_substitution_are_rejected' = 'W2'
    'tests::ambiguous_paths_and_unprotected_directories_are_refused' = 'W3'
    'tests::actual_junction_ancestor_is_refused' = 'W3'
    'tests::actual_ancestor_rename_is_blocked_while_guarded' = 'W3'
    'tests::independent_candidates_do_not_overwrite_old_versions' = 'W4'
    'tests::real_parallel_candidates_remain_independent' = 'W4'
    'tests::real_immutable_destination_collision_is_unknown_without_overwrite' = 'W4'
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Test-PlainDirectory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force
    return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0)
}

function Test-PlainPathAncestors([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($fullPath)
    $parts = $fullPath.Substring($root.Length).Split('\')
    $cursor = $root
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        $cursor = Join-Path $cursor $parts[$i]
        if (-not (Test-PlainDirectory $cursor)) { return $false }
    }
    return $true
}

function Get-LogonType {
    if (-not ('Pc03TokenStats' -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Pc03TokenStats {
    [StructLayout(LayoutKind.Sequential)] public struct LUID { public UInt32 LowPart; public Int32 HighPart; }
    [StructLayout(LayoutKind.Sequential)] public struct TOKEN_STATISTICS {
        public LUID TokenId; public LUID AuthenticationId; public Int64 ExpirationTime;
        public Int32 TokenType; public Int32 ImpersonationLevel; public UInt32 DynamicCharged;
        public UInt32 DynamicAvailable; public UInt32 GroupCount; public UInt32 PrivilegeCount; public LUID ModifiedId;
    }

    [StructLayout(LayoutKind.Sequential)] public struct TOKEN_ELEVATION { public UInt32 TokenIsElevated; }
    [DllImport("kernel32.dll")] public static extern IntPtr GetCurrentProcess();
    [DllImport("advapi32.dll", SetLastError=true)] public static extern bool OpenProcessToken(IntPtr process, UInt32 access, out IntPtr token);
    [DllImport("advapi32.dll", SetLastError=true)] public static extern bool GetTokenInformation(IntPtr token, Int32 infoClass, IntPtr info, UInt32 length, out UInt32 needed);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
}
"@
    }
    $token = [IntPtr]::Zero
    $buffer = [IntPtr]::Zero
    try {
        if (-not [Pc03TokenStats]::OpenProcessToken([Pc03TokenStats]::GetCurrentProcess(), 0x0008, [ref]$token)) { throw 'token-open' }
        [uint32]$needed = 0
        [void][Pc03TokenStats]::GetTokenInformation($token, 10, [IntPtr]::Zero, 0, [ref]$needed)
        $buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal([int]$needed)
        if (-not [Pc03TokenStats]::GetTokenInformation($token, 10, $buffer, $needed, [ref]$needed)) { throw 'token-stats' }
        $stats = [Runtime.InteropServices.Marshal]::PtrToStructure($buffer, [type][Pc03TokenStats+TOKEN_STATISTICS])
        $auth = ([int64]$stats.AuthenticationId.HighPart -shl 32) -bor [uint32]$stats.AuthenticationId.LowPart
        $logonId = [string]([uint64]$auth)
        $sessions = @(Get-CimInstance -ClassName Win32_LogonSession -ErrorAction Stop | Where-Object { [string]$_.LogonId -eq $logonId })
        if ($sessions.Count -ne 1) { throw 'logon-session-not-unique' }
        $typeNumber = [int]$sessions[0].LogonType
        $labels = @{ 2='Interactive'; 3='Network'; 4='Batch'; 5='Service'; 7='Unlock'; 8='NetworkCleartext'; 9='NewCredentials'; 10='RemoteInteractive'; 11='CachedInteractive'; 12='CachedRemoteInteractive'; 13='CachedUnlock' }
        if (-not $labels.ContainsKey($typeNumber)) { throw 'logon-type-unknown' }
        return [pscustomobject]@{ number = $typeNumber; name = $labels[$typeNumber]; logonId = $logonId }
    } finally {
        if ($buffer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer) }
        if ($token -ne [IntPtr]::Zero) { [void][Pc03TokenStats]::CloseHandle($token) }
    }
}

function ConvertTo-SidValue([string]$Name) {
    if ($Name -match '^S-\d+(?:-\d+)+$') { return $Name }
    try {
        return ([System.Security.Principal.NTAccount]::new($Name)).Translate(
            [System.Security.Principal.SecurityIdentifier]).Value
    } catch {
        throw 'acl-account-lookup-failed'
    }
}

function Test-DirectoryAcl(
    [string]$Path,
    [hashtable]$Expected,
    [bool]$Protected,
    [bool]$Inherited
) {
    if (-not (Test-PlainDirectory $Path)) { return 'directory-missing-or-reparse' }
    try {
        $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
        $ownerSid = ConvertTo-SidValue $acl.Owner
        if ($ownerSid -ne 'S-1-5-32-544') { return 'owner-mismatch' }
        if ($acl.AreAccessRulesProtected -ne $Protected) { return 'inheritance-state-mismatch' }
        $rules = @($acl.Access)
        if ($rules.Count -ne $Expected.Count) { return 'ace-count-mismatch' }
        $seen = @{}
        foreach ($rule in $rules) {
            $sid = $rule.IdentityReference.Translate(
                [System.Security.Principal.SecurityIdentifier]).Value
            if (-not $Expected.ContainsKey($sid) -or $seen.ContainsKey($sid)) { return 'unexpected-or-duplicate-ace' }
            $seen[$sid] = $true
            if ($rule.AccessControlType -ne [System.Security.AccessControl.AccessControlType]::Allow) {
                return 'non-allow-ace'
            }
            if ($rule.IsInherited -ne $Inherited) { return 'ace-inheritance-mismatch' }
            $rights = [int]$rule.FileSystemRights -band
                (-bnot [int][System.Security.AccessControl.FileSystemRights]::Synchronize)
            if ($rights -ne $Expected[$sid]) { return 'rights-mismatch' }
            $expectedInheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
            if ($rule.InheritanceFlags -ne $expectedInheritance -or
                $rule.PropagationFlags -ne [System.Security.AccessControl.PropagationFlags]::None) {
                return 'inheritance-flags-mismatch'
            }
        }
        foreach ($sid in $Expected.Keys) {
            if (-not $seen.ContainsKey($sid)) { return 'missing-ace' }
        }
        return $null
    } catch {
        return 'acl-read-failed'
    }
}

function Test-XacctAcl {
    $systemSid = 'S-1-5-18'
    $administratorsSid = 'S-1-5-32-544'
    $zhnSid = ConvertTo-SidValue "$env:COMPUTERNAME\Zhn_X"
    $pcxSid = ConvertTo-SidValue "$env:COMPUTERNAME\pcx-t2"
    $full = [int][System.Security.AccessControl.FileSystemRights]::FullControl -band
        (-bnot [int][System.Security.AccessControl.FileSystemRights]::Synchronize)
    $modify = [int][System.Security.AccessControl.FileSystemRights]::Modify -band
        (-bnot [int][System.Security.AccessControl.FileSystemRights]::Synchronize)
    $read = [int][System.Security.AccessControl.FileSystemRights]::ReadAndExecute -band
        (-bnot [int][System.Security.AccessControl.FileSystemRights]::Synchronize)
    $checks = @(
        @{ path = $PublicRoot; protected = $true; inherited = $false; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$modify; $pcxSid=$read } },
        @{ path = $InboxRoot; protected = $false; inherited = $true; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$modify; $pcxSid=$read } },
        @{ path = $OutboxRoot; protected = $true; inherited = $false; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$read; $pcxSid=$modify } },
        @{ path = $ExchangeRoot; protected = $true; inherited = $false; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$read; $pcxSid=$read } },
        @{ path = $ExchangeZhnX; protected = $true; inherited = $false; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$modify; $pcxSid=$read } },
        @{ path = $ExchangePcxT2; protected = $true; inherited = $false; rules = @{ $systemSid=$full; $administratorsSid=$full; $zhnSid=$read; $pcxSid=$modify } }
    )
    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($check in $checks) {
        $errorCode = Test-DirectoryAcl $check.path $check.rules $check.protected $check.inherited
        if ($null -ne $errorCode) {
            $failures.Add(($check.path.Substring($PublicRoot.Length).TrimStart('\') + ':' + $errorCode))
        }
    }
    return [pscustomobject]@{ checked = $true; ok = ($failures.Count -eq 0); failures = @($failures) }
}

function Get-TokenElevation {
    $token = [IntPtr]::Zero
    $buffer = [IntPtr]::Zero
    try {
        if (-not [Pc03TokenStats]::OpenProcessToken([Pc03TokenStats]::GetCurrentProcess(), 0x0008, [ref]$token)) { throw 'token-open' }
        [uint32]$needed = 0
        [void][Pc03TokenStats]::GetTokenInformation($token, 20, [IntPtr]::Zero, 0, [ref]$needed)
        if ($needed -lt 4) { throw 'token-elevation-size' }
        $buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal([int]$needed)
        if (-not [Pc03TokenStats]::GetTokenInformation($token, 20, $buffer, $needed, [ref]$needed)) { throw 'token-elevation' }
        $elevation = [Runtime.InteropServices.Marshal]::PtrToStructure($buffer, [type][Pc03TokenStats+TOKEN_ELEVATION])
        return ($elevation.TokenIsElevated -ne 0)
    } finally {
        if ($buffer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer) }
        if ($token -ne [IntPtr]::Zero) { [void][Pc03TokenStats]::CloseHandle($token) }
    }
}

function Test-DpapiRoundTrip {
    $source = New-Object byte[] 32
    $protected = $null
    $clear = $null
    try {
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($source) } finally { $rng.Dispose() }
        $protected = [Security.Cryptography.ProtectedData]::Protect($source, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
        $clear = [Security.Cryptography.ProtectedData]::Unprotect($protected, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
        if ([Convert]::ToBase64String($source) -ne [Convert]::ToBase64String($clear)) { return [pscustomobject]@{ ok = $false; code = 'dpapi-mismatch' } }
        return [pscustomobject]@{ ok = $true; code = 'ok' }
    } catch {
        return [pscustomobject]@{ ok = $false; code = 'dpapi-unavailable' }
    } finally {
        [Array]::Clear($source, 0, $source.Length)
        if ($null -ne $protected) { [Array]::Clear($protected, 0, $protected.Length) }
        if ($null -ne $clear) { [Array]::Clear($clear, 0, $clear.Length) }
    }
}

function Test-CredentialManagerRoundTrip {
    if (-not ('Pc03CredentialProbe' -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Pc03CredentialProbe {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CREDENTIAL {
        public UInt32 Flags; public UInt32 Type;
        [MarshalAs(UnmanagedType.LPWStr)] public string TargetName;
        [MarshalAs(UnmanagedType.LPWStr)] public string Comment;
        public Int64 LastWritten; public UInt32 CredentialBlobSize; public IntPtr CredentialBlob;
        public UInt32 Persist; public UInt32 AttributeCount; public IntPtr Attributes;
        [MarshalAs(UnmanagedType.LPWStr)] public string TargetAlias;
        [MarshalAs(UnmanagedType.LPWStr)] public string UserName;
    }
    [DllImport("advapi32.dll", EntryPoint="CredWriteW", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool CredWrite(ref CREDENTIAL credential, UInt32 flags);
    [DllImport("advapi32.dll", EntryPoint="CredReadW", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool CredRead(string target, UInt32 type, UInt32 flags, out IntPtr credential);
    [DllImport("advapi32.dll", EntryPoint="CredDeleteW", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool CredDelete(string target, UInt32 type, UInt32 flags);
    [DllImport("advapi32.dll")] public static extern void CredFree(IntPtr buffer);
    public static bool RoundTrip(byte[] bytes, string target, out int error, out int cleanupRetries, out bool residual) {
        error = 0;
        cleanupRetries = 0;
        residual = false;
        bool attempted = false;
        bool okay = false;
        GCHandle pin = GCHandle.Alloc(bytes, GCHandleType.Pinned);
        try {
            IntPtr existing;
            if (CredRead(target, 1, 0, out existing)) {
                CredFree(existing);
                error = -3;
                residual = true;
                return false;
            }
            int existingError = Marshal.GetLastWin32Error();
            if (existingError != 1168) { error = existingError; return false; }
            attempted = true;
            CREDENTIAL c = new CREDENTIAL(); c.Type = 1; c.TargetName = target; c.UserName = "synthetic-probe";
            c.CredentialBlobSize = (UInt32)bytes.Length; c.CredentialBlob = pin.AddrOfPinnedObject(); c.Persist = 1;
            if (!CredWrite(ref c, 0)) { error = Marshal.GetLastWin32Error(); }
            else {
                IntPtr p;
                if (!CredRead(target, 1, 0, out p)) { error = Marshal.GetLastWin32Error(); }
                else {
                    try {
                        CREDENTIAL read = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
                        if (read.CredentialBlobSize != bytes.Length) { error = -1; }
                        else {
                            byte[] copy = new byte[bytes.Length]; Marshal.Copy(read.CredentialBlob, copy, 0, copy.Length);
                            okay = true;
                            for (int i=0; i<copy.Length; i++) if (copy[i] != bytes[i]) { error = -2; okay = false; break; }
                        }
                    } finally { CredFree(p); }
                }
            }
        } finally {
            pin.Free();
            if (attempted) {
                if (!CredDelete(target, 1, 0) && Marshal.GetLastWin32Error() != 1168) {
                    cleanupRetries++;
                    if (!CredDelete(target, 1, 0) && Marshal.GetLastWin32Error() != 1168) {
                        error = Marshal.GetLastWin32Error();
                        okay = false;
                    }
                }
                IntPtr remaining;
                if (CredRead(target, 1, 0, out remaining)) {
                    CredFree(remaining);
                    residual = true;
                    okay = false;
                } else {
                    int verifyError = Marshal.GetLastWin32Error();
                    if (verifyError != 1168) {
                        error = verifyError;
                        okay = false;
                    }
                }
            }
        }
        return okay;
    }
}
"@
    }
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    $target = $W5CredentialPrefix + 'probe/' + [Guid]::NewGuid().ToString('N')
    [int]$errorCode = 0
    [int]$cleanupRetries = 0
    [bool]$residual = $false
    $ok = [Pc03CredentialProbe]::RoundTrip($bytes, $target, [ref]$errorCode, [ref]$cleanupRetries, [ref]$residual)
    if (-not $ok) {
        $code = if ($residual) { 'credential-manager-residual-target' } else { 'credential-manager-' + $errorCode }
        return [pscustomobject]@{
            ok = $false; code = $code; cleanupRetries = $cleanupRetries
            residualCredentialTarget = $(if ($residual) { $target } else { $null })
        }
    }
    return [pscustomobject]@{
        ok = $true; code = 'ok'; cleanupRetries = $cleanupRetries; residualCredentialTarget = $null
    }
}

function Write-Rejected([string]$ResultRoot, [string]$Id, [string]$Code) {
    $marker = Join-Path $ResultRoot ($Id + '.rejected')
    if (-not (Test-Path -LiteralPath $marker)) { Write-Utf8NoBom $marker ($Code + "`n") }
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Invoke-FixedTest(
    [string]$Binary,
    [string]$CaseName,
    [string]$OutputDirectory,
    [int]$TimeoutSeconds,
    [bool]$Ignored = $false,
    [hashtable]$Environment = @{}
) {
    $start = [DateTime]::UtcNow
    $stdoutPath = Join-Path $OutputDirectory ($CaseName.Replace('::', '__') + '.stdout.txt')
    $stderrPath = Join-Path $OutputDirectory ($CaseName.Replace('::', '__') + '.stderr.txt')
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Binary
    $ignoredArgument = if ($Ignored) { '--ignored ' } else { '' }
    $psi.Arguments = $ignoredArgument + '--exact ' + $CaseName + ' --nocapture'
    $psi.WorkingDirectory = $OutputDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($name in $Environment.Keys) { $psi.EnvironmentVariables[$name] = [string]$Environment[$name] }
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    if (-not $proc.Start()) { throw 'test-process-start-failed' }
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $finished = $proc.WaitForExit($TimeoutSeconds * 1000)
    $killError = $null
    if (-not $finished) {
        if (Test-Path -LiteralPath $TaskKillPath) {
            try {
                $killerInfo = New-Object System.Diagnostics.ProcessStartInfo
                $killerInfo.FileName = $TaskKillPath
                $killerInfo.Arguments = '/PID ' + $proc.Id + ' /T /F'
                $killerInfo.UseShellExecute = $false
                $killerInfo.CreateNoWindow = $true
                $killer = [System.Diagnostics.Process]::Start($killerInfo)
                if ($killer) {
                    try {
                        if (-not $killer.WaitForExit(5000)) {
                            $killError = 'taskkill-timeout'
                        } elseif ($killer.ExitCode -ne 0) {
                            $killError = 'taskkill-exit-' + $killer.ExitCode
                        }
                    } finally { $killer.Dispose() }
                }
            } catch { $killError = 'taskkill-' + $_.Exception.Message }
        }
        try {
            if (-not $proc.HasExited) { $proc.Kill() }
        } catch {
            if ($null -eq $killError) { $killError = 'process-kill-' + $_.Exception.Message }
        }
        [void]$proc.WaitForExit(5000)
        if (-not $proc.HasExited) {
            if ($null -eq $killError) {
                $killError = 'process-still-running-after-timeout'
            } else {
                $killError += ';process-still-running-after-timeout'
            }
        }
    }
    $stdout = if ($stdoutTask.Wait(5000)) { $stdoutTask.GetAwaiter().GetResult() } else { 'stdout collection timed out' }
    $stderr = if ($stderrTask.Wait(5000)) { $stderrTask.GetAwaiter().GetResult() } else { 'stderr collection timed out' }
    Write-Utf8NoBom $stdoutPath $stdout
    Write-Utf8NoBom $stderrPath $stderr
    $elapsed = [int]([DateTime]::UtcNow - $start).TotalMilliseconds
    $exitCode = if ($finished) { $proc.ExitCode } else { 124 }
    $proc.Dispose()
    $matrixItem = if ($TestMatrix.ContainsKey($CaseName)) { $TestMatrix[$CaseName] } else { 'W5' }
    return [pscustomobject]@{
        case = $CaseName; matrixItem = $matrixItem; status = $(if ($finished -and $exitCode -eq 0 -and $stdout -match 'test result: ok\. 1 passed;') { 'PASS' } elseif ($finished) { 'FAIL' } else { 'TIMEOUT' })
        exitCode = $exitCode; elapsedMs = $elapsed; stdout = $stdoutPath; stderr = $stderrPath
        processError = $killError
    }
}

function Get-W5TestResult($Outcome) {
    $resultStatus = $null
    $checks = New-Object System.Collections.Generic.List[object]
    $metadata = @{}
    if (Test-Path -LiteralPath $Outcome.stdout -PathType Leaf) {
        foreach ($line in [IO.File]::ReadAllLines($Outcome.stdout)) {
            $parts = $line.Split("`t")
            if ($parts.Length -eq 2 -and $parts[0] -ceq 'PC03_W5_RESULT') {
                $resultStatus = $parts[1]
            } elseif ($parts.Length -eq 5 -and $parts[0] -ceq 'PC03_W5_CHECK') {
                $checks.Add([pscustomobject]@{
                    name = $parts[1]; expected = $parts[2]; actual = $parts[3]; errorCode = $parts[4]
                })
            } elseif ($parts.Length -eq 3 -and $parts[0] -ceq 'PC03_W5_META') {
                $metadata[$parts[1]] = $parts[2]
            }
        }
    }
    $status = if ($Outcome.status -eq 'PASS' -and $resultStatus -eq 'PASS' -and $checks.Count -gt 0 -and
        @($checks | Where-Object { $_.expected -cne $_.actual }).Count -eq 0) { 'PASS' } else { 'FAIL' }
    return [pscustomobject]@{
        case = $Outcome.case; status = $status; exitCode = $Outcome.exitCode
        elapsedMs = $Outcome.elapsedMs; checks = $checks.ToArray(); metadata = $metadata
        stdout = $Outcome.stdout; stderr = $Outcome.stderr; processError = $Outcome.processError
        structuredStatus = $resultStatus
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentAccount = if ($identity.Name.EndsWith('\Zhn_X', [StringComparison]::OrdinalIgnoreCase)) {
    'Zhn_X'
} elseif ($identity.Name.EndsWith($ExpectedAccountSuffix, [StringComparison]::OrdinalIgnoreCase)) {
    'pcx-t2'
} else {
    Write-Error 'runner-account-unsupported'
    exit 2
}
$ResultRoot = if ($currentAccount -eq 'Zhn_X') { $InboxRoot } else { $OutboxRoot }
if (-not (Test-PlainDirectory $InboxRoot) -or -not (Test-PlainDirectory $OutboxRoot)) {
    Write-Error 'exchange-inbox-or-outbox-unavailable'
    exit 2
}

$requests = @(Get-ChildItem -LiteralPath $InboxRoot -Filter '*.request.json' -File -Force | Sort-Object Name)
foreach ($file in $requests) {
    if ($file.Name -notmatch '^([a-f0-9]{32})\.request\.json$') { continue }
    $id = $Matches[1]
    $doneMarker = Join-Path $ResultRoot ($id + '.done')
    $rejectedMarker = Join-Path $ResultRoot ($id + '.rejected')
    $runningMarker = Join-Path $ResultRoot ($id + '.running')
    if ((Test-Path -LiteralPath $doneMarker) -or (Test-Path -LiteralPath $rejectedMarker) -or
        (Test-Path -LiteralPath $runningMarker)) { continue }
    if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $file.Length -gt $MaxRequestBytes) {
        Write-Rejected $ResultRoot $id 'invalid-request-file'
        continue
    }

    try {
        $requestText = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
        $request = ConvertFrom-Json -InputObject $requestText -ErrorAction Stop
        if ($null -eq $request -or $request -isnot [pscustomobject]) { throw 'schema' }
        if ($request.runAs -is [string] -and $request.runAs -in @('pcx-t2', 'Zhn_X') -and
            $request.runAs -cne $currentAccount) { continue }
        if (($request.schemaVersion -isnot [int] -and $request.schemaVersion -isnot [long]) -or
            $request.schemaVersion -ne 2 -or $request.id -isnot [string] -or $request.id -cne $id -or
            $request.phase -isnot [string] -or $request.phase -notin @('tests', 'write-own', 'read-foreign', 'cleanup') -or
            $request.runAs -isnot [string] -or $request.runAs -cne $currentAccount) { throw 'schema' }

        $names = @($request.PSObject.Properties.Name | Sort-Object)
        $required = @('binaryRelativePath', 'cases', 'commit', 'id', 'phase', 'runAs', 'schemaVersion', 'sha256')
        if ($request.phase -eq 'read-foreign') { $required += @('fixtureId', 'foreignAccount') }
        if ($request.phase -eq 'cleanup') { $required += 'fixtureId' }
        $required = @($required | Sort-Object)
        if (($names -join '|') -cne ($required -join '|')) { throw 'schema' }
        if ($request.cases -isnot [array]) { throw 'case-list' }
        if ($request.commit -isnot [string] -or $request.commit -cnotmatch '^[a-f0-9]{40,64}$') {
            throw 'commit-format'
        }
        if ($request.binaryRelativePath -isnot [string] -or
            $request.binaryRelativePath -cnotmatch ('^bin\\' + [regex]::Escape($request.commit) + '\\[A-Za-z0-9._-]+\.exe$')) {
            throw 'binary-path-format'
        }
        if ($request.sha256 -isnot [string] -or $request.sha256 -cnotmatch '^[a-f0-9]{64}$') {
            throw 'hash-format'
        }
        if ($request.phase -eq 'tests') {
            if ($currentAccount -ne 'pcx-t2' -or $request.cases.Count -lt 1 -or $request.cases.Count -gt 12) {
                throw 'case-list'
            }
            $seen = @{}
            foreach ($case in $request.cases) {
                if ($case -isnot [string] -or -not $TestMatrix.ContainsKey($case) -or $seen.ContainsKey($case)) {
                    throw 'case-not-allowlisted'
                }
                $seen[$case] = $true
            }
        } elseif ($request.cases.Count -ne 0) {
            throw 'case-list'
        }
        if ($request.phase -eq 'read-foreign' -or $request.phase -eq 'cleanup') {
            if ($request.fixtureId -isnot [string] -or $request.fixtureId -cnotmatch '^[a-f0-9]{32}$') {
                throw 'fixture-id-invalid'
            }
        }
        if ($request.phase -eq 'read-foreign') {
            $expectedForeign = if ($currentAccount -eq 'Zhn_X') { 'pcx-t2' } else { 'Zhn_X' }
            if ($request.foreignAccount -isnot [string] -or $request.foreignAccount -cne $expectedForeign) {
                throw 'foreign-account-invalid'
            }
        }

        $binary = Join-Path $InboxRoot $request.binaryRelativePath
        $fullRoot = [IO.Path]::GetFullPath($InboxRoot).TrimEnd('\') + '\'
        $fullBinary = [IO.Path]::GetFullPath($binary)
        if (-not $fullBinary.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'binary-path-escape'
        }
        if (-not (Test-Path -LiteralPath $binary -PathType Leaf) -or -not (Test-PlainPathAncestors $binary)) {
            throw 'binary-missing-or-path-invalid'
        }
        $binaryItem = Get-Item -LiteralPath $binary -Force
        if (($binaryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'binary-reparse-point' }
        if ((Get-Sha256 $binary) -cne $request.sha256) { throw 'binary-hash-mismatch' }
        $stream = [IO.File]::Open($runningMarker, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $stream.Dispose()
    } catch {
        $code = switch -Exact ($_.Exception.Message) {
            'schema' { 'schema' }
            'case-list' { 'case-list' }
            'case-not-allowlisted' { 'case-not-allowlisted' }
            'commit-format' { 'commit-format' }
            'binary-path-format' { 'binary-path-format' }
            'hash-format' { 'hash-format' }
            'fixture-id-invalid' { 'fixture-id-invalid' }
            'foreign-account-invalid' { 'foreign-account-invalid' }
            'binary-path-escape' { 'binary-path-escape' }
            'binary-missing-or-path-invalid' { 'binary-missing-or-path-invalid' }
            'binary-reparse-point' { 'binary-reparse-point' }
            'binary-hash-mismatch' { 'binary-hash-mismatch' }
            default { 'invalid-request' }
        }
        Write-Rejected $ResultRoot $id $code
        continue
    }

    $package = Join-Path $ResultRoot ($id + '.result')
    if (Test-Path -LiteralPath $package) {
        Write-Rejected $ResultRoot $id 'output-exists'
        Remove-Item -LiteralPath $runningMarker -Force
        continue
    }
    [void](New-Item -ItemType Directory -Path $package)
    $rawDir = Join-Path $package 'raw'
    [void](New-Item -ItemType Directory -Path $rawDir)

    $sid = $identity.User.Value
    $user = $identity.Name
    $whoamiPath = Join-Path $env:SystemRoot 'System32\whoami.exe'
    $whoamiUserOutput = (& $whoamiPath /user | Out-String)
    $whoamiExitCode = $LASTEXITCODE
    $whoamiSids = @([regex]::Matches($whoamiUserOutput, 'S-1-\d+(?:-\d+)+') | ForEach-Object { $_.Value })
    $whoamiSid = if ($whoamiSids.Count -eq 1) { $whoamiSids[0] } else { $null }
    $whoamiGroupsOutput = (& $whoamiPath /groups | Out-String)
    $whoamiGroupsExitCode = $LASTEXITCODE
    $mandatoryLabels = @([regex]::Matches($whoamiGroupsOutput, 'S-1-16-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
    $mandatoryLabelSid = if ($mandatoryLabels.Count -eq 1) { $mandatoryLabels[0] } else { $null }
    Write-Utf8NoBom (Join-Path $rawDir 'whoami-user.stdout.txt') $whoamiUserOutput
    Write-Utf8NoBom (Join-Path $rawDir 'whoami-groups.stdout.txt') $whoamiGroupsOutput

    $logon = $null
    $tokenElevated = $null
    $exchangeAcl = [pscustomobject]@{ checked = $false; ok = $null; failures = @() }
    $dpapi = [pscustomobject]@{ ok = $false; code = 'not-run' }
    $credentialManager = [pscustomobject]@{ ok = $false; code = 'not-run' }
    $preflightError = $null
    try { $logon = Get-LogonType } catch { $preflightError = 'logon-type-unavailable' }
    try { $tokenElevated = Get-TokenElevation } catch {
        if ($null -eq $preflightError) { $preflightError = 'token-elevation-unavailable' }
    }
    if ($whoamiExitCode -ne 0 -or $whoamiSid -cne $sid) {
        if ($null -eq $preflightError) { $preflightError = 'whoami-sid-unavailable-or-mismatch' }
    }
    if ($null -eq $preflightError -and $user.EndsWith($ExpectedAccountSuffix, [StringComparison]::OrdinalIgnoreCase) -ne ($currentAccount -eq 'pcx-t2')) {
        $preflightError = 'unexpected-account'
    }
    if ($null -eq $preflightError -and $logon.number -notin @(2, 4)) { $preflightError = 'unsupported-logon-type' }
    if ($null -eq $preflightError -and $request.phase -ne 'tests' -and $currentAccount -eq 'pcx-t2' -and $logon.number -ne 4) {
        $preflightError = 'pcx-t2-requires-batch-logon'
    }
    if ($null -eq $preflightError -and $currentAccount -eq 'Zhn_X' -and
        ($logon.number -ne 2 -or $tokenElevated -ne $false -or
            $whoamiGroupsExitCode -ne 0 -or $null -eq $mandatoryLabelSid)) {
        $preflightError = 'zhn-x-requires-non-elevated-interactive-token'
    }
    try {
        $exchangeAcl = Test-XacctAcl
        if (-not $exchangeAcl.ok -and $null -eq $preflightError) { $preflightError = 'exchange-acl-mismatch' }
    } catch {
        $exchangeAcl = [pscustomobject]@{ checked = $true; ok = $false; failures = @($_.Exception.Message) }
        if ($null -eq $preflightError) { $preflightError = 'exchange-acl-check-failed' }
    }
    if ($null -eq $preflightError) {
        try { $dpapi = Test-DpapiRoundTrip } catch {
            $dpapi = [pscustomobject]@{ ok = $false; code = 'dpapi-unavailable' }
        }
        try { $credentialManager = Test-CredentialManagerRoundTrip } catch {
            $credentialManager = [pscustomobject]@{
                ok = $false; code = 'credential-manager-unavailable'; cleanupRetries = 0
                residualCredentialTarget = $null
            }
        }
    }
    if ($null -eq $preflightError -and -not $dpapi.ok) { $preflightError = $dpapi.code }
    if ($null -eq $preflightError -and -not $credentialManager.ok) {
        $preflightError = $credentialManager.code
    }
    $preflightOk = ($null -ne $logon -and $null -ne $tokenElevated -and $null -eq $preflightError -and
        $dpapi.ok -and $credentialManager.ok -and $exchangeAcl.ok)
    $preflight = [pscustomobject]@{
        status = $(if ($preflightOk) { 'READY' } else { 'ENV_BLOCKED' }); user = $user; sid = $sid
        logonType = $logon; tokenIsElevated = $tokenElevated
        whoamiUserOutput = $whoamiUserOutput; whoamiUserSid = $whoamiSid; whoamiExitCode = $whoamiExitCode
        whoamiGroupsOutput = $whoamiGroupsOutput; whoamiGroupsExitCode = $whoamiGroupsExitCode
        mandatoryLabelSid = $mandatoryLabelSid; exchangeAcl = $exchangeAcl
        dpapi = $dpapi; credentialManager = $credentialManager; error = $preflightError
    }
    Write-Utf8NoBom (Join-Path $package 'preflight.json') ($preflight | ConvertTo-Json -Depth 8)

    $manifestOutcomes = @()
    if ($request.phase -eq 'tests') {
        $rows = New-Object System.Collections.Generic.List[string]
        $rows.Add("matrixItem`tcase`tstatus`texitCode`telapsedMs")
        $outcomes = New-Object System.Collections.Generic.List[object]
        $requestStart = [DateTime]::UtcNow
        foreach ($case in $request.cases) {
            $remaining = $MaxRequestSeconds - [int]([DateTime]::UtcNow - $requestStart).TotalSeconds
            if (-not $preflightOk) {
                $outcome = [pscustomobject]@{
                    case = $case; matrixItem = $TestMatrix[$case]; status = 'ENV_BLOCKED'
                    exitCode = ''; elapsedMs = 0; stdout = ''; stderr = ''; processError = $null
                }
            } elseif ($remaining -le 0) {
                $outcome = [pscustomobject]@{
                    case = $case; matrixItem = $TestMatrix[$case]; status = 'TIMEOUT'
                    exitCode = 124; elapsedMs = 0; stdout = ''; stderr = ''; processError = $null
                }
            } else {
                $limit = [Math]::Min($MaxCaseSeconds, $remaining)
                $outcome = Invoke-FixedTest $binary $case $rawDir $limit
            }
            $outcomes.Add($outcome)
            $rows.Add(($outcome.matrixItem + "`t" + $outcome.case + "`t" + $outcome.status + "`t" +
                $outcome.exitCode + "`t" + $outcome.elapsedMs))
        }
        Write-Utf8NoBom (Join-Path $package 'results.tsv') (($rows -join "`n") + "`n")
        $manifestOutcomes = @($outcomes | ForEach-Object {
            [pscustomobject]@{
                matrixItem = $_.matrixItem; case = $_.case; status = $_.status
                exitCode = $_.exitCode; elapsedMs = $_.elapsedMs; processError = $_.processError
            }
        })
    } elseif (-not $preflightOk) {
        $stageResult = [pscustomobject]@{ status = 'ENV_BLOCKED'; error = $preflight.error; checks = @() }
        $manifestOutcomes = @($stageResult)
        Write-Utf8NoBom (Join-Path $package 'results.json') ($stageResult | ConvertTo-Json -Depth 8)
    } else {
        $fixtureId = if ($request.phase -eq 'write-own') { $id } else { $request.fixtureId }
        $w5Action = if ($request.phase -eq 'cleanup') { 'cleanup' } else { $request.phase }
        $w5Environment = @{
            PC03_W5_ID = $fixtureId
            PC03_W5_ACCOUNT = $currentAccount
            PC03_W5_ACTION = $w5Action
            PC03_W5_ACCOUNT_SID = $sid
            PC03_W5_CREDENTIAL_PREFIX = $W5CredentialPrefix
        }
        if ($request.phase -eq 'read-foreign') {
            $w5Environment.PC03_W5_FOREIGN_ACCOUNT = $request.foreignAccount
        }
        $w5Cases = if ($request.phase -eq 'read-foreign') {
            @('tests::w5_read_foreign')
        } elseif ($request.phase -eq 'cleanup') {
            @('tests::w5_read_foreign', 'tests::w5_write_own')
        } else {
            @('tests::w5_write_own')
        }
        $w5Results = New-Object System.Collections.Generic.List[object]
        foreach ($case in $w5Cases) {
            $outcome = Invoke-FixedTest $binary $case $rawDir $MaxCaseSeconds $true $w5Environment
            $w5Results.Add((Get-W5TestResult $outcome))
        }
        $phaseStatus = if (@($w5Results | Where-Object { $_.status -ne 'PASS' }).Count -eq 0) { 'PASS' } else { 'FAIL' }
        $stageResult = [pscustomobject]@{
            status = $phaseStatus; phase = $request.phase; fixtureId = $fixtureId; runAs = $currentAccount
            checks = $w5Results.ToArray()
        }
        $manifestOutcomes = @($stageResult)
        Write-Utf8NoBom (Join-Path $package 'results.json') ($stageResult | ConvertTo-Json -Depth 10)
    }

    $manifest = [pscustomobject]@{
        schemaVersion = 2; requestId = $id; phase = $request.phase; runAs = $request.runAs
        createdUtc = [DateTime]::UtcNow.ToString('o'); commit = $request.commit
        binaryRelativePath = $request.binaryRelativePath; binarySha256 = $request.sha256; user = $user; sid = $sid
        fixtureId = $(if ($request.PSObject.Properties.Name -contains 'fixtureId') { $request.fixtureId } else { $null })
        logonType = $logon; tokenIsElevated = $tokenElevated; mandatoryLabelSid = $mandatoryLabelSid
        preflightStatus = $preflight.status; maxRequestSeconds = $MaxRequestSeconds; maxCaseSeconds = $MaxCaseSeconds
        outcomes = $manifestOutcomes
    }
    Write-Utf8NoBom (Join-Path $package 'manifest.json') ($manifest | ConvertTo-Json -Depth 10)
    $hashLines = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $package -File -Recurse | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($package.Length + 1).Replace('\', '/')
        $hashLines.Add(((Get-Sha256 $_.FullName) + '  ' + $relative))
    }
    Write-Utf8NoBom (Join-Path $package 'hashes.sha256') (($hashLines -join "`n") + "`n")
    $hashOfList = Get-Sha256 (Join-Path $package 'hashes.sha256')
    Write-Utf8NoBom $doneMarker ($hashOfList + "`n")
    Remove-Item -LiteralPath $runningMarker -Force
}
