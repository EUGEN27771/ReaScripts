-- Presets(module)
-- @noindex


-- Load some modules -----------------
local File = require "Modules.File"

--******************************************************************************
--------------------------------------
function SetRGB(RGB, a)
  gfx.r = (RGB & 0xFF0000) / 16711680 -- 256*256*255
  gfx.g = (RGB & 0x00FF00) / 65280 -- 256*255
  gfx.b = (RGB & 0x0000FF) / 255 -- 255
  gfx.a = a or 1
end

--==============================================================================
-- Несколько осн. мышиных функций ------
function pointIN(px, py, x,y,w,h)
  return px >= x and px <= x + w and py >= y and py <= y + h
end
----------
function mouseIN(x,y,w,h)
  return pointIN(gfx.mouse_x, gfx.mouse_y, x,y,w,h)
end

-- LEFT ----------------------
function mouseDown(x,y,w,h)
  return mouse_down and mouseIN(x,y,w,h)
end
----------
function mouseUp(x,y,w,h)
  return mouse_up and mouseIN(x,y,w,h)
end
----------
function mouseClick(x,y,w,h)
  return mouseUp(x,y,w,h) and pointIN(mouse_down_x,mouse_down_y, x,y,w,h)
end

-- RIGHT ---------------------
function mouseRDown(x,y,w,h)
  return mouse_rdown and mouseIN(x,y,w,h)
end

--********************************************************************
local Presets = {}

-- устан. пресет-папку(fullpath), создает если не существует
function Presets.SetPath(path)
  if File.RecursiveCreateDirectory(path) then
    Presets.path = path
    return true
  end
end

-- устан. расш. для валидных файлов пресетов
-- ext - непустая строка, например, "txt", "mpr", без точек!
-- лучше пробить по допустимым символам, для себя и так норм
function Presets.SetExtension(ext)
  if Presets.ext == "" then return false
  else Presets.ext = ext return true
  end
end

