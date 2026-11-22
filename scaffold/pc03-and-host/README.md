# PC-03 Android test host

This scaffold compiles the product `SecretStore.kt` and
`SecretStoreDeviceChecks.kt` in the same Kotlin invocation as the host. It does
not modify product files or install dependencies.

## Build

From PowerShell:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' `
  'C:\Users\Zhn_X\.agent-shared\scaffold\pc03-and-host\build.sh' `
  'C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03' `
  'C:\Users\Zhn_X\.agent-shared\tmp\copilot\9c3b77d9-71d5-42cb-8b89-694c4ab7ac59\pc03-and-host'
```

`build.cmd` accepts the same two arguments. The output directory must be new
and outside the project worktree. The build uses the installed JDK 21,
Kotlin 2.3.21 compiler, Android API 36 platform, and build-tools 36.0.0.
The batch file sets `JAVA_HOME` to that JDK only in its child process so
`apksigner` uses the same runtime; it does not change user or system settings.
An existing local Android debug keystore is used when available; the script
does not create or replace a signing key. A custom test key can be selected
with `PC03_TEST_KEYSTORE`, `PC03_TEST_KEY_ALIAS`, `PC03_TEST_STORE_PASS`, and
`PC03_TEST_KEY_PASS` environment variables. Password values are read by
`apksigner` through environment-variable references and are not written to
the script or repository. Without a local test key, compilation and APK
packaging finish but signing exits as blocked. No Gradle build, network
access, package installation, or product-project changes are performed.

The resulting `apk\pc03-host.apk` is a test-only instrumentation APK. It
targets API 29+, uses target SDK 36, and includes Kotlin stdlib in `classes.dex`.

## Device run

The phone must be awake and unlocked before installation. Check `adb
get-state`, `dumpsys power` (`mWakefulness=Awake`), and
`dumpsys window` (`isStatusBarKeyguard=false`) first. Installation has a
90-second timeout; a timeout while the phone is locked is an environment
block, not a product test failure. Use component
`app.pcryoxy.andhost/.HostInstrumentation`. The `recover-pending` phase creates
a stale pending file, writes the version again, and verifies the pending file
is removed and the committed value reopens.
`am instrument` can return exit code 0 even when a phase reports failure, so
exit status alone is not sufficient. Each phase must exit 0 and report
`INSTRUMENTATION_CODE: -1`, `INSTRUMENTATION_STATUS: result=PASS`, and
`INSTRUMENTATION_RESULT: result=PASS`.

```powershell
$adb = 'C:\Users\Zhn_X\.agent-tools\android-sdk\platform-tools\adb.exe'
$apk = '<output-directory>\apk\pc03-host.apk'
$install = Start-Process -FilePath $adb -ArgumentList @('install', '--no-incremental', '-r', '-t', '-g', $apk) -NoNewWindow -PassThru
if (-not $install.WaitForExit(90000)) {
    $install.Kill()
    'ENV_BLOCKED: install timed out'
    exit 2
}
if ($install.ExitCode -ne 0) { exit $install.ExitCode }

function Invoke-HostPhase([string]$Phase, [string[]]$Extra = @()) {
    $adbArgs = @('shell', 'am', 'instrument', '-w', '-e', 'phase', $Phase)
    for ($i = 0; $i -lt $Extra.Length; $i += 2) {
        $adbArgs += @('-e', $Extra[$i], $Extra[$i + 1])
    }
    $adbArgs += 'app.pcryoxy.andhost/.HostInstrumentation'
    $lines = & $adb @adbArgs 2>&1
    $exitCode = $LASTEXITCODE
    $text = $lines -join "`n"
    if ($exitCode -ne 0 -or $text -notmatch 'INSTRUMENTATION_CODE: -1' -or
        $text -notmatch 'INSTRUMENTATION_STATUS: result=PASS' -or
        $text -notmatch 'INSTRUMENTATION_RESULT: result=PASS') {
        throw "instrumentation phase $Phase failed"
    }
    return $text
}

Invoke-HostPhase 'recover-pending' | Out-Host
$prepare = Invoke-HostPhase 'prepare'
$prepare | Out-Host
& $adb reboot
& $adb wait-for-device
$deadline = (Get-Date).AddMinutes(3)
do {
    Start-Sleep -Seconds 2
    $boot = (& $adb shell getprop sys.boot_completed | Out-String).Trim()
    if ((Get-Date) -ge $deadline -and $boot -ne '1') {
        'ENV_BLOCKED: device did not finish booting'
        exit 2
    }
} until ($boot -eq '1')
$awake = & $adb shell dumpsys power | Select-String 'mWakefulness=Awake'
$unlocked = & $adb shell dumpsys window | Select-String 'isStatusBarKeyguard=false'
if (-not $awake -or -not $unlocked) {
    'ENV_BLOCKED: unlock the device before verify and cleanup'
    exit 2
}
$verify = Invoke-HostPhase 'verify'
$verify | Out-Host
Invoke-HostPhase 'cleanup' | Out-Null
```

The host persists only the random namespace, 16-byte version, and ciphertext
SHA-256 proof under its private no-backup directory. `prepare` and `verify`
report the ciphertext SHA-256 without printing plaintext or key aliases.
`cleanup` removes the test aliases, vault directory, lock file, and proof file.
The APK, dex files, and raw logs must remain outside Git.

For A3, capture the `namespace`, `ciphertextSha256`, and
`ciphertextBase64` status values from `prepare` and `export-ct` before
uninstalling the test host. Run `Invoke-HostPhase 'prepare'` followed by
`Invoke-HostPhase 'export-ct'` and capture their status values; do not continue
through the reboot/verify/cleanup flow for this A3 namespace. Uninstall the
test host, reinstall the same test APK, then run:

```powershell
Invoke-HostPhase 'probe-old-ct' @(
    'namespace', '<namespace>',
    'sha256', '<ciphertextSha256>',
    'ciphertextBase64', '<ciphertextBase64>'
)
```

The probe verifies the ciphertext hash and must report PASS with
`failureCode=2`: a fresh install has no matching Android Keystore key.
The probe removes its empty temporary namespace directory afterward.
The `cleanup` phase uses the proof saved by `prepare`; after uninstall/reinstall
that proof no longer exists, so cleanup of the pre-uninstall namespace is not
applicable. Uninstall itself removes the test host's private proof file.

## Known limitations

- The host validates the PC-03 test harness only; it is not a product APK or
  a PC-03 acceptance result.
- Android API 29 does not expose `KeyInfo.getSecurityLevel()`. Do not infer
  TEE or StrongBox from this run.
- D8 may emit Kotlin metadata version warnings; the existing Kotlin standard
  library is included to avoid runtime `NoClassDefFoundError`.
