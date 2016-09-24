--[[
   * ReaScript Name:Render selected item on new track, up to last VSTi
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]


---------------------------------------------
-- Render Item ------------------------------
---------------------------------------------
function Render_Item(item)
    -- Sel only first item -- 
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(item, true)
    -------------------------
    reaper.Main_OnCommand(40209, 0) -- Apply track/take FX to item
    ------
    local take = reaper.GetActiveTake(item)
    local take_guid  = reaper.BR_GetMediaItemTakeGUID(take)
    ------
    reaper.Main_OnCommand(40642, 0) -- Explode
    -------------------------
    local new_take = reaper.GetMediaItemTakeByGUID(0,take_guid)
    local new_item = reaper.GetMediaItemTake_Item(new_take)
    ------
  return new_item
end

---------------------------------------------
-- Move Item(and set parameters) ------------
---------------------------------------------
function Move_Item(track, item, new_item)
    -- Insert new track, move new item to new_track --
    local track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") -- Track number(1-based)
    local ret = reaper.InsertTrackAtIndex(track_num, 0)            -- insert new track
    local new_track = reaper.GetTrack(0, track_num)                -- get inserted track
    reaper.MoveMediaItemToTrack(new_item, new_track)               -- move new_item to new_track
    
    -----------------------------------------
    -- Set track and item parameters  -------
    -----------------------------------------
    reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)               -- Mute Original Item
    local ret,Name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false) -- Get orig track name
    reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", Name.."(render)", true) -- Set new track name
    reaper.SetMediaTrackInfo_Value(new_track, "B_MAINSEND", 0)     -- No send new track to master track 
    reaper.CreateTrackSend(new_track, track)                       -- Create Send from new_track to orig track
    --------
    reaper.SetTrackSendInfo_Value(new_track, 0, 0, "D_VOL", 1)     -- Set send vol 1.0 = +0dB (if def vol~=1.0)
    reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0)  -- Set new track normal folder depth
    ---------------------------------
    reaper.TrackList_AdjustWindows(0)                              -- update tracklist
end

---------------------------------------------
-- Main -------------------------------------
---------------------------------------------
function Main(item)
    local track = reaper.GetMediaItemTrack(item)
    local fx_count = reaper.TrackFX_GetCount(track) 
    local mute_pos = 0
    local state_tb = {}
    
    -----------------------------------------
    -- Find mute_pos and get FX states ------
    ----------------------------------------- 
    for fx=1, fx_count do 
        local retval, fx_name = reaper.TrackFX_GetFXName(track, fx-1, "")
        if fx_name:match("VSTi") or fx_name:match("AUi") then mute_pos = fx end
        state_tb[fx] = reaper.TrackFX_GetEnabled(track, fx-1) -- get state
    end
    
    -----------------------------------------
    -- Mute all FXs after mute_pos ----------
    -----------------------------------------   
    for fx=mute_pos+1, fx_count do 
        reaper.TrackFX_SetEnabled(track, fx-1, false) -- mute
    end
        
    -----------------------------------------
    -- Apply track/take FX(as new take) -----
    -----------------------------------------
    local new_item = Render_Item(item)
    Move_Item(track, item, new_item)
    
    -----------------------------------------
    -- Restore FX states --------------------
    -----------------------------------------
    for fx=mute_pos+1, fx_count do 
        reaper.TrackFX_SetEnabled(track, fx-1, state_tb[fx])
    end   
end

---------------------------------------------
-- Start ------------------------------------
---------------------------------------------
local item = reaper.GetSelectedMediaItem(0, 0)
if item then 
    reaper.Undo_BeginBlock()
    Main(item) 
    reaper.Undo_EndBlock("Render selected item on new track, up to last VSTi", -1)
end
