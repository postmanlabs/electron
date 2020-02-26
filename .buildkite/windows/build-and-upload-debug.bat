SETLOCAL ENABLEDELAYEDEXPANSION

IF NOT EXIST "src\electron" (
  ECHO "Not in the correct directory. Exiting..."
  EXIT /b 1
)

ECHO "Cleaning up old files"
CALL RMDIR /s /q src\out

ECHO "Building electron in debug mode"
CALL gn gen out/Debug --args="import(\"//electron/build/args/debug.gn\")" || EXIT /b !errorlevel!
CALL gn check out/Debug //electron:electron_lib || EXIT /b !errorlevel!
CALL gn check out/Debug //electron:electron_app || EXIT /b !errorlevel!
CALL gn check out/Debug //electron:manifests || EXIT /b !errorlevel!
CALL gn check out/Debug //electron/shell/common/api:mojo || EXIT /b !errorlevel!
CALL ninja -C out/Debug electron:electron_app || EXIT /b !errorlevel!
REM if "%GN_CONFIG%"=="testing" ( python C:\Users\electron\depot_tools\post_build_ninja_summary.py -C out\Default )

ECHO "Zipping the artifacts"
CALL gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")" || EXIT /b !errorlevel!
CALL ninja -C out/ffmpeg electron:electron_ffmpeg_zip || EXIT /b !errorlevel!
CALL ninja -C out/Debug electron:electron_dist_zip || EXIT /b !errorlevel!
CALL ninja -C out/Debug electron:electron_mksnapshot_zip || EXIT /b !errorlevel!
CALL ninja -C out/Debug electron:electron_chromedriver_zip || EXIT /b !errorlevel!
CALL ninja -C out/Debug third_party/electron_node:headers || EXIT /b !errorlevel!
CALL 7z a src\out\Debug\node_headers.zip out\Debug\gen\node_headers || EXIT /b !errorlevel!

ECHO "Uploading the artifacts"
CALL buildkite-agent artifact upload src\out\Debug\dist.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\Debug\chromedriver.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\ffmpeg\ffmpeg.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\node_headers.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\Debug\mksnapshot.zip || EXIT /b !errorlevel!
CALL buildkite-agent artifact upload src\out\Debug\electron.lib || EXIT /b !errorlevel!

EXIT /b