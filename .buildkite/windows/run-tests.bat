SETLOCAL ENABLEDELAYEDEXPANSION

CALL RMDIR /s /q out
CALL RMDIR /s /q ffmpeg

echo "Downloading the artifact"
CALL buildkite-agent artifact download ffmpeg\ffmpeg.zip .
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Unzipping the artifact"
CALL powershell Expand-Archive -Force -LiteralPath ffmpeg\ffmpeg.zip -DestinationPath out\
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Switch to the src branch"
CALL cd \D src

echo "Running verify ffmpeg"
CALL python electron\script\verify-ffmpeg.py --source-root %cd% --build-dir out/ffmpeg --ffmpeg-path out/ffmpeg
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Verify mksnapshot"
CALL python electron\script\verify-mksnapshot.py --build-dir out\Release --source-root %cd%
if %errorlevel% neq 0 exit /b %errorlevel%

CALL cd \D ..

CALL RMDIR /s /q out
CALL RMDIR /s /q ffmpeg

exit /b