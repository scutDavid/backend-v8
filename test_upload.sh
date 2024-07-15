[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )" && pwd )"
echo $GITHUB_WORKSPACE
mkdir -p $GITHUB_WORKSPACE/output/v8/Lib/Test
cd $GITHUB_WORKSPACE/output/v8/Lib/Test 
echo "This is a test file" > test.txt