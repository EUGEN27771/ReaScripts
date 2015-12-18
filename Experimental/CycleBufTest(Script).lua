function Set_JS_Parameters(Part,Pos)
  reaper.SetEditCurPos(Pos, 0, 0)--Set Cursor for Insert Audio
  reaper.TrackFX_SetParam(JS_Track_ID, FX_index, 1, Sel_Track_Num-1)--Set Track_Number in JS
  reaper.TrackFX_SetParam(JS_Track_ID, FX_index, 0, Part)--Set Insert Value(-1 or 1)
  reaper.TrackFX_Show(JS_Track_ID, FX_index, 1)--Open JS FX(Audio will be inserted only when JS opened)
  Close_JS();--Close JS after Inserting
end

function Close_JS()
  Insert=reaper.TrackFX_GetParam(JS_Track_ID, FX_index, 0);--Get Insert State(0=OK)
  if Insert~=0
    then reaper.defer(Close_JS) 
       elseif i<1 
          then  i=i+1
                reaper.TrackFX_Show(JS_Track_ID, FX_index, 0)
                Set_JS_Parameters(1, Ins_Pos2)
    else reaper.TrackFX_Show(JS_Track_ID, FX_index, 0)
         reaper.TrackFX_SetParam(JS_Track_ID, FX_index, 2, 0)--Set Stop=0 in JS
         reaper.SetEditCurPos(Cur_Pos, 0, 0)--Restore Cursor Pos
         Rename_Items()
         reaper.UpdateArrange()
  end 
end

function Rename_Items()
  Count_Sel_Items = reaper.CountSelectedMediaItems(0)
  for i = 1, Count_Sel_Items, 1 do 
  Item_ID=reaper.GetSelectedMediaItem(0, i-1)
  Take_ID=reaper.GetMediaItemTake(Item_ID, 0)
  reaper.GetSetMediaItemTakeInfo_String(Take_ID, "P_NAME", Sel_Track_Name..i, 1)
  end
end


i=0
Ins_Val=1
FX_index=0
JS_Track_ID=reaper.GetTrack(0, 0)--Get first track

reaper.SelectAllMediaItems(0, 0)--Unsel All Items in Proj
Sel_Track_ID=reaper.GetSelectedTrack(0, 0)--Get first selected track
Sel_Track_Num=reaper.GetMediaTrackInfo_Value(Sel_Track_ID, "IP_TRACKNUMBER")--Get track num
retval,Sel_Track_Name=reaper.GetSetMediaTrackInfo_String(Sel_Track_ID, "P_NAME" , "", 0)--name

reaper.TrackFX_SetParam(JS_Track_ID, FX_index, 2, 1)--Firstly,Set Stop=1 in JS
Ins_Pos1=reaper.TrackFX_GetParam(JS_Track_ID, FX_index, 3)--Get Ins_pos1 from JS
Ins_Pos2=reaper.TrackFX_GetParam(JS_Track_ID, FX_index, 4)--Get Ins_pos2 from JS
Cur_Pos=reaper.GetCursorPosition()--Save Cursor Pos

Set_JS_Parameters(-1, Ins_Pos1)--Call func
