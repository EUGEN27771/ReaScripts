-- @description FXRack
-- @version 1.01
-- @author EUGEN27771
-- @website http://forum.cockos.com/member.php?u=50462
-- @provides {Images,Modules,JSUtilities}/*



--[[
Паттерны match - sub и тп просмотреть.
По FLOATPOS(При добавлении через Browser) - РАБОТАЕТ НЕВЕРНО ПРИ ОПР. НАСТРОЙКАХ, убрать, сделать стандартную?
Undo - Хотя бы на примитивном уровне, особых заморочек не нужно, но сейчас полная лажа с ним!
===========================
кнопки в слоте, размеры, шрифты подпилить.
Копирование без автоматизации добавить.
Глоб. ф-ии забить в Rack:functionX()
Разделитель для ключей желательно сменить.
Запись в JSmem (можно сделать по новой схеме, более защищенно, хотя вряд ли туда полезут).
--]]


--******************************************************************************
--*** NOTE! IT'S TEST VERSION !!! **********************************************
--******************************************************************************
function msg(m) reaper.ShowConsoleMsg("\n" .. m) end

--------------------------------------------------
function get_script_path()
  local filename = debug.getinfo(1, "S").source:match("^@?(.+)$")
  return filename:match("^(.*)[\\/](.-)$") -- ret script path, name 
end
----------
function get_exe_res_proj_pathes() -- exe, resource, project pathes
  local exe_path = reaper.GetExePath()
  local resource_path = reaper.GetResourcePath("")
  local project_path = reaper.GetProjectPath("")
  return exe_path, resource_path, project_path
end
----------
function modify_package_path(new_path) -- add path to package.path
  package.path = new_path .. "/?.lua;" .. package.path
end

-- Get pathes ------------------------------------
local script_path, script_name = get_script_path()
local exe_path, resource_path, project_path = get_exe_res_proj_pathes()

-- Add script path to package.path ---------------
modify_package_path(script_path)

-- Load modules ----------------------------------
require "Modules.SimpleControls" -- Controls(global)
local FXChain = require "Modules.FXChain" -- TEST PLINK
local File = require "Modules.File"
local Presets = require "Modules.Presets"
local SplitMix = require "Modules.RackSplitMix" -- Mixer/Splitter module!
local Mixer = SplitMix.Mixer
local Splitter = SplitMix.Splitter

--------------------------------------------------------------------------------
-- Some defaults(don't change it!) ---------------------------------------------
--------------------------------------------------------------------------------
BG = gfx.loadimg(0, script_path .. "/Images/BG_PatchWork.png" ) -- BG(slot 0)
------------------------------
local Rack = {}   -- Rack Main table
Rack.version = "FXRack 1.01" -- version(в JS указ. desk:version)
-- JSFX Utilities names ------
Rack.JSSplitter = "(Split)RackSplitter"
Rack.JSMixer = "(Mix)RackMixer"
-- Presets path, ext ---------
Rack.preset_path = script_path .. "/Presets"
Rack.preset_ext = "RfxChain" -- preset extension, standart reaper fxchain
------------------------------
Rack.rows = 8     -- Rack rows num, don't change
Rack.columns = 8  -- Rack columns num, don't change

--==============================================================================
-- Несколько мат. функций ----
local min, max = math.min, math.max
local ceil, floor = math.ceil, math.floor

function minmax(x, minv, maxv)
  return min(max(x, minv),maxv)
end
------------------------------
function round(x)
  if x < 0 then return ceil(x - 0.5) else return floor(x + 0.5) end
end
------------------------------
function roundstp(x, step)
  if x < 0 then return ceil(x/step - 0.5)*step else return floor(x/step + 0.5)*step end
end

-- DB2VAL - VAL2DB -----------
function DB2VAL(x)
  return exp((x)*0.11512925464970228420089957273422);
end
------------------------------
function VAL2DB(x)
  if x < 0.0000000298023223876953125 then return -150 end
  local v = math.log(x)*8.6858896380650365530225783783321
  if v < -150 then return -150 else return v end
end

----------------------------------------
function SetRGB(RGB, a)
  gfx.r = (RGB & 0xFF0000) / 16711680 -- 256*256*255
  gfx.g = (RGB & 0x00FF00) / 65280 -- 256*255
  gfx.b = (RGB & 0x0000FF) / 255 -- 255
  gfx.a = a or 1
end

--------------------------------------------------------------------------------
-- Save/load Preset Functions --------------------------------------------------
--------------------------------------------------------------------------------
-- Write presetname to mixer memory ----
function Rack:WritePresetNameToJS(presetname)
  local track = self.track
  local fx = self.slots.Mix.fx.idx - 1 -- mixer idx, 0-based for reaper functions
  local modeparam, posparam, valparam  = 41, 42, 43 -- mem parameters indexes

  local track_auto_mode = reaper.GetTrackAutomationMode(track) -- get cur automode
  reaper.SetTrackAutomationMode(track, 0) -- set trim/read, prevent write mem sliders

  reaper.TrackFX_SetParam(track, fx, modeparam, 2) -- 2 = clear mode, clear memory
  reaper.TrackFX_SetParam(track, fx, modeparam, 1) -- 1 = wrire mode
  local str_bytes = { string.byte(presetname, 1, #presetname) }
  for i = 1, #str_bytes do
    reaper.TrackFX_SetParam(track, fx, posparam, i) -- set pos
    reaper.TrackFX_SetParam(track, fx, valparam, str_bytes[i]) -- wrire val
  end
  reaper.TrackFX_SetParam(track, fx, posparam, 0) -- set pos = 0
  reaper.TrackFX_SetParam(track, fx, valparam, 0) -- set val = 0
  reaper.TrackFX_SetParam(track, fx, modeparam, 0) -- 0 = read mode
  reaper.SetTrackAutomationMode(track, track_auto_mode) -- restore automode
end

-- Read presetname from mixer memory ---
function Rack:ReadPresetNameFromJS()
  local track = self.track
  local fx = self.slots.Mix.fx.idx - 1 -- mixer idx, 0-based for reaper functions
  local modeparam, posparam, valparam  = 41, 42, 43 -- mem parameters indexes

  local track_auto_mode = reaper.GetTrackAutomationMode(track) -- get cur automode
  reaper.SetTrackAutomationMode(track, 0) -- set trim/read, prevent write mem sliders

  reaper.TrackFX_SetParam(track, fx, modeparam, 0) -- 0 = read mode
  local str_bytes = {}
  for i = 1, 255 do
    reaper.TrackFX_SetParam(track, fx, posparam, i) -- set pos
    local val = reaper.TrackFX_GetParam(track, fx, valparam) -- read val
    if val > 0 and val < 256 then str_bytes[i] = val else break end
  end
  reaper.TrackFX_SetParam(track, fx, posparam, 0) -- set pos = 0
  reaper.TrackFX_SetParam(track, fx, valparam, 0) -- set val = 0
  reaper.SetTrackAutomationMode(track, track_auto_mode) -- restore automode
  local presetname = string.char(table.unpack(str_bytes))
  return presetname
end

--------------------------------------------------
-- Save(write to file) FXChain as preset ---------
--------------------------------------------------
-- Удаляет некоторые данные! --
-- Test Delete some datas(можно подправить)
function PresetData(presetdata)
  presetdata = presetdata:gsub("FLOATPOS %d+ %d+ %d+ %d+\n", "")
  presetdata = presetdata:gsub("FLOAT %d+ %d+ %d+ %d+\n", "")
  presetdata = presetdata:gsub("FXID {%x+%-%x+%-%x+%-%x+%-%x+}\n", "")
  return presetdata
end
-- Save(write to file) FXChain as preset ---------
function Rack:SaveFXChainAsPreset(presetname)
  local track = self.track
  if not track then return end
  local fxchain = FXChain.Get(track) -- берем текущую FXChain
  if fxchain then
    -- only fxsubchunks(для пресета берем только суб-чанки эффектов)
    local presetdata = table.concat(fxchain.fxs)
    presetdata = PresetData(presetdata)
    --msg(presetdata) -- Test msg
    return Presets.Save(presetname, presetdata) -- пишем данные в пресет
  end
end

-- Set(load + set chunk) FXChain FromPreset ------
function Rack:SetFXChainFromPreset(presetname) -- Set from preset
  local track = self.track
  if not track then return end
  local fxchain = FXChain.Get(track) -- берем текущую FXChain
  local presetdata = Presets.Load(presetname) -- читаем данные из пресета
  if fxchain and presetdata then
    -- вставляем все данные как одно поле таблицы fx_chain.fxs - здесь не важно
    fxchain.fxs = {presetdata}
    local ret = FXChain.Set(track, fxchain, true, false) -- устанавливаем FXChain, PLINK - не меняется!
    if ret then self:Update(); return true end -- Update Rack after set fxchain !!!
  end
end

--------------------------------------------------------------------------------
-- Main Preset Function --------------------------------------------------------
--------------------------------------------------------------------------------
function Rack:Presets()
  -- MenuDraw return action and name(or nil)!
  local action, presetname = Presets.MenuDraw()
  --------------------------------------
  if action == "Load" then
    if self:SetFXChainFromPreset(presetname) then
      Presets.SetCurPresetName(presetname)
      self:WritePresetNameToJS(presetname)
    end
  elseif action == "Save" then
    if self:SaveFXChainAsPreset(presetname) then
      Presets.UpdateList() -- Update presets List
      Presets.SetCurPresetName(presetname)
      self:WritePresetNameToJS(presetname)
    end
  elseif action == "Rename" then
    if Presets.Rename(Presets.curpresetname, presetname) then
      Presets.UpdateList() -- Update presets List
      Presets.SetCurPresetName(presetname)
      self:WritePresetNameToJS(presetname)
    end
  elseif action == "Delete" then
    if Presets.Delete(presetname) then
      Presets.UpdateList() -- Update presets List
      Presets.SetCurPresetName()
      self:WritePresetNameToJS("No Preset")
    end
  end
end

--------------------------------------------------------------------------------
-- Check Utilities(and create if need) -----------------------------------------
--------------------------------------------------------------------------------
function Rack:CheckUtilities(script_path, resource_path)
  local src = script_path .. "/JSUtilities/"
  local dest = resource_path .. "/Effects/FXRack/"
  -- Check exist and versions ----------
  local splitter = File.ReadBin(dest .. self.JSSplitter)
  local mixer = File.ReadBin(dest .. self.JSMixer)
  local version_str = string.format("desc:%s", self.version)
  
  if not (splitter and splitter:find(version_str,1,true)) then splitter = false end
  if not (mixer and mixer:find(version_str,1,true)) then mixer = false end
  -- Confirm ---------------------------
  if not(splitter and mixer) then
    if reaper.MB("Create/Update Utilities?", "FXRack Info", 1) ~= 1 then return end
  end
  -- Create/Update if need -------------
  if not splitter then splitter = File.Copy(src .. self.JSSplitter, dest .. self.JSSplitter) end
  if not mixer then mixer = File.Copy(src .. self.JSMixer, dest .. self.JSMixer) end
  return splitter and mixer
end

--------------------------------------------------------------------------------
-- Get Track for FXRack --------------------------------------------------------
--------------------------------------------------------------------------------
function Rack:StartButton(lbl)
  local font_sz = 30
  gfx.setfont(1, "Tahoma", font_sz)
  -------------
  local sw, sh = gfx.measurestr(lbl)
  local w, h = sw + 60, sh + 20
  local x, y = (gfx.w-w)/2, (gfx.h-h)/2
  -------------
  SetRGB(0x172837, 0.7)
  gfx.rect(x,y,w,h, 1)  -- bg
  SetRGB(0xA7C5DB, 0.2)
  gfx.rect(x,y,w,h, 0)  -- frame
  -------------
  SetRGB(0xA7C5DB) -- Info font color
  gfx.x, gfx.y = x, y
  gfx.drawstr(lbl, 5, x+w, y+h)
  -------------
  if mouseClick(x,y,w,h) then return true end
end


-- Set Rack target track -----------------------------------
function Rack:SetTrack(track)
  self.track = nil -- Reset track firstly

  -- Если нет выделенных треков, предупреждаем и уходим
  if not track then self:StartButton("No track selected!")
    return false
  end

  local fx_cnt = reaper.TrackFX_GetCount(track)
  local split, mix

  -- FXChain на треке пуста - прелагаем для FXRack, добавляем mixer/splitter
  if fx_cnt == 0 and self:StartButton("Use selected Track for FXRack?") then
    split = reaper.TrackFX_AddByName(track, self.JSSplitter, false, 1)
    mix = reaper.TrackFX_AddByName(track, self.JSMixer, false, 1)
  end

  -- FXChain на треке не пуста - проверяем на наличие mixer/splitter
  if fx_cnt > 0 then
    split = reaper.TrackFX_AddByName(track, self.JSSplitter, false, 0)
    mix = reaper.TrackFX_AddByName(track, self.JSMixer, false, 0)
    if split~=-1 and mix~=-1 then -- mixer/splitter ok
      self.track = track -- Set Rack target track
      local track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
      local track_name = select(2, reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false))
      if track_name == "" then track_name = "Untitled" end -- if untitled
      self.track_info = string.format("%s%d: %s", "Track", track_num, track_name)
      return true -- Return true if track defined!!!
    else self:StartButton("Wrong track! Read Info, or use Empty or Correct Track!")
    end
  end
  
end

--------------------------------------------------------------------------------
-- Init Slots ------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
Если row/columns будут изменяемыми(есть ли смысл), нужна инициализация на каждое изменение.
В текущем варианте(фикс. значения 8x8) - достаточно одной инициализации.
--]]
function Rack:InitSlots()
  -- Координаты --------------
  local s_x, s_y = 39, 31 -- start_x, start_y
  local slot_w, slot_h = 108, 40 -- w, h for all fx slots
  local spit_w, mix_w = 62, 125 -- mixer, splitter w
  local gap = 38  -- split/mix gap
  ----------------------------
  -- Split Images --
  local gain_png = script_path .. "/Images/knob_vol_28x28x127.png"
  -- Mix Images ----
  local gain_png = script_path .. "/Images/knob_vol_28x28x127.png"
  local pan_png = script_path .. "/Images/knob_pan_28x28x127.png"
  local phase_png = script_path .. "/Images/button_phase_22x22x2.png"
  local power_png = script_path .. "/Images/button_power_17x18x2.png"
  local solo_png = script_path .. "/Images/button_solo_22x22x2.png"
  local summode_png = script_path .. "/Images/button_summing_26x17x2.png"

  ----------------------------
  local rows, columns = self.rows, self.columns

  self.slots = {} -- Rack Slots table
  ----------------------------

  local xx, yy
  -- Pre Slots(pre:i) ------------------
  xx = s_x   -- pre slots x
  yy = s_y   -- pre slots y
  for i = 1, rows do
    self.slots["pre:".. i] = {x = xx, y = yy, w = slot_w, h = slot_h}
    yy = yy + slot_h
  end

  -- Splitter(Split) -------------------
  xx = s_x + slot_w + gap  -- splitter x
  yy = s_y                 -- splitter y
  self.slots.Split = Splitter.Init(xx, yy, spit_w, slot_h*rows, rows, gain_png)

  -- Par Slots(i:j) --------------------
  xx = s_x + slot_w + gap + spit_w  -- par slots x
  yy = s_y                          -- par slots y
  for i = 1, rows do
    xx = s_x + slot_w + gap + spit_w
    for j = 1, columns - 2 do
      self.slots[i .. ":" .. j] = {x = xx, y = yy, w = slot_w, h = slot_h}
      xx = xx + slot_w
    end
    yy = yy + slot_h
  end

  -- Mixer(Mix) ------------------------
  xx = s_x + slot_w + gap + spit_w + (columns-2)*slot_w -- mixer x
  yy = s_y                                              -- mixer y
  self.slots.Mix = Mixer.Init(xx, yy, mix_w, slot_h*rows, rows, gain_png, pan_png, power_png, phase_png, solo_png, summode_png)

  -- Post Slots(post:i) ----------------
  xx = s_x + slot_w + gap + spit_w + (columns-2)*slot_w + mix_w + gap -- post slots x
  yy = s_y                                                            -- post slots y
  for i = 1, rows do
    self.slots["post:".. i] = {x = xx, y = yy, w = slot_w, h = slot_h}
    yy = yy + slot_h
  end


  -- Две конв. таблицы n2k, k2n --------
  local t = {}
  for i = 1, rows do t[#t+1] = "pre:".. i end -- pre
  t[#t+1] = "Split"  -- split
  for i = 1, rows do
    for j = 1, columns - 2 do t[#t+1] = i .. ":" .. j end -- par
  end
  t[#t+1] = "Mix"    -- mix
  for i = 1, rows do t[#t+1] = "post:".. i end -- post
  ---------------------
  self.snum2key = t   -- slot num to slot key convert tb
  self.skey2num = {}  -- slot key to slot num convert tb
  for k, v in pairs(t) do self.skey2num[v] = k end

end

--------------------------------------------------------------------------------
-- Update Rack, Get TrackFX Chain, link FXs to Slots, Verifty ------------------
--------------------------------------------------------------------------------
-- Verify Chain ----------------------------------
function Rack:VerifyChain()
  local track = self.track
  local rows, columns, slots = self.rows, self.columns, self.slots
  local undef_fx, dupl_fx = self.undef_fx, self.dupl_fx
  local t = {} -- temp table
  -- linked FX by slots order ----------
  for i = 1, #self.snum2key do
    local k = self.snum2key[i]
    local slot = slots[k]
    if slot.fx then t[#t+1] = slot.fx.idx end
  end
  -- Check FX order ----------
  local order = true -- init as true
  for k, v in pairs(t) do
    if k~=v then order = false break end
  end
  -- Fix Chain if need -------
  if not order or #undef_fx > 0 or #dupl_fx > 0 then
    --[[ TEST msg! ---
    if not order then msg("no order") 
    elseif #undef_fx > 0 then msg("undef_fx > 0") 
    elseif #dupl_fx > 0 then msg("dupl_fx > 0") 
    end --]]
    ----------------
    local fx_chain = FXChain.Get(self.track)
    for i = 1, #t do -- fix fx order and use only valid fx
      t[i] = FXChain.GetFXChunk(fx_chain, t[i])
    end
    fx_chain.fxs = t -- устан. вместо текущих суб-чанков
    FXChain.Set(track, fx_chain, true, true) -- set fixed fxchain
    self:Update() -- Update after fixes
  end

  -- Set N channels if need --
  if reaper.GetMediaTrackInfo_Value(track, "I_NCHAN") ~= rows * 2 then
    reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", rows * 2)
  end

end

-- Slot - Link To FX ---------------------------------------
function Rack:SlotLinkToFX(skey, fx_idx, fxname) -- fx_idx 1-based!
  if skey == "Mix" or skey == "Split" then -- for mixer/splitter
    SplitMix.LinkToJS(self.slots[skey], self.track, fx_idx, fxname)
  else -- for other fx
    fxname = fxname:gsub("%s", "")
    fxname = fxname:gsub("%(.-%)", "")
    fxname = fxname:gsub("%w+:", "")   -- result = short name
    self.slots[skey].fx = {idx = fx_idx, name = fxname } -- LinkToFX
    SlotFXSetPinMap(skey) -- hard set pinmap for fx
  end
end

-- Update - Get TrackFX Chain, link to slots by keys -------
function Rack:Update()
  --if not GetChainCnt then GetChainCnt = 1 else GetChainCnt = GetChainCnt+1 end
  ------------------
  self.fx_cnt = reaper.TrackFX_GetCount(self.track)
  self.undef_fx = {} -- for undefined fxs
  self.dupl_fx = {}  -- for duplicated fxs
  ------------------
  for k, v in pairs(self.slots) do v.fx = nil end -- Clear all fx-links
  ------------------
  for i = 1, self.fx_cnt do
    local ret, fxname = reaper.TrackFX_GetFXName(self.track, i-1, "")
    local skey = fxname:match("^%((pre:%d)%)") or  -- pre
                 fxname:match("%((Split)%)") or    -- spliter
                 fxname:match("^%((%d:%d)%)") or   -- parallels
                 fxname:match("%((Mix)%)") or      -- mixer
                 fxname:match("^%((post:%d)%)")    -- post
    ----------------
    if skey then -- if valid key found
      if not self.slots[skey].fx then
        self:SlotLinkToFX(skey, i, fxname) -- OK, Verified FX!
      else
        self.dupl_fx[#self.dupl_fx+1] = i  -- Duplicateted FX!
      end
    else -- if valid key not found
      self.undef_fx[#self.undef_fx+1] = i  -- Undefined FX!
    end
  end
  ------------------
  self:VerifyChain() -- verify/fix chain
  ------------------
end

--------------------------------------------------------------------------------
-- Open/Close FX Browser -------------------------------------------------------
--------------------------------------------------------------------------------
--[[
OpenFXBrowser - однозначно открывает(open/re-open) FX-browser
CloseFXBrowser - однозначно закрывает браузер
Сам экшн(40271) без двойной проверки косячит, поэтому только так.
--]]
function OpenFXBrowser()
  local state = reaper.GetToggleCommandState(40271)
  if state == 1 then reaper.Main_OnCommand(40271, 0) end
  state = reaper.GetToggleCommandState(40271)
  if state == 0 then reaper.Main_OnCommand(40271, 0) end
end
--------
function CloseFXBrowser()
  local state = reaper.GetToggleCommandState(40271)
  if state == 1 then reaper.Main_OnCommand(40271, 0) end
  state = reaper.GetToggleCommandState(40271)
  if state == 1 then reaper.Main_OnCommand(40271, 0) end
end

--------------------------------------------------------------------------------
-- SetInOutPair, note: fx_idx 1-based, chans_pair 1-based(1 = 1/2, 2 = 3/4 etc)-
--------------------------------------------------------------------------------
function SlotFXSetPinMap(skey)
  local track, slot = Rack.track, Rack.slots[skey]
  local fx, chans_pair
  if slot.fx then fx = slot.fx.idx - 1 else return end -- 0-based for reaper functions
  local chans_pair = tonumber(skey:match("(%d):%d")) or 1 -- 1 for pre/post
  -- Set pinmap for fx -----------------
  local ret, inPins, outPins = reaper.TrackFX_GetIOSize(track, fx)
  if not(ret and inPins and outPins) then return end -- if not retvals
  -- Reset all in/out pins ---
  for i = 1, inPins do reaper.TrackFX_SetPinMappings(track, fx, 0, i-1, 0, 0) end
  for i = 1, outPins do reaper.TrackFX_SetPinMappings(track, fx, 1, i-1, 0, 0) end

  local Low32L = 2^((chans_pair-1)*2)
  local Low32R = 2^((chans_pair-1)*2 + 1)
  -- Set in pair -------------
  if inPins > 0 then reaper.TrackFX_SetPinMappings(track, fx, 0, 0, Low32L, 0)
    if inPins > 1 then reaper.TrackFX_SetPinMappings(track, fx, 0, 1, Low32R, 0) end
  end
  -- Set out pair ------------
  if outPins > 0 then reaper.TrackFX_SetPinMappings(track, fx, 1, 0, Low32L, 0)
    if outPins > 1 then reaper.TrackFX_SetPinMappings(track, fx, 1, 1, Low32R, 0)
    else reaper.TrackFX_SetPinMappings(track, fx, 1, 0, Low32L + Low32R, 0) -- for mono plugins
    end
  end
end

--------------------------------------------------------------------------------
-- FindPrevNoEmptySlot(skey) ---------------------------------------------------
--------------------------------------------------------------------------------
function SlotFindPrevNoEmpty(skey)
  local prev
  for i = 1, #Rack.snum2key do
    local k = Rack.snum2key[i]
    if k == skey then return prev end
    if Rack.slots[k].fx then prev = k end
  end
end

--------------------------------------------------------------------------------
-- Configurate Added FX --------------------------------------------------------
--------------------------------------------------------------------------------
function SlotConfigAddedFX()
  local dest_track = Browser.dest_track -- dest track
  local open_fx_cnt = Browser.open_fx_cnt -- fx_cnt до открытия Browser
  local close_fx_cnt = reaper.TrackFX_GetCount(dest_track) -- fx_cnt после закрытия Browser
  if close_fx_cnt <= open_fx_cnt then return end  -- если ничего не добавлено, уходим отсюда
  --------------------------------------
  local src_idx = open_fx_cnt + 1       -- source fx idx, 1-based
  local dest_idx = Browser.dest_idx     -- dest fx idx, 1-based
  local dest_skey = Browser.dest_skey   -- dest slot key
  --------------------------------------
  local fx_chain = FXChain.Get(dest_track)
  if not fx_chain then return end -- return if not chain table

    -- Create new name for added fx ----
    local ret, fxname = reaper.TrackFX_GetFXName(dest_track, src_idx - 1, "") -- здесь idx 0-based!
    fxname = "\"" .. "(" .. dest_skey .. ") " .. fxname .. "\""  -- new fxname = (skey) + fxname
    -- Set New Name(with skey) ---------
    local src_fx_chunk = FXChain.GetFXChunk(fx_chain, src_idx) -- source chunk
    local s, e, fx_type = src_fx_chunk:find("<(%u+)%s.-\n") -- тип на всякий случай
    if s then
      local str = src_fx_chunk:sub(s, e):gsub("\"\"", fxname)
      src_fx_chunk = src_fx_chunk:sub(1, s-1) .. str .. src_fx_chunk:sub(e+1)
    end
    -- Set Floatpos(как удобно?) -------
    -- РАБОТАЕТ НЕВЕРНО ПРИ ОПР. НАСТРОЙКАХ, убрать, сделать стандартную!!???
    local slot = Rack.slots[dest_skey] -- пока считаем по коорд. слота
    local x, y = gfx.clienttoscreen(slot.x + slot.w, slot.y - 300)
    local pos_str = "FLOAT ".. x .. " ".. max(y, 0) .. " 100 100\n"
    src_fx_chunk = src_fx_chunk:gsub("FLOATPOS %d+ %d+ %d+ %d+\n", pos_str)

  --------------------------------------
  -- Remove all FX after src and remove src(он больше не нужен)
  -- SetFXChunk if dest slot NO EMPTY, else InsertFXFromChunk
  FXChain.RemoveFX(fx_chain, src_idx, close_fx_cnt)
  if Rack.slots[dest_skey].fx then FXChain.SetFXChunk(fx_chain, src_fx_chunk, dest_idx)
  else FXChain.InsertFXFromChunk(fx_chain, src_fx_chunk, dest_idx)
  end
  --------------------------------------
  FXChain.Set(dest_track, fx_chain, true, true) -- use_src_track_chunk, rebuild_plink = true!
  ------------------
  Rack:Update() -- Update

end


--------------------------------------------------------------------------------
-- Main Add/Replace FX function via FX Browser ---------------------------------
--------------------------------------------------------------------------------
--[[
Не забыть! В случае закрытия осн. скрипта,
браузер можно и оставить, но лучше его закрыть!
--]]
function SlotAddReplaceFX(skey)
  if not Browser then
    Browser = {} -- FX Browser main table
    --------------------------
    Browser.dest_track = Rack.track -- dest track
    Browser.open_fx_cnt = reaper.TrackFX_GetCount(Rack.track) -- fx_cnt до открытия
    Browser.dest_skey = skey -- dest slot key
    --------------------------
    local prev_skey = SlotFindPrevNoEmpty(skey) -- предыдущий непустой слот
    if not prev_skey then Browser.dest_idx = 1
    else Browser.dest_idx = Rack.slots[prev_skey].fx.idx + 1 -- dest fx_idx
    end
    --------------------------
    OpenFXBrowser() -- открывает(либо переоткрывает для тек. трека) Browser
  end

  ----------------------------
  if not reaper.ValidatePtr(Browser.dest_track, "MediaTrack*") or
    Browser.dest_track ~= Rack.track or not Browser.dest_skey then
    CloseFXBrowser() -- закрывает Браузер
    Browser = nil    -- del Browser table
    return "Track Changed!"
  end

  ----------------------------
  local state = reaper.GetToggleCommandState(40271) -- get browser open state
  local fx_cnt = reaper.TrackFX_GetCount(Browser.dest_track) -- текущее кол-во fx
  ----------------------------
  if state == 0 or fx_cnt ~= Browser.open_fx_cnt then -- state or fx_cnt change
    reaper.TrackFX_Show(Browser.dest_track, 0, 0) -- close fx chain, обязательно
    SlotConfigAddedFX(Browser.dest_skey)
    Browser = nil  -- del table
    --------------------------
  else reaper.defer(SlotAddReplaceFX)
  end

end

--------------------------------------------------------------------------------
-- Remove/Copy/Cut/Paste FX ----------------------------------------------------
--------------------------------------------------------------------------------
-- Rack:Update() после операций, по сути не нужен, но лучше наверняка...

-- Remove FX -------------------------------------
function SlotRemoveFX(skey)
  local slot = Rack.slots[skey]
  if not slot.fx then return end
  local fx_chain = FXChain.Get(Rack.track)
  if not fx_chain then return end
  FXChain.RemoveFX(fx_chain, slot.fx.idx)
  FXChain.Set(Rack.track, fx_chain, true, true)
  ------------------
  Rack:Update()
end

-- Copy FX to Clipboard  -------------------------
function SlotCopyOrCutFX(src_skey, isCut)
  local slot = Rack.slots[src_skey]
  if not slot.fx then return end
  local fx_chain = FXChain.Get(Rack.track)
  if not fx_chain then return end
  Rack.Clipboard = FXChain.GetFXChunk(fx_chain, slot.fx.idx)
  ------------------
  if isCut then
    FXChain.RemoveFX(fx_chain, slot.fx.idx)
    FXChain.Set(Rack.track, fx_chain, true, true)
  end
  ------------------
  Rack:Update()
end

-- Paste FX from Clipboard  ----------------------
function SlotPasteFX(dest_skey)
  if not Rack.Clipboard then return end -- if clipboard is empty
  local dest_idx
  local prev_skey = SlotFindPrevNoEmpty(dest_skey) -- предыдущий непустой слот
  if prev_skey then dest_idx = Rack.slots[prev_skey].fx.idx + 1 else dest_idx = 1 end
  ------------------
  local fx_chain = FXChain.Get(Rack.track)
  if not fx_chain then return end
  local fx_chunk = Rack.Clipboard
  fx_chunk = fx_chunk:gsub("%([preost%d]-:%d%)", "(" .. dest_skey .. ")", 1) -- new name
  fx_chunk = fx_chunk:gsub("<PROGRAMENV %d+ %d+\n.->", "") -- Del PE
  fx_chunk = fx_chunk:gsub("FXID {%x+%-%x+%-%x+%-%x+%-%x+}", "FXID " .. reaper.genGuid(""), 1) -- New FXID
  ------------------
  if Rack.slots[dest_skey].fx then FXChain.SetFXChunk(fx_chain, fx_chunk, dest_idx)
  else FXChain.InsertFXFromChunk(fx_chain, fx_chunk, dest_idx)
  end
  ------------------
  FXChain.Set(Rack.track, fx_chain, true, true)
  ------------------
  Rack:Update()
end

-- Drag Move -------------------------------------
function SlotDragMoveFX(src_skey, dest_skey)
  local src_idx = Rack.slots[src_skey].fx.idx
  local dest_idx
  local prev_skey = SlotFindPrevNoEmpty(dest_skey) -- предыдущий непустой слот
  if prev_skey then dest_idx = Rack.slots[prev_skey].fx.idx + 1 else dest_idx = 1 end
  ------------------
  local fx_chain = FXChain.Get(Rack.track)
  if not fx_chain then return end
  local fx_chunk = FXChain.GetFXChunk(fx_chain, src_idx)
  fx_chunk = fx_chunk:gsub("%([preost%d]-:%d%)", "(" .. dest_skey .. ")", 1) -- new name
  FXChain.InsertFXFromChunk(fx_chain, fx_chunk, dest_idx) -- Добавление в dest-Позицию
  if dest_idx <= src_idx then src_idx = src_idx + 1 end -- Коррект. src_idx!
  FXChain.RemoveFX(fx_chain, src_idx) -- Удаление исходного
  ------------------
  FXChain.Set(Rack.track, fx_chain, true, true)
  ------------------
  Rack:Update()
end

-- Drag Copy -------------------------------------
function SlotDragCopyFX(src_skey, dest_skey)
  local src_idx = Rack.slots[src_skey].fx.idx
  local dest_idx
  local prev_skey = SlotFindPrevNoEmpty(dest_skey) -- предыдущий непустой слот
  if prev_skey then dest_idx = Rack.slots[prev_skey].fx.idx + 1 else dest_idx = 1 end
  ------------------
  local fx_chain = FXChain.Get(Rack.track)
  if not fx_chain then return end
  local fx_chunk = FXChain.GetFXChunk(fx_chain, src_idx)
  fx_chunk = fx_chunk:gsub("%([preost%d]-:%d%)", "(" .. dest_skey .. ")", 1) -- new name
  fx_chunk = fx_chunk:gsub("<PROGRAMENV %d+ %d+\n.->", "") -- Del PE on DragCopy(optionally?)
  fx_chunk = fx_chunk:gsub("FXID {%x+%-%x+%-%x+%-%x+%-%x+}", "FXID " .. reaper.genGuid(""), 1) -- New FXID
  FXChain.InsertFXFromChunk(fx_chain, fx_chunk, dest_idx) -- Добавление в dest-Позицию
  ------------------
  FXChain.Set(Rack.track, fx_chain, true, true)
  ------------------
  Rack:Update()
end

--------------------------------------------------------------------------------
-- Draw Slot(pre/post/par) by slot key -----------------------------------------
--------------------------------------------------------------------------------
function Rack:SlotDraw(skey)
  local slot = self.slots[skey]
  local x, y, w, h = slot.x+1, slot.y+1, slot.w-2, slot.h-2
  local x1, x2, x3, y1, y2, b_w, b_h
  local fx, fxname, fx_enabled
  --------------------------------------
  if slot.fx then
    fx = slot.fx.idx - 1  -- Slot fx link, 0-based for reaper.functions!
    fxname = slot.fx.name -- linked fx name
    -- Если делать ресайз, x,y,w,h надо считать от осн. размеров слота!
    x1, x2, x3 = x+2, x+37, x+72 -- btn 1, 2, 3 x-coord
    y1, y2 = y+2, y+h/2+2  -- btn line1, line2 y-coord, I use 2 lines
    b_w, b_h = 32, 16
    -- Эти параметры нужно брать постоянно!
    fx_enabled = reaper.TrackFX_GetEnabled(self.track, fx)
  end


  -- Add/Show-Hide/Bypass slot FX ------
  if mouseDown(x,y,w,h) and not(mouse_Shift or mouse_Ctrl) then
    if fx then
      if mouseIN(x1, y1, b_w, b_h) then -- Bypass
        reaper.TrackFX_SetEnabled(self.track, fx, not fx_enabled )
      else
        local show = 3 -- 2/3 = show/hide float window
        if reaper.TrackFX_GetOpen(self.track, fx) then show = 2 end
        reaper.TrackFX_Show(self.track, fx, show)
      end
    else
      SlotAddReplaceFX(skey) -- Add or Replace FX
    end
  end

  -- Drag Move/Copy = Shift/Ctrl -------
  if mouseDown(x,y,w,h) and (mouse_Shift or mouse_Ctrl) and slot.fx then 
    self.CapSlot = skey
  end
  ------------------
  if self.CapSlot and mouseUp(x,y,w,h) then
    if not slot.fx then
      if mouse_Ctrl and not mouse_Shift then SlotDragCopyFX(self.CapSlot, skey)
      elseif mouse_Shift and not mouse_Ctrl then SlotDragMoveFX(self.CapSlot, skey)
      end
      reaper.Undo_OnStateChangeEx("FXRack Copy-Move", -1, -1) -- TEST
    end
    self.CapSlot = nil
  end
  
  -- Slot Menu -------------------------
  if mouseRDown(x,y,w,h) then
    gfx.x, gfx.y  = gfx.mouse_x, gfx.mouse_y
    local menu
    if slot.fx then menu = "Add/Replace FX|Remove FX||Copy FX|Cut FX||#Paste" 
    else menu = "Add/Replace FX|#Remove FX||#Copy FX|#Cut FX||Paste" 
    end
    ----------------
    local menu_ret = gfx.showmenu(menu)
    if menu_ret == 1 then Browser = nil; SlotAddReplaceFX(skey) -- Reset Browser; Add or Replace FX
    elseif menu_ret == 2 and slot.fx then SlotRemoveFX(skey) -- Remove FX
    elseif menu_ret == 3 and slot.fx then SlotCopyOrCutFX(skey, false) -- Copy FX
    elseif menu_ret == 4 and slot.fx then SlotCopyOrCutFX(skey, true)  -- Cut FX
    elseif menu_ret == 5 and not slot.fx then SlotPasteFX(skey)  -- Paste FX
    end
  end


  --- DRAW Slot ------------------------

  -- Slot mini btns ----------
  if fx then
    SetRGB(0x183146)
    gfx.rect(x1, y1, b_w, b_h, 1) -- on/off btn
    gfx.rect(x2, y1, b_w, b_h, 1) -- row/column btn
    gfx.rect(x3, y1, b_w, b_h, 1) -- empty btn
  end

  -- Slot FX Info ------------
  gfx.setfont(1, "Tahoma", 14) -- Slot btns font
  SetRGB(0x91ADC2)
  if fx then -- if slot Linked to FX, draw mini btns
    -- On/Off state ----------
    gfx.x, gfx.y = x1, y1
    local str
    if fx_enabled then str = "On" else str = "Off" end
    gfx.drawstr(str, 5, x1 + b_w, y1 + b_h) -- on/off
    -- Slot Key(row/column) --
    gfx.x, gfx.y = x2, y1
    gfx.drawstr(skey, 5, x2 + b_w, y1 + b_h) -- slot key
    -- FX name ---------------
    local flag -- align to center or left(for long fx names)
    if gfx.measurestr(fxname) > w - 6 then flag = 4 else flag = 5 end
    gfx.x, gfx.y = x1, y2
    gfx.drawstr(fxname, flag, x + w - 3, y2 + b_h) -- slot fx name
    -- Mask(if FX bypassed) --
    if not fx_enabled then
      SetRGB(0x000000, 0.4) -- mask col
      gfx.rect(x+1, y+1, w-2, h-2, 1) -- mask
    end
  else -- if slot is Empty, draw "+" btn only
    gfx.a = 0.4
    gfx.x, gfx.y = x, y
    gfx.drawstr("+", 5, x+w, y+h)
  end

end

--------------------------------------------------------------------------------
-- Get Project Change, update proj_change count --------------------------------
--------------------------------------------------------------------------------
function ProjectChange()
  local cur_cnt = reaper.GetProjectStateChangeCount(0)
  if cur_cnt ~= proj_change then proj_change = cur_cnt
     return true
  end
end

--------------------------------------------------------------------------------
function Rack:Meter()
  local x,y,w,h = 1179, 13, 14, 344
  local RGB, a = 0x5BA5BD, 0.8 -- meter color
  local minv, maxv = -60, 0

  local peakL = reaper.Track_GetPeakInfo(self.track, 0)
  local peakR = reaper.Track_GetPeakInfo(self.track, 1)
  peakL = VAL2DB(peakL)
  peakR = VAL2DB(peakR)

  local range = maxv - minv
  local normL = min((peakL - minv)/range, 1)
  local normR = min((peakR - minv)/range, 1)
  local hL, hR = h*normL, h*normR
  SetRGB(RGB, a)
  --gfx.rect(x,y,w,h,0) -- test rect
  gfx.rect(x, y+h-hL, w*0.5-1, hL)
  gfx.rect(x+w*0.5+1, y+h-hR, w*0.5-1, hR)
  --
end

--------------------------------------------------------------------------------
function Rack:Help()
  -- Должна быть краткая информация или что-то такое.
end

--------------------------------------------------------------------------------
-- Main Draw Rack function -----------------------------------------------------
--------------------------------------------------------------------------------
--[[
Можно объединить некоторые ф-и. 
В теории, можно вообще отнести их в Update. 
--]]
function Rack:Draw()
  -- Draw Background -----------------------------
  gfx.x, gfx.y = 0, 0
  gfx.a = 1
  gfx.blit(BG, 1, 0) -- Main BG:)
  --BGW, BGH = gfx.getimgdim(BG)

  -- Get first selected track --------------------
  local track = reaper.GetSelectedTrack(0, 0)

  -- Update on track, project changes ------------
  if not track or self.track ~= track then
    if self:SetTrack(track) then
      self:Update() -- Update Rack
      local curpresetname = self:ReadPresetNameFromJS() -- Get CurPreset
      Presets.SetCurPresetName(curpresetname)
      ProjectChange() -- upd cnt, prevent duble update
    else return
    end
  elseif ProjectChange() then
    if self:SetTrack(track) then
      self:Update()
      ProjectChange() -- upd cnt, prevent duble update
    else return
    end
  end

  -- Draw Track info -----------------------------
  local x,y,w,h = 180, 6, 280, 18 -- info rect
  gfx.x = x; gfx.y = y;
  SetRGB(0xA7C5DB) -- Info font color
  gfx.setfont(1, "Tahoma", 13)
  gfx.drawstr(self.track_info, 4, x + w, y + h);

  -- Draw Slots(Pre, Par, Post, no ordered) ------
  for k, v in pairs(self.slots) do
    if k ~= "Split" and k ~= "Mix" then self:SlotDraw(k) end
  end

  -- Draw Mixer, Splitter ------------------------
  SplitMix.Draw(self.slots.Split)  -- Splitter
  SplitMix.Draw(self.slots.Mix)    -- Mixer

  -- Draw drag move/copy cap slot ----------------
  if self.CapSlot then
    if gfx.mouse_cap&1 == 0 then
      self.CapSlot = nil -- Release cap slot, no cap slots
    else
      local slot = self.slots[self.CapSlot]
      local x, y, w, h = slot.x, slot.y, slot.w, slot.h
      gfx.a = 1
      gfx.blit(-1, 1, 0, x, y, w, h, gfx.mouse_x-10, gfx.mouse_y-10, w, h)
      SetRGB(0xB30000, 0.1) -- red
      gfx.rect(x, y, w, h)  -- highlighting
    end
  end

  -- Draw Meter ----------------------------------
  self:Meter()

  -- Draw Presets --------------------------------
  self:Presets()

end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
  gfx.clear = 0x180E01 -- bg color
  gui = {w = 1225, h = 382 , dock = 0, x = 100, y = 300}
  gfx.init(script_name, gui.w, gui.h, gui.dock, gui.x, gui.y)
  mouse_last_cap = 0
  mouse_down_x, mouse_down_y = 0, 0
  mouse_last_x, mouse_last_y = 0, 0
end

--------------------------------------------------------------------------------
--   Mainloop   ----------------------------------------------------------------
--------------------------------------------------------------------------------
function mainloop()
  -- mouse state -----------------------
  mouse_down = gfx.mouse_cap&1==1 and mouse_last_cap&1==0
  mouse_rdown = gfx.mouse_cap&2==2 and mouse_last_cap&2==0
  mouse_up = gfx.mouse_cap&1==0 and mouse_last_cap&1==1
  mouse_rup = gfx.mouse_cap&2==0 and mouse_last_cap&2==2
  if mouse_down then mouse_down_x, mouse_down_y = gfx.mouse_x, gfx.mouse_y end
  mouse_move = (mouse_last_x ~= gfx.mouse_x) or (mouse_last_y ~= gfx.mouse_y)
  -- modkeys state ---------------------
  mouse_Ctrl  = gfx.mouse_cap&4==4
  mouse_Shift = gfx.mouse_cap&8==8
  mouse_Alt   = gfx.mouse_cap&16==16

  --------------------------------------
  Rack:Draw() -- Main Rack function
  --------------------------------------

  -- update mouse last state -----------
  gfx.mouse_wheel = 0
  gfx.mouse_hwheel = 0
  mouse_last_cap = gfx.mouse_cap
  mouse_last_x = gfx.mouse_x
  mouse_last_y = gfx.mouse_y

  --------------------------------------
  gfx.update() -- Update gfx window
  --------------------------------------
  char = gfx.getchar()
  if char==32 then reaper.Main_OnCommand(40044, 0) end -- play
  if char~=-1 then reaper.defer(mainloop) end          -- defer

end

--------------------------------------------------------------------------------
-- START -----------------------------------------------------------------------
--------------------------------------------------------------------------------
if Rack:CheckUtilities(script_path, resource_path) then
  Rack:InitSlots()
  Presets.MenuInit(472,6,280,18, 0x021B2D, 0xa7c5db, Rack.preset_path, Rack.preset_ext)
  -- Поехали --
  Init()
  mainloop()
end
