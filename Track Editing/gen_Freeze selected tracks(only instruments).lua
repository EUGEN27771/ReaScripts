--[[
   * ReaScript Name:Freeze selected tracks(only instruments)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]


---------------------------------------------
-- Freeze -----------------------------------
---------------------------------------------
function Freeze(track)
    local fx_count = reaper.TrackFX_GetCount(track)
    if fx_count==0 then return end 
    ----------------------------------------- 
    local sel_first = reaper.NamedCommandLookup("_S&M_SELFX1")
    local sel_next  = reaper.NamedCommandLookup("_S&M_SELFXNEXT")
    local online_sel_fx  = reaper.NamedCommandLookup("_S&M_FXOFF_SETONSEL")
    local online_all_fx  = 40536
    local offline_all_fx = 40535
    local freeze_track   = 41223
    -----------------------------------------
    reaper.SetOnlyTrackSelected(track) -- Select current track only
    reaper.Main_OnCommand(offline_all_fx, 0)  -- offline all fxs
    reaper.Main_OnCommand(sel_first, 0)       -- select first fx

    -- Online instruments only --------------
    for fx=1, fx_count do 
        local retval, fx_name = reaper.TrackFX_GetFXName(track, fx-1, "")
        if fx_name:match("VSTi") or fx_name:match("AUi") then 
           reaper.Main_OnCommand(online_sel_fx, 0)
        end
        reaper.Main_OnCommand(sel_next, 0)    -- to next fx
    end
     
    -- Freeze, online all -------------------
    reaper.Main_OnCommand(freeze_track, 0)    -- Freeze
    reaper.Main_OnCommand(online_all_fx, 0)   -- online all fxs
end

---------------------------------------------
-- Start ------------------------------------
---------------------------------------------
local track_cnt = reaper.CountSelectedTracks(0)
local track_tb = {}
-- Get sel tracks ------
for i=1, track_cnt do  
    track_tb[i] = reaper.GetSelectedTrack(0, i-1)
end
-- Freeze tracks -------
reaper.Undo_BeginBlock()
for i=1, track_cnt do 
    Freeze(track_tb[i])
end
-- Restore sel state ---
for i=1, track_cnt do 
    reaper.SetTrackSelected(track_tb[i], true)
end
reaper.Undo_EndBlock("Freeze selected tracks(only instruments)", -1)
