SETLOCAL ENABLEDELAYEDEXPANSION

REM IF NOT EXIST "src\electron" (
REM   ECHO "Not in the correct directory. Exiting..."
REM   EXIT /b 1
REM )

REM ECHO "Cleaning up old files"
REM CALL RMDIR /s /q src\out

ECHO "Switching directory to <pipeline>/src/electron"
CALL cd src/electron || EXIT /b !errorlevel!

REM ECHO "git fetch && git checkout %BUILDKITE_BRANCH%"
REM CALL git fetch || EXIT /b !errorlevel!
REM CALL git checkout %BUILDKITE_BRANCH% || EXIT /b !errorlevel!

REM ECHO "git pull"
REM CALL git pull origin %BUILDKITE_BRANCH%  || EXIT /b !errorlevel!

REM ECHO "gclient sync -f"
REM CALL gclient sync -f || EXIT /b !errorlevel!


ECHO "Switching to <pipeline>/src directory"
CALL cd /D .. || EXIT /b !errorlevel!

REM ECHO "Building electron binaries in Release mode"
REM CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
REM CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
REM CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
REM CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
REM CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
REM CALL ninja -C out/Release electron:electron_app || EXIT /b !errorlevel!
REM CALL gn gen out/Release/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!

REM ECHO "Zipping the artifacts"

REM CALL ninja -C out/Release/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
REM CALL ninja -C out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
REM CALL ninja -C out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
REM CALL ninja -C out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!

ECHO "Switch directory <pipeline>/src/out/Release"
CALL cd out || EXIT /b !errorlevel!

ECHO "Uploading the release artifacts"
CALL buildkite-agent artifact upload Release/dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release/chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release/mksnapshot.zip || EXIT /b !errorlevel!

ECHO "Switch directory <pipeline>/src/out/Release/ffmpeg and upload artifact ffmpeg"
CALL cd Release
CALL buildkite-agent artifact upload ffmpeg/ffmpeg.zip || EXIT /b !errorlevel!

ECHO "Switch directory <pipeline>/src"
CALL cd ../../.. || EXIT /b !errorlevel!
CALL cd || EXIT /b !errorlevel!

EXIT /b