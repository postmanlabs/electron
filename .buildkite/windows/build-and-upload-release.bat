SETLOCAL ENABLEDELAYEDEXPANSION

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

ECHO "Cleaning up old files"
CALL RMDIR /s /q src\out

ECHO "Switching directory to <pipeline>/src/electron"
CALL cd src/electron || EXIT /b !errorlevel!
CALL cd || EXIT /b !errorlevel!

ECHO "Fetching the branch changes"
CALL git fetch || EXIT /b !errorlevel!
CALL git checkout %BUILDKITE_BRANCH% || EXIT /b !errorlevel!

ECHO "Fetching the pull changes"
CALL git pull || EXIT /b !errorlevel!

ECHO "gclient sync -f"
CALL gclient sync -f || EXIT /b !errorlevel!


ECHO "Switching to <pipeline>/src directory"
CALL cd /D .. || EXIT /b !errorlevel!
CALL cd || EXIT /b !errorlevel!

ECHO "Building electron in Release mode"
CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_app || EXIT /b !errorlevel!
CALL gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!

ECHO "Zipping the artifacts"

CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!

ECHO "Uploading the artifacts"
CALL buildkite-agent artifact upload out\Release\dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload out\Release\chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload out\ffmpeg\ffmpeg.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload out\Release\mksnapshot.zip || EXIT /b !errorlevel!

EXIT /b