--Set Dir and File name--
Dir = [[D:\]]--Set directory
File = [[Probe.txt]]--Set File Name
------------------------------------------------
ShowFlag=3; Par=0
Ret=reaper.BR_Win32_ShellExecute("open", File, Par, Dir, ShowFlag)
