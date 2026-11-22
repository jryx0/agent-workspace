@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~2"=="" (
  echo usage: build.cmd ^<pc03-worktree^> ^<output-directory^> 1>&2
  exit /b 2
)

for %%I in ("%~1") do set "SOURCE_ROOT=%%~fI"
for %%I in ("%~2") do set "OUTPUT_ROOT=%%~fI"
for %%I in ("%~dp0") do set "SCRIPT_DIR=%%~fI"
if not exist "%SOURCE_ROOT%\native\android\SecretStore.kt" (
  echo product SecretStore.kt is missing 1>&2
  exit /b 2
)
if not exist "%SOURCE_ROOT%\native\android\tests\SecretStoreDeviceChecks.kt" (
  echo product SecretStoreDeviceChecks.kt is missing 1>&2
  exit /b 2
)
if not exist "%USERPROFILE%\.agent-tools\runtimes\jdk-21\bin\java.exe" (
  echo approved local JDK 21 is missing 1>&2
  exit /b 2
)
set "JAVA=%USERPROFILE%\.agent-tools\runtimes\jdk-21\bin\java.exe"
set "JAR=%USERPROFILE%\.agent-tools\runtimes\jdk-21\bin\jar.exe"
set "ANDROID_HOME=%USERPROFILE%\.agent-tools\android-sdk"
set "ANDROID_JAR=%ANDROID_HOME%\platforms\android-36\android.jar"
set "BUILD_TOOLS=%ANDROID_HOME%\build-tools\36.0.0"
set "GRADLE_LIB=%USERPROFILE%\.agent-tools\runtimes\gradle-9.6.1\lib"
set "STDLIB_ROOT=%USERPROFILE%\.gradle\caches\modules-2\files-2.1\org.jetbrains.kotlin\kotlin-stdlib\2.3.21"
set "STDLIB="
for /D %%D in ("%STDLIB_ROOT%\*") do if exist "%%~fD\kotlin-stdlib-2.3.21.jar" if not defined STDLIB set "STDLIB=%%~fD\kotlin-stdlib-2.3.21.jar"

if not exist "%ANDROID_JAR%" (
  echo Android API 36 platform is missing 1>&2
  exit /b 2
)
if not exist "%BUILD_TOOLS%\aapt2.exe" (
  echo Android build-tools 36.0.0 are missing 1>&2
  exit /b 2
)
if not exist "%BUILD_TOOLS%\lib\d8.jar" (
  echo D8 is missing 1>&2
  exit /b 2
)
if not exist "%STDLIB%" (
  echo approved local Kotlin stdlib 2.3.21 is missing 1>&2
  exit /b 2
)
if exist "%OUTPUT_ROOT%\classes" (
  echo output directory already exists; choose a fresh directory 1>&2
  exit /b 2
)
if exist "%OUTPUT_ROOT%\dex" (
  echo output directory already exists; choose a fresh directory 1>&2
  exit /b 2
)
if exist "%OUTPUT_ROOT%\apk" (
  echo output directory already exists; choose a fresh directory 1>&2
  exit /b 2
)

echo(%OUTPUT_ROOT%\| findstr /i /b /c:"%SOURCE_ROOT%\" >nul
if not errorlevel 1 (
  echo output directory must be outside the project worktree 1>&2
  exit /b 2
)

mkdir "%OUTPUT_ROOT%\classes" "%OUTPUT_ROOT%\dex" "%OUTPUT_ROOT%\apk"
if errorlevel 1 exit /b 1

"%JAVA%" -cp "%GRADLE_LIB%\*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler ^
  -no-stdlib -no-reflect -classpath "%ANDROID_JAR%;%STDLIB%" -jvm-target 11 ^
  -d "%OUTPUT_ROOT%\classes" ^
  "%SCRIPT_DIR%HostInstrumentation.kt" ^
  "%SOURCE_ROOT%\native\android\SecretStore.kt" ^
  "%SOURCE_ROOT%\native\android\tests\SecretStoreDeviceChecks.kt"
if errorlevel 1 exit /b 1

for %%F in (
  "app\pcryoxy\secure\SecretStore.class"
  "app\pcryoxy\secure\SecretStore$Failure.class"
  "app\pcryoxy\secure\SecretStoreDeviceChecks.class"
  "app\pcryoxy\secure\SecretStoreDeviceChecks$Proof.class"
) do if not exist "%OUTPUT_ROOT%\classes\%%~F" (
  echo required class was not produced: %%~F 1>&2
  exit /b 1
)

set "CLASS_ARGS="
for /R "%OUTPUT_ROOT%\classes" %%F in (*.class) do set CLASS_ARGS=!CLASS_ARGS! "%%F"

"%JAVA%" -cp "%BUILD_TOOLS%\lib\d8.jar" com.android.tools.r8.D8 ^
  --min-api 29 --lib "%ANDROID_JAR%" --output "%OUTPUT_ROOT%\dex" ^
  !CLASS_ARGS! "%STDLIB%"
if errorlevel 1 exit /b 1

"%BUILD_TOOLS%\aapt2.exe" link -I "%ANDROID_JAR%" ^
  --manifest "%SCRIPT_DIR%AndroidManifest.xml" ^
  --min-sdk-version 29 --target-sdk-version 36 ^
  -o "%OUTPUT_ROOT%\apk\host-unsigned.apk"
if errorlevel 1 exit /b 1

"%JAR%" uf "%OUTPUT_ROOT%\apk\host-unsigned.apk" ^
  -C "%OUTPUT_ROOT%\dex" classes.dex
if errorlevel 1 exit /b 1

"%BUILD_TOOLS%\zipalign.exe" -f 4 ^
  "%OUTPUT_ROOT%\apk\host-unsigned.apk" ^
  "%OUTPUT_ROOT%\apk\host-aligned.apk"
if errorlevel 1 exit /b 1

set "KEYSTORE=%PC03_TEST_KEYSTORE%"
if not defined KEYSTORE set "KEYSTORE=%USERPROFILE%\.android\debug.keystore"
if not exist "%KEYSTORE%" (
  echo existing test keystore is missing; no signing key was generated 1>&2
  exit /b 2
)
set "KEY_ALIAS=%PC03_TEST_KEY_ALIAS%"
if not defined KEY_ALIAS set "KEY_ALIAS=androiddebugkey"
set "STORE_PASS_ARGS=pass:android"
if defined PC03_TEST_STORE_PASS set "STORE_PASS_ARGS=env:PC03_TEST_STORE_PASS"
set "KEY_PASS_ARGS=pass:android"
if defined PC03_TEST_KEY_PASS set "KEY_PASS_ARGS=env:PC03_TEST_KEY_PASS"

"%BUILD_TOOLS%\apksigner.bat" sign ^
  --ks "%KEYSTORE%" ^
  --ks-key-alias "%KEY_ALIAS%" --ks-pass %STORE_PASS_ARGS% --key-pass %KEY_PASS_ARGS% ^
  --out "%OUTPUT_ROOT%\apk\pc03-host.apk" ^
  "%OUTPUT_ROOT%\apk\host-aligned.apk"
if errorlevel 1 exit /b 1

"%BUILD_TOOLS%\apksigner.bat" verify "%OUTPUT_ROOT%\apk\pc03-host.apk"
if errorlevel 1 exit /b 1

echo host APK: %OUTPUT_ROOT%\apk\pc03-host.apk
