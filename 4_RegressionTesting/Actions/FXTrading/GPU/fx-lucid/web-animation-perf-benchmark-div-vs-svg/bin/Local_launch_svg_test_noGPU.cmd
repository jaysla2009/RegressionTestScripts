set svg_dir= %~dp0

CD /D %svg_dir%
CD ..\

If not exist "c:\Program Files (x86)\Google\Chrome\Application\chrome.exe" GOTO x86

"c:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --start-maximized --blacklist-accelerated-compositing --blacklist-webgl --disable-gpu --show-fps-counter file:/%CD%/svg/svg.html
exit 0

:x86
"c:\Program Files\Google\Chrome\Application\chrome.exe" --start-maximized --blacklist-accelerated-compositing --blacklist-webgl --disable-gpu --show-fps-counter file:/%CD%/svg/svg.html
exit 0