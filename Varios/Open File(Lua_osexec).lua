---Specify the full path to the file in double square brackets---
File_Patch = [[C:\Users\EUGEN\Desktop\Example.txt]]

--Open File-----------------------------------------
if File_Patch then
   File_Patch = string.gsub(File_Patch, [[\]], [[/]])
   os.execute(File_Patch)
end
