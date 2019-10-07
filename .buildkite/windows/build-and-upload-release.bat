SETLOCAL ENABLEDELAYEDEXPANSION

REM Docs on for loop in cmd: https://ss64.com/nt/for.html
for %%R in (ia32 x64) do (
  echo "Building for %%R"

  echo "1. Running cleanup"
  CALL npm run clean

  echo "2. Running bootstrap command"
  CALL python script\bootstrap.py --target_arch=%%R
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo "3. Building electron in release mode"
  CALL python script\build.py -c R
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo "4. Creating the distribution"
  CALL python ./script/create-dist.py
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo "Uploading the artifacts"
  CALL buildkite-agent artifact upload "dist/electron-v*-win32-%%R.zip"
  if %errorlevel% neq 0 exit /b %errorlevel%
)

echo "Post-Cleanup: Cleaning up only dist/* and out/*"
CALL npm run clean-build

exit /b