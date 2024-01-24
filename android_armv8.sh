VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

sudo apt-get install -y \
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
git checkout refs/tags/$VERSION

echo "=====[ fix DEPS ]===="
node -e "const fs = require('fs'); fs.writeFileSync('./DEPS', fs.readFileSync('./DEPS', 'utf-8').replace(\"Var('chromium_url') + '/external/github.com/kennethreitz/requests.git'\", \"'https://github.com/kennethreitz/requests'\"));"

gclient sync


# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py arm64.release -vv -- '
target_os = "android"
target_cpu = "arm64"
is_debug = false
v8_enable_i18n_support = true
v8_target_cpu = "arm64"
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

node $GITHUB_WORKSPACE/node-script/genBlobHeader.js "android arm64" out.gn/arm64.release/snapshot_blob.bin
mkdir -p output/v8/Inc/Blob/Android/arm64
cp SnapshotBlob.h output/v8/Inc/Blob/Android/arm64/

mkdir -p output/v8/Lib/Android/armeabi-v8a
cd output/v8/Lib/Android/armeabi-v8a
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_base/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libbase/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libsampler/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/v8_libplatform/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/src/inspector/inspector/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/third_party/icu/icuuc/*.o
ar -rcsD libwee8.a out.gn/arm64.release/obj/third_party/icu/icui18n/*.o

third_party/android_ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/aarch64-linux-android/bin/strip -g -S -d --strip-debug --verbose output/v8/Lib/Android/armeabi-v8a/libwee8.a
