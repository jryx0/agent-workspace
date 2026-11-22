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
`dumpsys window` (`isStatusBarKeyguard=false`) first. Set a 60-second timeout
for installation; a timeout while the phone is locked is an environment block,
not a product test failure.

```powershell
$adb = 'C:\Users\Zhn_X\.agent-tools\android-sdk\platform-tools\adb.exe'
$apk = '<output-directory>\apk\pc03-host.apk'
$install = Start-Process -FilePath $adb -ArgumentList @('install', '-r', '-t', '-g', $apk) -NoNewWindow -PassThru
if (-not $install.WaitForExit(60000)) {
    $install.Kill()
    'ENV_BLOCKED: install timed out'
    exit 2
}
if ($install.ExitCode -ne 0) { exit $install.ExitCode }

& $adb shell am instrument -w -e phase prepare app.pcryoxy.andhost/.HostInstrumentation
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
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
& $adb shell am instrument -w -e phase verify app.pcryoxy.andhost/.HostInstrumentation
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $adb shell am instrument -w -e phase cleanup app.pcryoxy.andhost/.HostInstrumentation
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The host persists only the random namespace and 16-byte version proof under
its private no-backup directory. It never writes plaintext fixture bytes or
prints key aliases. `cleanup` removes the test aliases, vault directory, and
proof file. The APK, dex files, and raw logs must remain outside Git.

## Known limitations

- The host validates the PC-03 test harness only; it is not a product APK or
  a PC-03 acceptance result.
- Android API 29 does not expose `KeyInfo.getSecurityLevel()`. Do not infer
  TEE or StrongBox from this run.
- D8 may emit Kotlin metadata version warnings; the existing Kotlin standard
  library is included to avoid runtime `NoClassDefFoundError`.
