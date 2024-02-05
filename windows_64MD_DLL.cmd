set VERSION=%1
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

@REM echo =====[ Patching V8 ]=====
@REM node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git apply --cached --reject %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git checkout -- .

echo =====[ Make dynamic_crt ]=====
node %~dp0\node-script\rep.js  build\config\win\BUILD.gn

@REM echo =====[ add ArrayBuffer_New_Without_Stl ]=====
@REM node %~dp0\node-script\add_arraybuffer_new_without_stl.js .

echo =====[ Building V8 ]=====
call gn gen out.gn\x64.release -args="target_os=""win"" target_cpu=""x64"" v8_use_external_startup_data=true v8_enable_i18n_support=true is_debug=false is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false is_component_build=true"

call ninja -C out.gn\x64.release -t clean
call ninja -C out.gn\x64.release v8

md output\v8\Lib\Win64DLL
copy /Y out.gn\x64.release\v8.dll.lib output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8_libplatform.dll.lib output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8_libbase.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8_libplatform.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\zlib.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8_libbase.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\v8_libplatform.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\zlib.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\icudtl.dat output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\icuuc.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.release\icui18n.dll output\v8\Lib\Win64DLL\