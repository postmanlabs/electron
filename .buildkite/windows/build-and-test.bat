SETLOCAL ENABLEDELAYEDEXPANSION

SET ARCH=%1%

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

ECHO "Arch tech %ARCH%"
ECHO "Cleaning up old files"
CALL RMDIR /s /q src\out

ECHO "--- Switching directory to <pipeline>/src/electron"
CALL cd src/electron || EXIT /b !errorlevel!

ECHO "Cleaning old .git/rebase-apply file before running gclient sync"
CALL cd ..
CALL RMDIR /s /q .git\rebase-apply
CALL RMDIR /s /q third_party\electron_node\.git\rebase-apply
CALL cd electron

ECHO "--- Remove origin and add new origin"
CALL git remote remove origin || EXIT /b !errorlevel!
CALL git remote add origin https://github.com/postmanlabs/electron || EXIT /b !errorlevel!

ECHO "--- set upstream to branch %BUILDKITE_BRANCH%"
CALL git fetch || EXIT /b !errorlevel!
CALL git checkout %BUILDKITE_BRANCH% || EXIT /b !errorlevel!
CALL git branch --set-upstream-to origin/%BUILDKITE_BRANCH% || EXIT /b !errorlevel!

ECHO "--- git reset --hard origin"
CALL git reset --hard origin/%BUILDKITE_BRANCH% || EXIT /b !errorlevel!

ECHO "--- gclient sync -f"
CALL gclient sync -f || EXIT /b !errorlevel!


ECHO "--- Switching to <pipeline>/src directory"
CALL cd /D ..

ECHO "--- Building electron binaries in Release mode for 32 bit"
CALL gn gen out/Release-x32 --args="import(\"//electron/build/args/release.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!
CALL gn check out/Release-x32 //electron:electron_lib || EXIT /b !errorlevel!
CALL gn check out/Release-x32 //electron:electron_app || EXIT /b !errorlevel!
CALL gn check out/Release-x32 //electron:manifests || EXIT /b !errorlevel!
CALL gn check out/Release-x32 //electron/shell/common/api:mojo || EXIT /b !errorlevel!
CALL ninja -C out/Release-x32 electron:electron_app || EXIT /b !errorlevel!
CALL gn gen out/ffmpeg-x32 --args="import(\"//electron/build/args/ffmpeg.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!

ECHO "--- Building electron binaries in Release mode for 64 bit"
CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_app || EXIT /b !errorlevel!
CALL gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!

ECHO "--- Zipping the artifacts for 32 bit"
CALL ninja -C out/ffmpeg-x32 electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release-x32 electron:electron_dist_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release-x32 electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release-x32 electron:electron_chromedriver_zip || EXIT /b !errorlevel!

ECHO "--- Switch directory <pipeline>/src/out"
CALL cd /D out || EXIT /b !errorlevel!

ECHO "--- Uploading the release artifacts for 32 bit"
CALL buildkite-agent artifact upload Release-x32/dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release-x32/chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release-x32/mksnapshot.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload ffmpeg-x32/ffmpeg.zip || EXIT /b !errorlevel!

ECHO "--- Switch directory <pipeline>/src"
CALL cd /D ..

ECHO "--- Zipping the artifacts for 64 bit"
CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
CALL ninja -C out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!

ECHO "--- Switch directory <pipeline>/src"
CALL cd /D out || EXIT /b !errorlevel!

ECHO "--- Uploading the release artifacts for 64 bit"
CALL buildkite-agent artifact upload Release/dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release/chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload Release/mksnapshot.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload ffmpeg/ffmpeg.zip || EXIT /b !errorlevel!

EXIT /b