-- создает список существующих пресетов
function Presets.UpdateList()
  if not Presets.path then return end
  local t = File.EnumerateFiles(Presets.path)
  local ptn = "(.+)%." .. Presets.ext .. "$" -- паттерн для поиска
  Presets.List = {}
  if t then
    for i = 1, #t do
      local name = t[i]:match(ptn) -- пресет-файлы, захв. имя
      if name then Presets.List[#Presets.List+1] = name end
    end
  end
  return Presets.List
end

-- устан.(не загружает!) текущий пресет(имя, отображаемое в пресет-строке)
function Presets.SetCurPresetName(curpresetname)
  if curpresetname and type(curpresetname) == "string" and #curpresetname > 0 then
    Presets.curpresetname = curpresetname
  else Presets.curpresetname = "No Preset"
  end
end

-- возвр. индекс пресета по имени(либо nil)
function Presets.GetByName(presetname)
  if not Presets.List then return end
  for k, v in pairs(Presets.List) do
    if v == presetname then return k end
  end
end

-- возвр. имя пресета по индекс(либо nil)
function Presets.GetName(presetidx)
  if not Presets.List then return end
  return Presets.List[presetidx]
end

-- читает и возвращает данные из файла пресета
function Presets.Load(presetname)
  local filename = Presets.path .. "/" .. presetname .. "." .. Presets.ext
  return File.ReadBin(filename) -- ret data if succefully or nil
end

-- сохр. пресет в пресетную папку с соотв. расширением
function Presets.Save(presetname, presetdata)
  local filename = Presets.path .. "/" .. presetname .. "." .. Presets.ext
  return File.WriteBin(filename, presetdata) -- ret true if succefully
end

-- переименовывает пресет oldname > newname
function Presets.Rename(oldname, newname)
  oldname = Presets.path .. "/" .. oldname .. "." .. Presets.ext
  newname = Presets.path .. "/" .. newname .. "." .. Presets.ext
  return File.Rename(oldname, newname)
end

-- удаляет файл пресета
function Presets.Delete(presetname)
  local filename = Presets.path .. "/" .. presetname .. "." .. Presets.ext
  return File.Remove(filename) -- ret true if succefully
end

------------------------------------------------------------
-- Init Preset Menu ----------------------------------------
------------------------------------------------------------
function Presets.MenuInit(x,y,w,h, col, col_font, path, ext)
  if Presets.SetPath(path) and
    Presets.SetExtension(ext) and
    Presets.UpdateList() then
    Presets.Menu = {x = x, y = y, w = w, h = h, col = col, col_font = col_font}
    Presets.SetCurPresetName() -- now nil, "No Preset"
    return true -- if succefully
  end
end

------------------------------------------------------------
-- Verify and confirm Preset Menu actions ------------------
------------------------------------------------------------
-- Можно поразносить по соотв. функциям проверку и подтверждение
-- Это, наверное, удобнее и проще.
function Presets.ConfirmAction(action, name)
  ------------------
  if action == "Load" then
    if not Presets.GetByName(name) then return end
  end
  ------------------
  if action == "Save" then
    if name ~= Presets.curpresetname and Presets.GetByName(name) then
      local msg = "Overwrite \"" .. name .. "\"?"
      if reaper.MB(msg, "Save Preset", 1) ~= 1 then return end
    end
  end
  ------------------
  if action == "Rename" then
    if not Presets.GetByName(Presets.curpresetname) then return end
    if name ~= Presets.curpresetname and Presets.GetByName(name) then
      local msg = "Overwrite \"" .. name .. "\"?"
      if reaper.MB(msg, "Rename Preset", 1) ~= 1 then return end
      action = "Save" -- It's Overwrite Exist Preset!
    end
  end
  ------------------
  if action == "Delete" then
    if not Presets.GetByName(name) then return end
    local msg = "Delete preset \"" .. name .. "\"?"
    if reaper.MB(msg, "Confirm Preset Delete", 1) ~= 1 then return end
  end
  ------------------
  return action, name
end

------------------------------------------------------------
-- Draw Preset Menu ----------------------------------------
------------------------------------------------------------
function Presets.MenuDraw()
  if not Presets.List then return end
  local x,y,w,h = Presets.Menu.x, Presets.Menu.y, Presets.Menu.w, Presets.Menu.h
  local col, col_font = Presets.Menu.col, Presets.Menu.col_font
  -- coords --------
  local x1,y1,w1,h1 = x,y,h,h    -- prev preset
  local x2,y2,w2,h2 = x+h,y,w-h*3, h -- curpreset
  local x3,y3,w3,h3 = x+w-h*2, y, h, h -- next preset
  local x4,y4,w4,h4 = x+w-h, y, h, h -- menu btn

  gfx.setfont(1,"Tahoma", h - 4) -- presets font

  SetRGB(col) -- bg color
  gfx.rect(x,y,w,h, 1)  -- main rect
  gfx.set(0.5, 0.5, 0.5, 0.15) -- frames col
  gfx.rect(x1,y1,w1,h1,0) -- prev rect
  gfx.rect(x2,y2,w2,h2,0) -- cur rect
  gfx.rect(x3,y3,w3,h3,0) -- next rect
  gfx.rect(x4,y4,w4,h4,0) -- menu rect

  SetRGB(col_font)
  gfx.x = x1; gfx.y = y1
  gfx.drawstr("<", 5, x1+w1, y1+h1) -- prev "<"
  gfx.x = x2; gfx.y = y2
  gfx.drawstr(Presets.curpresetname, 5, x2+w2, y2+h2) -- currrent
  gfx.x = x3; gfx.y = y3
  gfx.drawstr(">", 5, x3+w3, y4+h3) -- next ">"
  gfx.x = x4; gfx.y = y4
  gfx.drawstr("+", 5, x4+w4, y4+h4) -- menu "+"

  --------------------------------------
  local action, name -- init state!

  -- Menu List ---------------
  if mouseDown(x2,y2,w2,h2) then -- mouse down in curpreset rect
    gfx.x = x2; gfx.y = y2+h2;
    local menu_ret = gfx.showmenu(table.concat(Presets.List,"|"))
    if menu_ret > 0 then action, name = "Load", Presets.List[menu_ret] end -- Load
  end
  -- Prev Preset -------------
  if mouseDown(x1,y1,w1,h1) then -- mouse down in prev("<") rect
    local idx = Presets.GetByName(Presets.curpresetname)
    if not idx or idx == 1 then idx = #Presets.List+1 end
    action, name = "Load", Presets.List[idx-1] -- Load Prev
  end
  -- Next Preset -------------
  if mouseDown(x3,y3,w3,h3) then -- mouse down in next(">") rect
    local idx = Presets.GetByName(Presets.curpresetname)
    if not idx or idx == #Presets.List then idx = 0 end
    action, name = "Load", Presets.List[idx+1] -- Load Next
  end
  -- Menu Button -------------
  if mouseDown(x4,y4,w4,h4) then -- mouse down in menu("+") rect
    gfx.x = x4; gfx.y = y4+h4;
    local menu_ret, ui_ret
    menu_ret = gfx.showmenu("Save Preset|Rename Preset|Delete Preset")
    if menu_ret == 1 then      -- Save
      ui_ret, name = reaper.GetUserInputs("Save Preset", 1, "Preset name:,extrawidth=200", Presets.curpresetname)
      if ui_ret then action = "Save" end
    elseif menu_ret == 2 then  -- Rename
      ui_ret, name = reaper.GetUserInputs("Rename Preset", 1, "Preset name:,extrawidth=200", Presets.curpresetname)
      if ui_ret then action = "Rename" end
    elseif menu_ret == 3 then  -- Delete
      action, name = "Delete", Presets.curpresetname
    end
  end

  -- Confirm and return action, name ---
  if action and name and name ~= "" then
    return Presets.ConfirmAction(action, name)
  end

end

--================================================
return Presets
