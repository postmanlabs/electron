SETLOCAL ENABLEDELAYEDEXPANSION

echo "Building for %1"

echo "Running cleanup"
CALL npm run clean

echo "Running bootstrap command"
CALL python script\bootstrap.py --target_arch="%1"
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Building electron in release mode"
CALL python script\build.py -c R
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Creating the distribution"
CALL python ./script/create-dist.py
if %errorlevel% neq 0 exit /b %errorlevel%

echo "Uploading the shasum files"
REM Going inside the directory to avoid saving the files along with the directory name.
REM Instead of saving as 'dist/*.sha256sum' (mac/linux) or 'dist\*.sha256sum' (windows),
REM it would always save it as '*.sha256sum
cd dist
CALL buildkite-agent artifact upload "*.sha256sum"
cd ..

echo "Post-Cleanup"
CALL npm run clean

exit /b
