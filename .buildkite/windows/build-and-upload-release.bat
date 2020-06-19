SETLOCAL ENABLEDELAYEDEXPANSION

SET ARCH=%1%

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

ECHO "Arch tech %ARCH%"
ECHO "Cleaning up old files"
CALL RMDIR /s /q src\out

ECHO "Switching directory to <pipeline>/src/electron"
CALL cd src/electron || EXIT /b !errorlevel!

ECHO "Remove origin and add new origin"
CALL git remote remove origin || EXIT /b !errorlevel!
CALL git remote add origin https://github.com/postmanlabs/electron || EXIT /b !errorlevel!

ECHO " set upstream to brancch %BUILDKITE_BRANCH%"
CALL git fetch || EXIT /b !errorlevel!
CALL git checkout %BUILDKITE_BRANCH% || EXIT /b !errorlevel!
CALL git branch --set-upstream-to origin/%BUILDKITE_BRANCH% || EXIT /b !errorlevel!

ECHO "git pull"
CALL git pull || EXIT /b !errorlevel!

ECHO "gclient sync -f"
CALL gclient sync -f || EXIT /b !errorlevel!


ECHO "Switching to <pipeline>/src directory"
CALL cd /D .. || EXIT /b !errorlevel!

ECHO "Building electron binaries in Release mode"
if "%ARCH%" == "ia32" (
  CALL gn gen out/Release-x32 --args="import(\"//electron/build/args/release.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!
  CALL gn check out/Release-x32 //electron:electron_lib || EXIT /b !errorlevel!
  CALL gn check out/Release-x32 //electron:electron_app || EXIT /b !errorlevel!
  CALL gn check out/Release-x32 //electron:manifests || EXIT /b !errorlevel!
  CALL gn check out/Release-x32 //electron/shell/common/api:mojo || EXIT /b !errorlevel!
  CALL ninja -C out/Release-x32 electron:electron_app || EXIT /b !errorlevel!
  CALL gn gen out/ffmpeg-x32 --args="import(\"//electron/build/args/ffmpeg.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!
  
) ELSE (
  CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
  CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
  CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
  CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
  CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_app || EXIT /b !errorlevel!
  CALL gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!
)

ECHO "Zipping the artifacts"
if "%ARCH%" == "ia32" (
  CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!
) ELSE (
  CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
  CALL ninja -C out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!
)

ECHO "Switch directory <pipeline>/src/out/Release"
CALL cd /D out || EXIT /b !errorlevel!

ECHO "Uploading the release artifacts"
if "%ARCH%" == "ia32" (
  CALL buildkite-agent artifact upload Release/dist.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload Release/chromedriver.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload Release/mksnapshot.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload ffmpeg/ffmpeg.zip || EXIT /b !errorlevel!
) ELSE (
  CALL buildkite-agent artifact upload Release/dist.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload Release/chromedriver.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload Release/mksnapshot.zip || EXIT /b !errorlevel!
  CALL buildkite-agent artifact upload ffmpeg/ffmpeg.zip || EXIT /b !errorlevel!
)

ECHO "Upload to GitHub release"
CALL cd electron 
CALL python script/release/uploaders/upload.py
  
ECHO "Uploading the shasum files"
CALL cd ..
CALL cd out/Release
CALL buildkite-agent artifact upload "*.sha256sum"
CALL cd ..
CALL cd ffmpeg
CALL buildkite-agent artifact upload "*.sha256sum"

EXIT /b