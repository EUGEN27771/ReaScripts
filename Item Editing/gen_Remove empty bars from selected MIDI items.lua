--[[
   * ReaScript Name:Remove empty bars from selected MIDI items
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]


function msg(m) reaper.ShowConsoleMsg(tostring(m.."\n")) end
----------------------------
----------------------------
---------
function range_start_end(prev_range_end)
    local range_start = prev_range_end
    local range_start_QN = reaper.TimeMap_timeToQN(range_start)
    local ret, Bar_Start_QN, Bar_End_QN = reaper.TimeMap_QNToMeasures(0, range_start_QN)
    local range_end   = reaper.TimeMap_QNToTime(Bar_End_QN)
    return range_start, range_end
end
---------
function Add_range_to_Split(range_start,range_end,note_start,note_end)
    if range_start<note_start  and range_end>note_start then return end --    | --|-
    if range_start<note_end    and range_end>note_end   then return end --   -|-- |
    if range_start<=note_start and range_end>=note_end  then return end --    | - |
    if range_start>=note_start and range_end<=note_end  then return end --   -|---|-
  return true
end
---------
function Remove_Empty_Bars(Item,Take)
    local Split_Points = {}
    -- if LOOPSRC --
    if reaper.GetMediaItemInfo_Value(Item, "B_LOOPSRC") then reaper.Main_OnCommand(40362,0) 
       Item = reaper.GetSelectedMediaItem(0,0)
       Take = reaper.GetActiveTake(Item)
    end
    ----------------
    local Item_Start = reaper.GetMediaItemInfo_Value(Item, "D_POSITION")
    local Item_End   = Item_Start + reaper.GetMediaItemInfo_Value(Item, "D_LENGTH")
    local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(Take)
    ----------------
    local range_start, range_end = range_start_end(Item_Start)
    local spl = 1   
    ----------------------------
    while range_start<Item_End do
      local Split  
        -- Find notes in current range -----
        for i=1,notecnt do 
            local ret, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(Take, i-1)
            local note_start = reaper.MIDI_GetProjTimeFromPPQPos(Take, startppqpos)
            local note_end   = reaper.MIDI_GetProjTimeFromPPQPos(Take, endppqpos)      
              -------
              Split = Add_range_to_Split(range_start,range_end,note_start,note_end) 
              if not Split then  break end   
        end
      
      -- Add range to Split_Points table if notes not found --
      if Split then Split_Points[spl] = {range_start,range_end}; spl = spl+1 end
      -- To next range --
      range_start, range_end = range_start_end(range_end)
    end
    ----------------------------
    -- split empty -------------
    for spl=1,#Split_Points, 1 do 
        reaper.GetSet_LoopTimeRange(true, false, Split_Points[spl][1], Split_Points[spl][2], false)
        reaper.Main_OnCommand(40312, 0)
    end    

end

-------------------------------------------
---  Start  -------------------------------
-------------------------------------------
local Sel_Items = {} 
local item_cnt = reaper.CountSelectedMediaItems(0)
-- sel items to table ---------------------
for i=1, item_cnt do Sel_Items[i] = reaper.GetSelectedMediaItem(0, i-1) end
-----
----------------------------
reaper.PreventUIRefresh(111)
reaper.Undo_BeginBlock()
  local usel1, usel2  = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    --------------------
    for i=1, item_cnt do
      reaper.Main_OnCommand(40289,0)
      local Item = Sel_Items[i]
      local Take = reaper.GetActiveTake(Item)
         if reaper.TakeIsMIDI(Take) then 
            reaper.SetMediaItemSelected(Item, true)
            Remove_Empty_Bars(Item,Take)
         end
    end
    --------------------
  reaper.GetSet_LoopTimeRange(true, false, usel1, usel2, false)
reaper.Undo_EndBlock("Remove empty bars from selected MIDI items", -1)    
reaper.PreventUIRefresh(-111)
-----
