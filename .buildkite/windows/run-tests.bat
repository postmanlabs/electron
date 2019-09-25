SETLOCAL ENABLEDELAYEDEXPANSION

echo "Running test suite"
CALL python script\test.py --ci --rebuild_native_modules
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Running verify ffmpeg"
CALL python script\verify-ffmpeg.py
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b