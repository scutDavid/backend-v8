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
# echo "=====[ switch v8.git ]====="
# node $GITHUB_WORKSPACE/node-script/switch_v8_git.js .

cd ..
export DEPOT_TOOLS_UPDATE=0
export PATH=$(pwd)/depot_tools:$PATH
export PATH=$(pwd)/depot_tools/.cipd_bin/2.7/bin:$PATH
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['mac']" >> .gclient
cd ~/v8/v8
git checkout cfr_v8_8.4-lkgr
gclient sync
echo 'script_executable = "vpython"' >> .gn

filename2="build/toolchain/mac/filter_libtool.py"
old_string="return True" 
new_string=""
sed -i "2.bak""s@$old_string@$new_string@g" $filename2
old_string="if pattern.match(line):" 
new_string="if isinstance(line, bytes):\r\n        line = line.decode('utf-8')\r\n        print(1, line)\r\n    elif isinstance(line, str):\r\n        print(2, line)\r\n    try:\r\n        if pattern.match(line):\r\n          return True\r\n    except AttributeError as e:\r\n        print(3, line)\r\n        return True"sed -i "3.bak" "s@$old_string@$new_string@g" $filename2


# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

# echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
# node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
vpython ./tools/dev/v8gen.py x64.release -vv -- '
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

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "osx 64" out.gn/x64.release/snapshot_blob.bin

mkdir -p output/v8/Lib/macOS
cp out.gn/x64.release/obj/libwee8.a output/v8/Lib/macOS/
cp out.gn/x64.release/icudtl.dat output/v8/Lib/macOS/
mkdir -p output/v8/Inc/Blob/macOS
cp SnapshotBlob.h output/v8/Inc/Blob/macOS/
