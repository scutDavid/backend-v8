[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"
mkdir -p $GITHUB_WORKSPACE/output/v8/Lib/Test
echo "This is a test file" > test.txt