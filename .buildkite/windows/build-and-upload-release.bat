SETLOCAL ENABLEDELAYEDEXPANSION

SET ARCH=%1%

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

@REM ECHO "Arch tech %ARCH%"
@REM ECHO "Cleaning up old files"
@REM CALL RMDIR /s /q src\out

ECHO "--- Switching directory to <pipeline>/src/electron"
CALL cd src/electron || EXIT /b !errorlevel!

@REM ECHO "Cleaning old .git/rebase-apply file before running gclient sync"
@REM CALL cd ..
@REM CALL RMDIR /s /q .git\rebase-apply
@REM CALL RMDIR /s /q third_party\electron_node\.git\rebase-apply
@REM CALL cd electron

@REM ECHO "--- Remove origin and add new origin"
@REM CALL git remote remove origin || EXIT /b !errorlevel!
@REM CALL git remote add origin https://github.com/postmanlabs/electron || EXIT /b !errorlevel!

@REM ECHO "--- Set upstream to brancch %BUILDKITE_BRANCH%"
@REM CALL git fetch || EXIT /b !errorlevel!
@REM CALL git checkout %BUILDKITE_BRANCH% || EXIT /b !errorlevel!
@REM CALL git branch --set-upstream-to origin/%BUILDKITE_BRANCH% || EXIT /b !errorlevel!

@REM ECHO "--- git reset --hard origin"
@REM CALL git reset --hard origin/%BUILDKITE_BRANCH% || EXIT /b !errorlevel!

@REM ECHO "--- gclient sync -f"
@REM CALL gclient sync -f || EXIT /b !errorlevel!

@REM ECHO "--- Switching to <pipeline>/src directory"
@REM CALL cd /D .. 

@REM ECHO "--- Setting environment Variable"
@REM CALL set CHROMIUM_BUILDTOOLS_PATH=%cd%\buildtools

@REM ECHO "--- Building electron binaries in Release mode"
@REM if "%ARCH%" == "ia32" (
@REM   CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_app -j 75 || EXIT /b !errorlevel!
@REM   CALL gn gen out/ffmpeg --args="import(\"//electron/build/args/ffmpeg.gn\") target_cpu=\"x86\"" || EXIT /b !errorlevel!
  
@REM ) ELSE (
@REM   CALL gn gen out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:electron_lib || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:electron_app || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron:manifests || EXIT /b !errorlevel!
@REM   CALL gn check out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_app -j 75 || EXIT /b !errorlevel!
@REM   CALL gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!
@REM )

@REM ECHO "--- Zipping the artifacts"
@REM if "%ARCH%" == "ia32" (
@REM   CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_dist_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_mksnapshot_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_chromedriver_zip -j 75 || EXIT /b !errorlevel!
@REM ) ELSE (
@REM   CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_dist_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_mksnapshot_zip -j 75 || EXIT /b !errorlevel!
@REM   CALL ninja -C out/Release electron:electron_chromedriver_zip -j 75 || EXIT /b !errorlevel!
@REM )

ECHO "--- Switch directory <pipeline>/src/out"
CALL cd /D .. || EXIT /b !errorlevel!
CALL cd /D out || EXIT /b !errorlevel!

ECHO "--- Uploading the release artifacts"
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

ECHO "--- Switch directory <pipeline>/src"
CALL cd .. 

ECHO "--- Upload to GitHub release and create SHA files"
CALL cd electron 

if "%ARCH%" == "ia32" (
  CALL python script/release/uploaders/upload.py --arch_ia32
) ELSE (
  CALL python script/release/uploaders/upload.py
)
CALL cd ..
  
ECHO "--- Uploading the shasum files"
CALL cd out/Release
CALL buildkite-agent artifact upload "*.sha256sum"
CALL cd ../..

EXIT /b