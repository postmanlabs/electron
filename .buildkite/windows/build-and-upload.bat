SETLOCAL ENABLEDELAYEDEXPANSION

REM (@TODO check do we need to cleanup everything or just the dist & out directories)
REM echo "Cleaning up"
REM CALL npm run clean
REM if %errorlevel% neq 0 exit /b %errorlevel%

REM echo "Running bootstrap command"
REM CALL python script\bootstrap.py -v
REM if %errorlevel% neq 0 exit /b %errorlevel%

REM echo "Building electron in debug mode"
REM CALL python script\build.py -c D
REM if %errorlevel% neq 0 exit /b %errorlevel%

echo "Zipping the artifacts"
CALL powershell Compress-Archive -Force -Path out\D -DestinationPath out\D.zip
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Uploading the artifacts"
CALL buildkite-agent artifact upload "out/D.zip"
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b