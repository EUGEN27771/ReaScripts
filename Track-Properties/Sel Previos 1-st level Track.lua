-------------------------------------
-- Select previos 1-st level track --
-------------------------------------
function sel_prev_track(tr_id)
  local sel_tr_num, i, tr_depth
  sel_tr_num = reaper.GetMediaTrackInfo_Value(tr_id, "IP_TRACKNUMBER")
  reaper.SetMediaTrackInfo_Value(tr_id, "I_SELECTED", 0) -- unselect
  i = sel_tr_num-2
  while i>=0 do
    tr_id    = reaper.GetTrack(0,i)
    tr_depth = reaper.GetTrackDepth(tr_id)
      if tr_depth==0 then reaper.SetMediaTrackInfo_Value(tr_id, "I_SELECTED", 1)
         break
      end
  i=i-1
  end
end

----------------------------------
tr_id = reaper.GetSelectedTrack(0,0)
if tr_id then sel_prev_track(tr_id) end
 
