---Specify the full path to the file in double square brackets---
File_Patch = [[D:\Probe.txt]]

--Open File-----------------------------------------
if File_Patch then
   File_Patch = string.gsub(File_Patch, [[\]], [[/]])
   Command = "start "..File_Patch
   os.execute(Command)
end
