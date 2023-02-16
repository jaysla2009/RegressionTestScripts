set div_dir= %~dp0

CD /D %div_dir%
CD ..\


If not exist "c:\Program Files (x86)\Google\Chrome\Application\chrome.exe" GOTO x86
"c:\Program Files\Google\Chrome\Application\chrome.exe" --start-maximized --show-fps-counter --enable-gpu-rasterization --gpu-rasterization-msaa-sample-count:16 file:/%CD%/div/div.html
exit 0

:x86
"c:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --start-maximized --show-fps-counter --enable-gpu-rasterization --gpu-rasterization-msaa-sample-count:16 file:/%CD%/div/div.html

exit 0