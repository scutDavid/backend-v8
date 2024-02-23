VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
cd depot_tools
git reset --hard 8d16d4a

filename="fetch_configs/v8.py"
old_string="https://chromium.googlesource.com/v8/v8.git" 
new_string="https://github.com/scutDavid/v8"
sed -i "1.bak" "s@$old_string@$new_string@g" $filename
# echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
# node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js ~/depot_tools

# echo "=====[ switch v8.git ]====="
# node $GITHUB_WORKSPACE/node-script/switch_v8_git.js ~/depot_tools

cd ..
export DEPOT_TOOLS_UPDATE=0
export PATH=$(pwd)/depot_tools:$PATH
echo "=====[ python version ]====="
python --version

gclient

mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['ios']" >> .gclient
cd ~/v8/v8
git checkout cfr_v8_8.4-lkgr
gclient sync
echo 'script_executable = "vpython"' >> .gn

# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

# echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
# node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
echo "=====[ vpython version ]====="
vpython --version
vpython ./tools/dev/v8gen.py arm64.release -vv -- '
v8_use_external_startup_data = true
v8_use_snapshot = true
v8_enable_i18n_support = true
is_debug = false
v8_static_library = true
ios_enable_code_signing = false
target_os = "ios"
target_cpu = "arm64"
v8_enable_pointer_compression = false
libcxx_abi_unstable = false
'

# gn gen out.gn/arm64.release --args='v8_use_external_startup_data=true v8_use_snapshot=true v8_enable_i18n_support=true is_debug=false v8_static_library=true ios_enable_code_signing=false target_os="ios" target_cpu="arm64" v8_enable_pointer_compression=false libcxx_abi_unstable=false'

ninja -C out.gn/arm64.release -t clean
ninja -C out.gn/arm64.release wee8
strip -S out.gn/arm64.release/obj/libwee8.a

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "ios arm64" out.gn/arm64.release/snapshot_blob.bin

mkdir -p output/v8/Lib/iOS/arm64
cp out.gn/arm64.release/obj/libwee8.a output/v8/Lib/iOS/arm64/
cp out.gn/arm64.release/icudtl.dat output/v8/Lib/iOS/arm64/

mkdir -p output/v8/Inc/Blob/iOS/arm64
cp SnapshotBlob.h output/v8/Inc/Blob/iOS/arm64/
