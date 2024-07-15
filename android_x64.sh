VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )" && pwd )"

sudo yum install -y \
    pkg-config \
    git \
    subversion \
    curl \
    wget \
    build-essential \
    python \
    xz-utils \
    zip

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
cd depot_tools
git reset --hard 8d16d4a

filename="fetch_configs/v8.py"
old_string="https://chromium.googlesource.com/v8/v8.git" 
new_string="https://github.com/scutDavid/v8"
sed -i "s@$old_string@$new_string@g" $filename

cd ..
export DEPOT_TOOLS_UPDATE=0
export PATH=$(pwd)/depot_tools:$PATH
gclient


mkdir ~/dev
mkdir ~/dev/v8
cd ~/dev/v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['android']" >> .gclient
cd ~/dev/v8/v8
cd build
./build/install-build-deps-android.sh
cd ..
git checkout cfr_v8_8.4-lkgr

echo "=====[ fix DEPS ]===="
node -e "const fs = require('fs'); fs.writeFileSync('./DEPS', fs.readFileSync('./DEPS', 'utf-8').replace(\"Var('chromium_url') + '/external/github.com/kennethreitz/requests.git'\", \"'https://github.com/kennethreitz/requests'\"));"

gclient sync
echo 'script_executable = "vpython"' >> .gn
echo "=====[ vpython version ]====="
vpython --version

# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

# echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
# node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
vpython ./tools/dev/v8gen.py x64.release -vv -- '
target_os = "android"
target_cpu = "x64"
is_debug = false
v8_enable_i18n_support = true
v8_target_cpu = "x64"
use_goma = false
v8_use_snapshot = true
v8_use_external_startup_data = false
v8_static_library = true
strip_debug_info = false
symbol_level=1
use_custom_libcxx=false
use_custom_libcxx_for_host=true
v8_enable_pointer_compression=false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8
third_party/android_ndk/toolchains/x86_64-4.9/prebuilt/linux-x86_64/x86_64-linux-android/bin/strip -g -S -d --strip-debug --verbose out.gn/x64.release/obj/libwee8.a

# node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "android x64" out.gn/x64.release/snapshot_blob.bin

mkdir -p $GITHUB_WORKSPACE/output/v8/Lib/Android/x64
cp out.gn/x64.release/obj/libwee8.a $GITHUB_WORKSPACE/output/v8/Lib/Android/x64/
cp out.gn/x64.release/icudtl.dat $GITHUB_WORKSPACE/output/v8/Lib/Android/x64
