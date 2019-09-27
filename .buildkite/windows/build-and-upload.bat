SETLOCAL ENABLEDELAYEDEXPANSION

REM (@TODO check do we need to cleanup everything or just the dist & out directories)
echo "Pre-Cleanup: Running complete cleanup"
CALL npm run clean
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Running bootstrap command"
CALL python script\bootstrap.py --dev
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Building electron in debug mode"
CALL python script\build.py -c D
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Zipping the artifacts"
CALL powershell Compress-Archive -Force -Path out\D -DestinationPath out\D.zip
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Uploading the artifacts"
CALL buildkite-agent artifact upload "out/D.zip"
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Post-Cleanup: Cleaning up only dist/* and out/*"
CALL npm run clean-build

exit /b