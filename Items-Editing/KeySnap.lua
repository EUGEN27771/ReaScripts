--Get Root and Scale--
function Get_Root_and_Scale()
 ME=reaper.MIDIEditor_GetActive()--Active ME 
 --Get Active take from ME or first sel take(if ME closed)--
 if ME~=nil then 
    Take_ID = reaper.MIDIEditor_GetTake(ME)--Get Active Take(from ME)
    else Item_ID=reaper.GetSelectedMediaItem(0,0)--Get item
         if Item_ID then 
            Take_ID=reaper.GetActiveTake(Item_ID)--Get Active Take(from Item)
         end   
 end
 --Get Root, Scale from take--
 if Take_ID~=nil then 
    retval, Root, Scale = reaper.MIDI_GetScale(Take_ID, 0,0,0)
 end
return retval 
end

--Transpose Notes in Take--
function Transpose_Notes(Take_ID)
 FNG_Take=reaper.FNG_AllocMidiTake(Take_ID)--AllocTake
 Note_Count=reaper.FNG_CountMidiNotes(FNG_Take)--Count notes
 Sel_Start, Sel_End = reaper.GetSet_LoopTimeRange(0,0,0,0,0)--Get Time Selection
  --For each note in Take--
  for i=1,Note_Count,1 do
    Note=reaper.FNG_GetMidiNote(FNG_Take, i-1)--Get current Note
    Note_PPQ_Pos=reaper.FNG_GetMidiNoteIntProperty( Note,"POSITION")--Get PPQ Position
    Note_Time_Pos=reaper.MIDI_GetProjTimeFromPPQPos(Take_ID,Note_PPQ_Pos)--PPQPos to Time
     --If note start in Time Sel-- 
     if Note_Time_Pos>=Sel_Start and Note_Time_Pos<Sel_End then
        Note_Pitch=reaper.FNG_GetMidiNoteIntProperty( Note,"PITCH")--Get PITCH
        --Keysnap Current Note regard Scale Setting--
        for j=1,12,1 do
            Num_in_Scale = (Note_Pitch-Root)%12
            Key_Snap = Scale & (2^Num_in_Scale)
            if Key_Snap>0 then 
                     break
             elseif ( Scale & (2^(Num_in_Scale+j)) )>0 then
                     Note_Pitch=Note_Pitch+j
                     reaper.FNG_SetMidiNoteIntProperty(Note, "PITCH", Note_Pitch)
                     break
             elseif ( Scale & (2^(Num_in_Scale-j)) )>0 then
                     Note_Pitch=Note_Pitch-j
                     reaper.FNG_SetMidiNoteIntProperty(Note, "PITCH", Note_Pitch)
                     break
            end
        end
        -----------------------------------------------   
     end    
  end
 reaper.FNG_FreeMidiTake(FNG_Take)--FreeTake 
end 

function Main()
 if Get_Root_and_Scale() then
    Count_Sel_Items=reaper.CountSelectedMediaItems(0)
    for i=1,Count_Sel_Items,1 do
        Item_ID=reaper.GetSelectedMediaItem(0,i-1)--Get Current Item
        Take_ID=reaper.GetActiveTake(Item_ID)--Get Active Take
        --Transpose Notes in Current Take--
        if Take_ID and reaper.TakeIsMIDI(Take_ID) then 
           Transpose_Notes(Take_ID)
        end   
    end
 end 
end 

----------------------------------
Transpose = 1--(1 = Up, -1 = Down)
reaper.Undo_BeginBlock()
Main()--execute function
reaper.Undo_EndBlock("KeySnap_Transpose_Up", -1)
