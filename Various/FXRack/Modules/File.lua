-- File(module)
-- @noindex


local File = {}

-- RecursiveCreateDirectory ------------
function File.RecursiveCreateDirectory(path)
  if not path then return end
  return reaper.RecursiveCreateDirectory(path, 1)
end

-- Enum SubDirs in Dir(path) -----------
-- return dirnames table --
function File.EnumerateSubDirs(path)
  if not path then return end
  local t = {}
  for i = 0, math.huge do
    local dn = reaper.EnumerateSubdirectories(path, i)
    if dn and dn ~= "" then t[#t+1] = dn else break end
  end
  return t
end

-- Enum Files in Dir(path) -------------
-- return filenames table --
function File.EnumerateFiles(path)
  if not path then return end
  local t = {}
  for i = 0, math.huge do
    local fn = reaper.EnumerateFiles(path, i)
    if fn and fn ~= "" then t[#t+1] = fn else break end
  end
  return t
end

-- File Exists(reaper) -----------------
function File.Exists(filename)
  return reaper.file_exists(filename)
end

-- File Exists(Lua) --------------------
function File.Exists2(filename)
  local file = io.open(filename, "rb")
  if file then file:close(); return true end
end

-- File Remove -------------------------
function File.Remove(filename)
  return os.remove(filename)
end

-- File Rename(rename file or dir) -----
function File.Rename(oldname, newname)
  return os.rename(oldname, newname)
end

-- Read Binary -------------------------
function File.ReadBin(filename)
  if not filename then return end
  local file, data
  file = io.open(filename, "rb")  -- read bin
  if file then data = file:read("a"); file:close() end
  return data
end

-- Write Binary ------------------------
function File.WriteBin(filename, data)
  if not (filename and data) then return end
  local file, ret
  file = io.open(filename, "wb") -- write bin
  if file then ret = file:write(data); file:close() end
  if ret then return true end -- if succefully
end


-- FileCopy ----------------------------
--[[copy file src_filename to file dest_filename
src_filename, dest_filename - full pathes
create dest directory if no exist
don't use on large files! --]]
function File.Copy(src_filename, dest_filename)
  if not(src_filename and dest_filename) or 
    src_filename == dest_filename then return 
  end
  -- Read from Source
  local data = File.ReadBin(src_filename)
  if not data then return end
  -- Check/Create dest directory
  local dest_dir = dest_filename:match("^(.*)[\\/].+") -- extract dir
  if not dest_dir then return end
  File.RecursiveCreateDirectory(dest_dir, 1)
  -- Write to Dest
  local ret = File.WriteBin(dest_filename, data)
  if ret then return true end -- if succefully
end


--======================================
return File
