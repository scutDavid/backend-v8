set GITHUBPATH=%cd%
md %GITHUBPATH%\v8\v8\output\v8\Inc
cd %GITHUBPATH%\v8\v8\output\v8\Inc
echo "This is a test file" > test.txt
cd ..
ls
echo %GITHUBPATH%
tar cvfz Inc.tar Inc
ls