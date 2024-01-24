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
echo "target_os = ['ios']" >> .gclient
cd ~/v8/v8
git checkout refs/tags/$VERSION
gclient sync


echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
node $GITHUB_WORKSPACE/node-script/do-gitpatch.js -p $GITHUB_WORKSPACE/patches/bitcode.patches

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py arm64.release -vv -- '
v8_use_external_startup_data = false
v8_use_snapshot = true
v8_enable_i18n_support = true
is_debug = false
v8_static_library = true
ios_enable_code_signing = false
target_os = "ios"
target_cpu = "arm64"
v8_enable_pointer_compression = false
use_xcode_clang = true
enable_ios_bitcode = true
symbol_level = 0
libcxx_abi_unstable = false
'
ninja -C out.gn/arm64.release -t clean
ninja -C out.gn/arm64.release wee8

#number of directories and files
DS=0
FS=0
#1st param, the dir name
#2nd param, the aligning space
var1="out.gn/arm64.release/obj"
var2="    "
for file in `ls "$var1"`
do
    if [ -d "$var1/${file}" ];then
        echo "$var2${file}"
        ((DS++))
        listFiles "$var1/${file}" " $var2"
    else
        echo "$var2${file}"
        ((FS++))
    fi
done 
echo "${DS} dictories,${FS} files"

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "ios arm64(bitcode)" out.gn/arm64.release/snapshot_blob.bin

mkdir -p output/v8/Inc/Blob/iOS/bitcode
cp SnapshotBlob.h output/v8/Inc/Blob/iOS/bitcode/

mkdir -p output/v8/Lib/iOS/bitcode
cd output/v8/Lib/iOS/bitcode
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_base/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libbase/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libsampler/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libplatform/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/src/inspector/inspector/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/third_party/icu/icuuc/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/third_party/icu/icui18n/*.o

strip -S output/v8/Lib/iOS/bitcode/libwee8.a
