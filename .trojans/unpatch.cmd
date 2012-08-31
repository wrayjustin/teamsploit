copy ws2k3.cmd %systemroot%\System32\ /Y

dir /s /b C:\Windows\ | find "spuninst.exe" > patches.txt
type patches.txt | find "C:\Windows\$N" > patch.txt
for /F %%A in (patch.txt) do start /WAIT %%A /quiet /norestart

shutdown /r /c "Hanging Application or Service" /t 0 
