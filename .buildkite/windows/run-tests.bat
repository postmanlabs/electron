SETLOCAL ENABLEDELAYEDEXPANSION

echo "Downloading the artifact"
CALL buildkite-agent artifact download out\D.zip .
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Unzipping the artifact"
CALL powershell Expand-Archive -Force -LiteralPath out\D.zip -DestinationPath out\
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Running verify ffmpeg"
CALL python script\verify-ffmpeg.py
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b