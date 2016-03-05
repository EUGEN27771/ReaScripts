--Mousewhell only!--
--get mousewhell value--
msg = function(m) reaper.ShowConsoleMsg(tostring(m).."\n") end
function main()
reaper.PreventUIRefresh(1)
  ----------    
  is_new_val,f_name,secID,cmdID,mode,reso,val = reaper.get_action_context()
  if     val>0  then K=1.1
  elseif val<0  then K=0.9
  end
   if val~=0 then
      --for each track and each track envelopes--
      for i=1,reaper.CountTracks(0) do
          tr = reaper.GetTrack(0,i-1)
          tr_h = reaper.GetMediaTrackInfo_Value(tr,  "I_HEIGHTOVERRIDE")--Get custom Height
                --if custom Height == 0 calculate Height(regard Envelopes)--
                if tr_h == 0 then
                    tr_h = reaper.GetMediaTrackInfo_Value(tr, 'I_WNDH')
                    Env_Count = reaper.CountTrackEnvelopes(tr)
                    fix_h = 0
                    for i=1,Env_Count do
                        Env = reaper.GetTrackEnvelope(tr ,i-1)
                        BR_Env = reaper.BR_EnvAlloc(Env,0)
                        active,visible,armed, inLane,laneHeight, defShape, minVal,maxVal, centerVal, type, faderScaling = reaper.BR_EnvGetProperties(BR_Env)
                        if visible and inLane then
                            if laneHeight>0 then tr_h=tr_h-laneHeight
                            elseif laneHeight==0 then fix_h=fix_h+1
                            end
                        end
                        reaper.BR_EnvFree(BR_Env, true) 
                    end
                    ---------------------------------------
                    tr_h = tr_h/(fix_h+1)--calculated track Height
                end  
          new_h = math.ceil(tr_h*K)--New track Height   
          --Set Track Height(new_h)--
          reaper.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", new_h)
      end 
   end 
  ---------- 
reaper.Main_OnCommand(40913,0)   
reaper.TrackList_AdjustWindows(0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end 
   
reaper.defer(main)
