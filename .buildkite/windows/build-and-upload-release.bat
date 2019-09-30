SETLOCAL ENABLEDELAYEDEXPANSION

REM (@TODO check do we need to cleanup everything or just the dist & out directories)
echo "Pre-Cleanup: Running complete cleanup"
CALL npm run clean
if %errorlevel% neq 0 exit /b %errorlevel%

REM Docs on for loop in cmd: https://ss64.com/nt/for.html
for %%R in (x64 ia32) do (
  echo "Building for %%R"

  echo "1. Running bootstrap command"
  CALL python script\bootstrap.py --target_arch=%%R
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo "2. Building electron in release mode"
  CALL python script\build.py -c R
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo "3. Creating the distribution"
  CALL python ./script/create-dist.py
  if %errorlevel% neq 0 exit /b %errorlevel%
)

echo "Uploading the artifacts"
CALL buildkite-agent artifact upload "dist/electron-v*-win32-x64.zip"
if %errorlevel% neq 0 exit /b %errorlevel%

CALL buildkite-agent artifact upload "dist/electron-v*-ia32-x64.zip"
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Post-Cleanup: Cleaning up only dist/* and out/*"
CALL npm run clean-build

exit /b