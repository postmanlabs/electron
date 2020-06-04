SETLOCAL ENABLEDELAYEDEXPANSION

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

ECHO "Cleaning up old files"
CALL RMDIR /s /q src\out

ECHO "Building electron in Release mode"
CALL gn gen src/out/Release --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!
CALL gn check src/out/Release //electron:electron_lib || EXIT /b !errorlevel!
CALL gn check src/out/Release //electron:electron_app || EXIT /b !errorlevel!
CALL gn check src/out/Release //electron:manifests || EXIT /b !errorlevel!
CALL gn check src/out/Release //electron/shell/common/api:mojo || EXIT /b !errorlevel!
CALL ninja -C src/out/Release electron:electron_app || EXIT /b !errorlevel!
REM if "%GN_CONFIG%"=="testing" ( python C:\Users\electron\depot_tools\post_build_ninja_summary.py -C out\Default )

ECHO "Zipping the artifacts"
CALL gn gen src/out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!
CALL ninja -C src/out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
CALL ninja -C src/out/Release electron:electron_dist_zip || EXIT /b !errorlevel!
CALL ninja -C src/out/Release electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
CALL ninja -C src/out/Release electron:electron_chromedriver_zip || EXIT /b !errorlevel!

ECHO "Uploading the artifacts"
CALL buildkite-agent artifact upload src\out\Release\dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\Release\chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\ffmpeg\ffmpeg.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\Release\mksnapshot.zip || EXIT /b !errorlevel!

EXIT /b