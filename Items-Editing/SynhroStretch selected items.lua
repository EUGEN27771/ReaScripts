-------------------------------------------------------------------------------------
-- SynhroStretch Selected items(use shortcut for script and mouse cursor position) --
-------------------------------------------------------------------------------------

sel_items = reaper.CountSelectedMediaItems(0) -- count selected items
if sel_items>0 then 
    -- Save all selected items ids -- 
    item_id = {}
    for i=1, sel_items do item_id[i] = reaper.GetSelectedMediaItem(0, i-1) end   
        
    -- Get first item start and last item end --
    s_start = reaper.GetMediaItemInfo_Value(item_id[1], "D_POSITION")
    s_end   = reaper.GetMediaItemInfo_Value(item_id[sel_items], "D_POSITION")+ 
              reaper.GetMediaItemInfo_Value(item_id[sel_items], "D_LENGTH")
    
    mouse = reaper.BR_PositionAtMouseCursor(false) -- V1 -- mouse cursor variant 
    -- mouse =  reaper.GetCursorPosition()         -- V2 -- edit  cursor variant 

    if mouse~=-1 and mouse>s_start then K = (s_end-s_start)/(mouse-s_start) -- its coefficient
        -- change each selected item(starting from the last) --
        i=sel_items
        while i>0 do 
            Item = item_id[i]
            Take = reaper.GetActiveTake(Item)
            Pos  = reaper.GetMediaItemInfo_Value(Item, "D_POSITION") - s_start  -- Its position relative to the first sel item
            Len  = reaper.GetMediaItemInfo_Value(Item, "D_LENGTH")              -- Length
            reaper.SetMediaItemInfo_Value(Item,"D_POSITION", s_start + Pos/K)
            reaper.SetMediaItemInfo_Value(Item,"D_LENGTH",Len/K)
            Playrate = reaper.GetMediaItemTakeInfo_Value(Take, "D_PLAYRATE")
            reaper.SetMediaItemTakeInfo_Value(Take, "D_PLAYRATE", Playrate*K)
            i=i-1
        end
    end
end

-- For NoUndo(no trash in undo history) --
reaper.Undo_BeginBlock()
reaper.Undo_EndBlock("SynhroStretch", 2)
