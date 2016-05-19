-----------------------------------------------------------------
-------- Delete Notes Overlaps(Poly) ----------------------------
-----------------------------------------------------------------

-- Get Take From Midi Editor or From Arrange --
function Get_MIDI_Take()
  ME = reaper.MIDIEditor_GetActive()                                         -- Active Midi Editor
    if ME then Take_ID = reaper.MIDIEditor_GetTake(ME);         ME_Flag = 1  -- Active Take from ME
     else Item_ID = reaper.GetSelectedMediaItem(0,0)
       if Item_ID then Take_ID = reaper.GetActiveTake(Item_ID); ME_Flag = 0  -- Active Take from Arrange                       
       end 
    end
  
  if not Take_ID or not reaper.TakeIsMIDI(Take_ID) then return false end
  return Take_ID
end

-- Get note properties --
function Get_Note_Prop(idx)
  -- Get Cur_Note Parameters --
  Note     = reaper.FNG_GetMidiNote(FNG_Take, idx)               -- Get current Note
  Note_Sel = reaper.FNG_GetMidiNoteIntProperty( Note,"SELECTED") -- Get Sel State 
  Note_Pos = reaper.FNG_GetMidiNoteIntProperty( Note,"POSITION") -- Get Position PPQ
  Note_Len = reaper.FNG_GetMidiNoteIntProperty( Note,"LENGTH")   -- Get LENGTH PPQ
  Note_End = Note_Pos+ Note_Len                                  -- Calc End PPQ
  return  Note, Note_Sel, Note_Pos ,Note_End
end

-- Find and Delete Overlaps --
function Del_Overlaps()
 FNG_Take = reaper.FNG_AllocMidiTake(Take_ID)      -- AllocTake
 Count_Notes = reaper.FNG_CountMidiNotes(FNG_Take) -- Count Notes
  for i=1,Count_Notes-1,1 do
      Cur_Note, Cur_Note_Sel, Cur_Note_Pos, Cur_Note_End = Get_Note_Prop(i-1) -- func Get_Note_Prop
      -- Find the first note corresponding to the conditions --
      if (ME_Flag==0 or Cur_Note_Sel==1) 
        then Del_Overlap=0; j=i;
             while j<Count_Notes and Del_Overlap<1 do
                   Next_Note, Next_Note_Sel, Next_Note_Pos, Next_Note_End = Get_Note_Prop(j) -- Get_Note_Prop
                   -- Compare Notes Data --
                   if Next_Note_Pos-Cur_Note_Pos>Min_Diff 
                      and Cur_Note_End>Next_Note_Pos 
                      and (InCh_Flag>0 or Next_Note_End>Cur_Note_End)
                      then New_Lenght=Next_Note_Pos-Cur_Note_Pos 
                           reaper.FNG_SetMidiNoteIntProperty(Cur_Note, "LENGTH", New_Lenght) -- Set New Lenght
                           Del_Overlap=1
                   end     
             j=j+1
             end
      end
  end
 reaper.FNG_FreeMidiTake(FNG_Take) -- FreeTake  
end

---------------------------------------------------
--- You can set some additional parameters --------
Min_Diff = 960/4   -- Set Min Differnce(in PPQ)
InCh_Flag = 0      -- Save Overlaps Inside of a Chord var
-- InCh_Flag = 1   -- Del  Overlaps Inside of a Chord var

--- Start ---
reaper.Undo_BeginBlock()
if Get_MIDI_Take() then Del_Overlaps() end
reaper.Undo_EndBlock("~Delete_Overlaps(Poly)~", -1)
reaper.UpdateArrange()

