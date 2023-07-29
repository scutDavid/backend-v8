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
v8_static_library = true
strip_debug_info = true
symbol_level=0
libcxx_abi_unstable = false
v8_enable_pointer_compression=false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8

#number of directories and files
DS=0
FS=0
#1st param, the dir name
#2nd param, the aligning space
var1="out.gn/x64.release/obj"
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

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "osx 64" out.gn/x64.release/snapshot_blob.bin

mkdir -p output/v8/Inc/Blob/macOS
cp SnapshotBlob.h output/v8/Inc/Blob/macOS/


mkdir -p output/v8/Lib/macOS
cd output/v8/Lib/macOS
ar -rcsD libwee8.a out.gn/x64.release/obj/v8_base/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/v8_libbase/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/v8_libsampler/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/v8_libplatform/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/src/inspector/inspector/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/third_party/icu/icuuc/*.o
ar -rcsD libwee8.a out.gn/x64.release/obj/third_party/icu/icui18n/*.o

