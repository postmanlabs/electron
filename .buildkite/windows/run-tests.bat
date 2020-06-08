SETLOCAL ENABLEDELAYEDEXPANSION

echo "Downloading the artifact"
CALL buildkite-agent artifact download ffmpeg\ffmpeg.zip .
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Unzipping the artifact"
CALL powershell Expand-Archive -Force -LiteralPath ffmpeg\ffmpeg.zip -DestinationPath out\
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Running verify ffmpeg"
CALL python script\verify-ffmpeg.py
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b