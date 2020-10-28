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

ECHO "--- Setting environment Variable"
CALL set CHROMIUM_BUILDTOOLS_PATH=%cd%\buildtools
CALL set SCCACHE_PATH=%cd%\electron\external_binaries\sccache.exe

ECHO "--- Building electron binaries in Release mode for 32 bit"
CALL gn gen out/Testing --args="import(\"//electron/build/args/release.gn\")" || EXIT /b !errorlevel!

CALL ninja -C out/Testing electron:electron_app -j 75 || EXIT /b !errorlevel!
CALL ninja -C out/Testing third_party\electron_node:headers || EXIT /b !errorlevel!

CALL cd out/Testing || EXIT /b !errorlevel!
CALL mkdir gen\node_headers\Release || EXIT /b !errorlevel!
CALL copy electron.lib gen\node_headers\Release\node.lib || EXIT /b !errorlevel!

CALL cd /D ../.. || EXIT /b !errorlevel!
CALL cd electron || EXIT /b !errorlevel!
CALL node ./script/spec-runner.js || EXIT /b !errorlevel!

EXIT /b