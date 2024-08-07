VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )" && pwd )"
echo $GITHUB_WORKSPACE
mkdir -p $GITHUB_WORKSPACE/output/v8/Lib/macOSdylib
cd $GITHUB_WORKSPACE/output/v8/Lib/macOSdylib/
echo "1122" > myfile.txt

cd $GITHUB_WORKSPACE/output/v8/Lib
tar cvfz MacOSDLL.tar MacOSDLL