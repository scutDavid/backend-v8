set VERSION=%1

md v8\v8\output\v8\Lib\Win64DLL
cd v8\v8\output\v8\Lib\Win64DLL
cd > filename.txt
echo > filename2.txt
dir /b > test.txt
echo %cd%
dir
more +0 test.txt
echo =====[ finish ]=====
