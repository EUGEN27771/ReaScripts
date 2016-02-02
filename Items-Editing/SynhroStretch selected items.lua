---SynhroStretch selected items(test1)-----
Sel_Items = reaper.CountSelectedMediaItems(0)
if Sel_Items>0 then
    S_start = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, 0), "D_POSITION")
    S_end   = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, Sel_Items-1), "D_POSITION")+ 
              reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, Sel_Items-1), "D_LENGTH")
    
    mouse = reaper.BR_PositionAtMouseCursor(false)
    if  mouse~=-1 then K=(mouse-S_start)/(S_end-S_start) else K=1 end
end

for i=1,Sel_Items do
    Item = reaper.GetSelectedMediaItem(0, i-1)
    Take = reaper.GetActiveTake(Item)
    --------------------------------
    Position = reaper.GetMediaItemInfo_Value(Item, "D_POSITION")
    Length = reaper.GetMediaItemInfo_Value(Item, "D_LENGTH")
    if i>1 then reaper.SetMediaItemInfo_Value(Item,"D_POSITION", Position*K) end
    reaper.SetMediaItemInfo_Value(Item,"D_LENGTH",Length*K)
    Playrate = reaper.GetMediaItemTakeInfo_Value(Take, "D_PLAYRATE")
    reaper.SetMediaItemTakeInfo_Value(Take, "D_PLAYRATE", Playrate/K)
end
