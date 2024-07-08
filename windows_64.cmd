set VERSION=%1
set GITHUBPATH=%cd%
%HOMEDRIVE%
cd %HOMEDRIVE%%HOMEPATH%
echo =====[ CurPath  %HOMEDRIVE%%HOMEPATH% ]=====
echo =====[ Getting Depot Tools ]=====
powershell -command "Invoke-WebRequest https://storage.googleapis.com/chrome-infra/depot_tools.zip -O depot_tools.zip"
7z x depot_tools.zip -o*
set PATH=%CD%\depot_tools;%PATH%
set PATH=%CD%\depot_tools\.cipd_bin\2.7\bin;%PATH%
set GYP_MSVS_VERSION=2019
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
call gclient

cd depot_tools
call git reset --hard 8d16d4a
powershell -Command "(gc fetch_configs/v8.py) -replace 'https://chromium.googlesource.com/v8/v8.git', 'https://github.com/scutDavid/v8' | Out-File -encoding ASCII fetch_configs/v8.py"
cd ..
set DEPOT_TOOLS_UPDATE=0

%HOMEDRIVE%
cd %HOMEDRIVE%%HOMEPATH%
mkdir v8
cd v8

echo =====[ Fetching V8 ]=====

call fetch v8
cd v8
call git checkout cfr_v8_8.4-lkgr
cd test\test262\data
call git config --system core.longpaths true
call git restore *
cd ..\..\..\
call gclient sync

cd build/util
Set TimeFile=LASTCHGANGE.committime
if not exist %TimeFile% (
    echo "0" > %TimeFile%
)
cd ..\..\

@REM echo =====[ Patching V8 ]=====
@REM node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git apply --cached --reject %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git checkout -- .

@REM echo =====[ add ArrayBuffer_New_Without_Stl ]=====
@REM node %~dp0\node-script\add_arraybuffer_new_without_stl.js .

echo =====[ Building V8 ]=====
call gn gen out.gn\x64.release -args="target_os=""win"" target_cpu=""x64"" v8_use_external_startup_data=false v8_enable_i18n_support=true is_debug=false v8_static_library=true is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false"

call ninja -C out.gn\x64.release -t clean
call ninja -C out.gn\x64.release wee8

@REM node %~dp0\node-script\genBlobHeader.js "window x64" out.gn\x64.release\snapshot_blob.bin

md %GITHUBPATH%\v8\v8\output\v8\Lib\Win64
copy /Y out.gn\x64.release\obj\wee8.lib %GITHUBPATH%\v8\v8\output\v8\Lib\Win64\
copy /Y out.gn\x64.release\icudtl.dat %GITHUBPATH%\v8\v8\output\v8\Lib\Win64\
@REM md output\v8\Inc\Blob\Win64
@REM copy SnapshotBlob.h %GITHUBPATH%\v8\v8\output\v8\Inc\Blob\Win64\

echo =====[ Copy V8 header ]=====
xcopy include %GITHUBPATH%\v8\v8\output\v8\Inc\  /s/h/e/k/f/c