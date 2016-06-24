--[[
   * ReaScript Name: Save Preset for last touched VST
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.01
  ]]

--------------------------------------------------------------------------------
-- Base64_to_Hex(modded from lua.org functions)  -------------------------------
--------------------------------------------------------------------------------
-- decryption table --
local base64bytes = {['A']=0, ['B']=1, ['C']=2, ['D']=3, ['E']=4, ['F']=5, ['G']=6, ['H']=7, ['I']=8, ['J']=9, ['K']=10,['L']=11,['M']=12,
                     ['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,
                     ['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,
                     ['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,
                     ['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+']=62,['/']=63,['=']=nil}
--------------------------------------------
-- Decode Base64 to HEX --------------------
--------------------------------------------
function B64_to_HEX(data)
  local chars  = {}
  local result = {}
  local hex
    for dpos=0, #data-1, 4 do
        -- Get chars -------------------
        for char=1,4 do chars[char] = base64bytes[(string.sub(data,(dpos+char), (dpos+char)) or "=")] end -- Get chars
        -- To hex ----------------------
        if chars[3] and chars[4] then 
            hex = string.format('%02X%02X%02X',                                  -- if 1,2,3,4 chars
                                   (chars[1]<<2)       + ((chars[2]&0x30)>>4),   -- 1
                                   ((chars[2]&0xf)<<4) + (chars[3]>>2),          -- 2
                                   ((chars[3]&0x3)<<6) + chars[4]              ) -- 3
          elseif  chars[3] then 
            hex = string.format('%02X%02X',                                      -- if 1,2,3 chars
                                   (chars[1]<<2)       + ((chars[2]&0x30)>>4),   -- 1
                                   ((chars[2]&0xf)<<4) + (chars[3]>>2),          -- 2
                                   ((chars[3]&0x3)<<6)                         )
          else
            hex = string.format('%02X',                                          -- if 1,2 chars
                                   (chars[1]<<2)       + ((chars[2]&0x30)>>4)  ) -- 1
        end 
       ---------------------------------
       table.insert(result,hex)
    end
  return table.concat(result)  
end

----------------------------------------
-- Name to Hex  ------------------------
----------------------------------------
function Name_to_Hex(Preset_Name)
  local VAL  = {Preset_Name:byte(1,-1)} -- to bytes, values
  local Pfmt = string.rep("%02X", #VAL)
  local HEX  = string.format(Pfmt, table.unpack(VAL))
  return "00"..HEX.."0010000000"        -- it may be not valid ?
end

--------------------------------------------------------------------------------
-- FX_Chunk_to_HEX -------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variant 1 ---------------------------
function FX_Chunk_to_HEX(FX_Chunk, Preset_Name)
  local Preset_Chunk = FX_Chunk:match("\n.*\n")     -- extract preset(simple var)
  local Hex_TB = {}
  local init = 1
  ---------------------
  for i=1, math.huge do 
        line = Preset_Chunk:match("\n.-\n", init)   -- extract line from preset(simple var)
        if not line then
           --reaper.ShowConsoleMsg(Hex_TB[i-1].."\n")
           Hex_TB[i-1] = Name_to_Hex(Preset_Name)   -- Name_to_Hex(replace name-line from chunk)
           --reaper.ShowConsoleMsg(Hex_TB[i-1].."\n")
           break 
        end
        ---------------
        init = init + #line - 1                    -- for next line
        line = line:gsub("\n","")                  -- del "\n"
        --reaper.ShowConsoleMsg(line.."\n")
        Hex_TB[i] = B64_to_HEX(line)
  end
  ---------------------
  return table.concat(Hex_TB)
end

-- Variant 2(without Name to Hex) ------
--[[
function FX_Chunk_to_HEX(FX_Chunk, Preset_Name)
  local Preset_Chunk = FX_Chunk:match("\n.*\n")   -- extract preset(simple var)
  ----------------------------------------
  Preset_Chunk = Preset_Chunk:gsub("\n","")       -- del "\n"
  return B64_to_HEX(Preset_Chunk)
end
--]]

--------------------------------------------------------------------------------
-- Get_CtrlSum -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Get_CtrlSum(HEX)
  local Sum = 0
  for i=1, #HEX, 2 do  Sum = Sum + tonumber( HEX:sub(i,i+1), 16) end
  return string.sub( string.format("%X", Sum), -2, -1 ) 
end

--------------------------------------------------------------------------------
-- Write preset to PresetFile --------------------------------------------------
--------------------------------------------------------------------------------
function Write_to_File(PresetFile, Preset_HEX, Preset_Name) 
  local file, Presets_ini, Nprsts
  ----------------------------------------------------------
  -- Rewrite header(or create) -----------------------------
  ----------------------------------------------------------
    local ret_r, ret_w
    if reaper.file_exists(PresetFile) then 
        -- BR function works faster than lua r,w --
        ret_r, Nprsts =  reaper.BR_Win32_GetPrivateProfileString("General", "NbPresets", "", PresetFile)
        Nprsts = math.tointeger(Nprsts)
        ------------------
        ret_w = reaper.BR_Win32_WritePrivateProfileString("General", "NbPresets", math.tointeger(Nprsts)+1, PresetFile)
    else Nprsts = 0
         Presets_ini = "[General]\nNbPresets="..Nprsts+1
         file = io.open(PresetFile, "w")
         file:write(Presets_ini)
         file:close()
    end 
  ----------------------------------------------------------
  -- Write preset data to file -----------------------------
  ----------------------------------------------------------
  file = io.open(PresetFile, "r+")
  file:seek("end")                        -- to end of file
  ------------------
  file:write("\n[Preset"..Nprsts.."]")    -- preset number(0-based)
  --------------------------------------
  --------------------------------------
  local Len = #Preset_HEX                 -- Data Lenght
  local s = 1
  local Ndata = 0 
  for i=1, math.ceil(Len/32768) do
      if i==1 then Ndata = "\nData=" else Ndata = "\nData_".. i-1 .."=" end   
      local Data = Preset_HEX:sub(s, s+32767)
      local Sum = Get_CtrlSum(Data)
      file:write(Ndata, Data, Sum)
      s = s+32768
  end
  --------------------------------------
  --- Preset_Name, Data Lenght ---------
  --------------------------------------
  file:write("\nName=".. Preset_Name .."\nLen=".. Len//2 .."\n")
  -------------------
  file:close()
end

--------------------------------------------------------------------------------
-- Get FX_Chunk and PresetFile  ------------------------------------------------
--------------------------------------------------------------------------------
function Get_FX_Data(track, fxnum)
  local fx_cnt = reaper.TrackFX_GetCount(track)
  if fx_cnt==0 or fxnum>fx_cnt-1 then return end          -- if fxnum not valid
  local ret, Track_Chunk =  reaper.GetTrackStateChunk(track,"",false)
  --reaper.ShowConsoleMsg(Track_Chunk)
  
  ------------------------------------
  -- Find FX_Chunk(use fxnum) --------
  ------------------------------------
  local s, e = Track_Chunk:find("<FXCHAIN")             -- find FXCHAIN section
  -- find VST(or JS) chunk 
  for i=1, fxnum+1 do
      s, e = Track_Chunk:find("%b<>", e)                    
  end
    ----------------------------------
    -- if FX(fxnum) type ~= "VST" ----
    if Track_Chunk:sub(s+1, s+3)~="VST" then return end   -- Only VST supported
    ----------------------------------
    -- extract FX_Chunk -------------- 
    local FX_Chunk = Track_Chunk:match("%b<>", s)         -- FX_Chunk(simple var)
    ----------------------------------
    --reaper.ShowConsoleMsg(FX_Chunk.."\n")
  
  ------------------------------------
  -- Get UserPresetFile --------------
  ------------------------------------
  local PresetFile = reaper.TrackFX_GetUserPresetFilename(track, fxnum, "")
  ------------------------------------
  return FX_Chunk, PresetFile
end

--------------------------------------------------------------------------------
-- Main function  --------------------------------------------------------------
--------------------------------------------------------------------------------
function Save_VST_Preset(track, fxnum, Preset_Name)
  if not (track and fxnum and Preset_Name) then return end   --  Need track, fxnum, Preset_Name
  local FX_Chunk, PresetFile = Get_FX_Data(track, fxnum)
  -----------
  if FX_Chunk and PresetFile then
     local start_time = reaper.time_precise() 
     local Preset_HEX = FX_Chunk_to_HEX(FX_Chunk, Preset_Name)
     --reaper.ShowConsoleMsg("Processing time = ".. reaper.time_precise()-start_time ..'\n') -- time test
     ------
     local start_time = reaper.time_precise()
     Write_to_File(PresetFile, Preset_HEX, Preset_Name)
     --reaper.ShowConsoleMsg("Write time = ".. reaper.time_precise()-start_time ..'\n') -- time test
     ------
     reaper.TrackFX_SetPreset(track, fxnum, Preset_Name) -- For "update", but this is optional
  end
end    

----------------------------------------------------------------------------------------------------
-- GetLastTouchedFX  -------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Get_LastTouch_FX()
  local retval, tracknum, fxnum = reaper.GetLastTouchedFX()            -- fxnum  
  if not retval then return end                       
  local track = reaper.GetTrack(0, tracknum-1)                         -- track(trackID)
  local Pidx, Npt = reaper.TrackFX_GetPresetIndex(track, fxnum)
  if Pidx==-1   then return end 
  local  Preset_Name = "New "..Npt+1                                   -- New Preset_Name
  return track, fxnum, Preset_Name
end

----------------------------------------------------------------------------------------------------
-- Start  ------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local track, fxnum, Preset_Name = Get_LastTouch_FX()                   -- any function can be used
Save_VST_Preset(track, fxnum, Preset_Name)                             -- RUN
                
