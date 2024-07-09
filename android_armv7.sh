VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

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

sudo yum update
sudo yum install -y libatomic1-i386-cross
#export LD_LIBRARY_PATH=”LD_LIBRARY_PATH:/usr/i686-linux-gnu/lib/”
echo "/usr/i686-linux-gnu/lib" > i686.conf
sudo mv i686.conf /etc/ld.so.conf.d/
sudo ldconfig

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


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['android']" >> .gclient
cd ~/v8/v8
./build/install-build-deps-android.sh
git checkout cfr_v8_8.4-lkgr

echo "=====[ fix DEPS ]===="
node -e "const fs = require('fs'); fs.writeFileSync('./DEPS', fs.readFileSync('./DEPS', 'utf-8').replace(\"Var('chromium_url') + '/external/github.com/kennethreitz/requests.git'\", \"'https://github.com/kennethreitz/requests'\"));"

gclient sync
# echo 'script_executable = "vpython"' >> .gn
# echo "=====[ vpython version ]====="
# vpython --version

# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

# echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
# node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
vpython ./tools/dev/v8gen.py arm.release -vv -- '
target_os = "android"
target_cpu = "arm"
is_debug = false
v8_enable_i18n_support = true
v8_target_cpu = "arm"
use_goma = false
v8_use_snapshot = true
v8_use_external_startup_data = false
v8_static_library = true
strip_absolute_paths_from_debug_symbols = false
strip_debug_info = false
symbol_level=1
use_custom_libcxx=false
use_custom_libcxx_for_host=true
'
ninja -C out.gn/arm.release -t clean
ninja -C out.gn/arm.release wee8
third_party/android_ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin/strip -g -S -d --strip-debug --verbose out.gn/arm.release/obj/libwee8.a

# node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "android armv7" out.gn/arm.release/snapshot_blob.bin

mkdir -p output/v8/Lib/Android/armeabi-v7a
cp out.gn/arm.release/obj/libwee8.a output/v8/Lib/Android/armeabi-v7a/
cp out.gn/arm.release/icudtl.dat output/v8/Lib/Android/armeabi-v7a/

ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/v8_base_without_compiler/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/v8_libbase/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/v8_libsampler/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/v8_libplatform/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/src/inspector/inspector/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/third_party/icu/icuuc/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/third_party/icu/icui18n/*.o
ar -rcsD output/v8/Lib/Android/armeabi-v7a/libwee81.a out.gn/arm.release/obj/v8_snapshot/*.o

# mkdir -p output/v8/Inc/Blob/Android/armv7a
# cp SnapshotBlob.h output/v8/Inc/Blob/Android/armv7a/
