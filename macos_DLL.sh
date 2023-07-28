VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
cd depot_tools
git reset --hard 8d16d4a
cd ..
export DEPOT_TOOLS_UPDATE=0
export PATH=$(pwd)/depot_tools:$PATH
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['mac']" >> .gclient
cd ~/v8/v8
git checkout refs/tags/$VERSION
gclient sync

# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py x64.release -vv -- '
is_debug = false
v8_enable_i18n_support = true
v8_use_snapshot = true
v8_use_external_startup_data = true
is_component_build = true
strip_debug_info = true
symbol_level=0
libcxx_abi_unstable = false
v8_enable_pointer_compression=false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release v8

#number of directories and files
DS=0
FS=0
#1st param, the dir name
#2nd param, the aligning space
function listFiles(){
    for file in `ls "$1"`
    do
        if [ -d "$1/${file}" ];then
            echo "$2${file}"
            ((DS++))
            listFiles "$1/${file}" " $2"
        else
            echo "$2${file}"
            ((FS++))
        fi
    done    
    
}
var=out.gn/x64.release
listFiles $var "    "
echo "${DS} dictories,${FS} files"

mkdir -p output/v8/Lib/macOSdylib
cp out.gn/x64.release/libv8.dylib output/v8/Lib/macOSdylib/
cp out.gn/x64.release/libv8_libplatform.dylib output/v8/Lib/macOSdylib/
cp out.gn/x64.release/libv8_libbase.dylib output/v8/Lib/macOSdylib/
cp out.gn/x64.release/libchrome_zlib.dylib output/v8/Lib/macOSdylib/
cp out.gn/x64.release/icuuc.dylib output/v8/Lib/macOSdylib/
cp out.gn/x64.release/icui18n.dylib output/v8/Lib/macOSdylib/
