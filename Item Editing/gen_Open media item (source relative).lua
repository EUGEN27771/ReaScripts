--[[
   * ReaScript Name: Open media item (source relative)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  
  ---------------------------------------------------------------------
-- Open Item(Var Actions depending of item source) ------------------
---------------------------------------------------------------------
--[[
  INFO:
    Open the Action list, right-click on the Action and Copy Sel Action ID
    Insert the Action ID in the "Action ID" column
      For text ID used quotes!
      For no-action used zero!
  ]]--

---------------------------------
---------------------------------
-- SourceType   =    Action ID -- 
---------------------------------
  -- Midi Source ---------
  MIDI          =    40153
  -- Audio Source --------
  WAVE          =    "_SWS_TOGZOOMIONLY"
  REX           =    "_SWS_TOGZOOMIONLY"
  FLAC          =    "_SWS_TOGZOOMIONLY"
  MP3           =    "_SWS_TOGZOOMIONLY"
  VORBIS        =    "_SWS_TOGZOOMIONLY"
  OPUS          =    "_SWS_TOGZOOMIONLY"
  -- Video Source --------
  VIDEO         =    50125
  -- Special Source ------
  RPP_PROJECT   =    41816
  EMPTY         =    40850
  CLICK         =    40011
  LTC           =    40011

-- if no sel item or no-action(Action ID=0) --
  NoSelItem     =    40113
---------------------------------------------------------------------
---------------------------------------------------------------------
function Get_Source_Type(Item_ID)
    if Item_ID then
      Take_ID = reaper.GetActiveTake(Item_ID)-- Get Active Take(from Item)
      if Take_ID then
         PCM_source = reaper.GetMediaItemTake_Source(Take_ID)
         S_Type = reaper.GetMediaSourceType(PCM_source,"")
         if S_Type == "SECTION" then
            PCM_source = reaper.GetMediaSourceParent(PCM_source)
            S_Type = reaper.GetMediaSourceType(PCM_source,"")
         end
      else S_Type = "EMPTY" 
      end
    end    
  return S_Type
end

----------------------
function Set_ID(S_Type)
    -- Midi Source --------- 
    if     S_Type == "MIDI"          then ID = MIDI
    -- Audio Source -------- 
    elseif S_Type == "WAVE"          then ID = WAVE
    elseif S_Type == "REX"           then ID = REX
    elseif S_Type == "FLAC"          then ID = FLAC
    elseif S_Type == "MP3"           then ID = MP3
    elseif S_Type == "VORBIS"        then ID = VORBIS
    elseif S_Type == "OPUS"          then ID = OPUS
    -- Video Source -------- 
    elseif S_Type == "VIDEO"         then ID = VIDEO
    -- Special Source ------
    elseif S_Type == "RPP_PROJECT"   then ID = RPP_PROJECT
    elseif S_Type == "EMPTY"         then ID = EMPTY
    elseif S_Type == "CLICK"         then ID = CLICK
    elseif S_Type == "LTC"           then ID = LTC
    end
    
    -- if non-native Action ID --
    if ID and type(ID) == "string" then 
      ID = reaper.NamedCommandLookup(ID)
    end
    -- if Action no assigned ----
    if not S_Type or not ID or ID == 0 then 
      ID = NoSelItem -- Action for others
    end 
  
  return ID
end

----------------------
function Run_Action()
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommandEx(ID,0, 0)
  reaper.Undo_EndBlock("Open media item (source relative)", -1)
end

----------------------------------------
----------------------------------------
Item_ID = reaper.GetSelectedMediaItem(0, 0)
Get_Source_Type(Item_ID)
Set_ID(S_Type)
reaper.defer(Run_Action)
