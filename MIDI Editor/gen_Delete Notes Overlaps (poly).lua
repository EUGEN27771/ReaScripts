--[[
   * ReaScript Name:Delete Notes Overlaps (poly)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]

-----------------------------------------------------------------
-------- Delete Notes Overlaps(Poly) ----------------------------
-----------------------------------------------------------------

-- Get Take From Midi Editor or From Arrange --
function Get_MIDI_Take()
  local ME, Item_ID, Take_ID
    ME = reaper.MIDIEditor_GetActive()                                       -- Active Midi Editor
    if ME then Take_ID = reaper.MIDIEditor_GetTake(ME);         ME_Flag = 1  -- Active Take from ME
     else Item_ID = reaper.GetSelectedMediaItem(0,0)
       if Item_ID then Take_ID = reaper.GetActiveTake(Item_ID); ME_Flag = 0  -- Active Take from Arrange                       
       end 
    end
  --------------
  if not Take_ID or not reaper.TakeIsMIDI(Take_ID) then return false end
  return Take_ID, ME_Flag
end

-- Get note properties --
function Get_Note_Prop(FNG_Take,idx)
  local Note, Note_Sel, Note_Pos, Note_Len, Note_End
  -- Get Cur_Note Parameters --
  Note     = reaper.FNG_GetMidiNote(FNG_Take, idx)               -- Get current Note
  Note_Sel = reaper.FNG_GetMidiNoteIntProperty( Note,"SELECTED") -- Get Sel State 
  Note_Pos = reaper.FNG_GetMidiNoteIntProperty( Note,"POSITION") -- Get Position PPQ
  Note_Len = reaper.FNG_GetMidiNoteIntProperty( Note,"LENGTH")   -- Get LENGTH PPQ
  Note_End = Note_Pos+ Note_Len                                  -- Calc End PPQ
  return  Note, Note_Sel, Note_Pos ,Note_End
end

-- Find and Delete Overlaps --
function Del_Overlaps(Take_ID, ME_Flag)
  local FNG_Take    = reaper.FNG_AllocMidiTake(Take_ID)   -- AllocTake
  local Count_Notes = reaper.FNG_CountMidiNotes(FNG_Take) -- Count Notes
  
  for i=1, Count_Notes-1 do
     local Cur_Note, Cur_Note_Sel, Cur_Note_Pos, Cur_Note_End = Get_Note_Prop(FNG_Take,i-1) -- func Get_Note_Prop
     -- Find the first note corresponding to the conditions --
     if ME_Flag==0 or Cur_Note_Sel==1 then 
        local Del_Overlap = 0
        local j = i
        while j < Count_Notes and Del_Overlap < 1 do
            local Next_Note, Next_Note_Sel, Next_Note_Pos, Next_Note_End = Get_Note_Prop(FNG_Take,j) -- Get_Note_Prop
            -- Compare Notes Data --
            if Next_Note_Pos-Cur_Note_Pos > Min_Diff and 
                        Cur_Note_End > Next_Note_Pos and (InCh_Flag > 0 or Next_Note_End > Cur_Note_End) then 
                        -- then set new Lenght --
                        local New_Lenght = Next_Note_Pos-Cur_Note_Pos 
                        reaper.FNG_SetMidiNoteIntProperty(Cur_Note, "LENGTH", New_Lenght) -- Set New Lenght
                        Del_Overlap = 1
            end     
          j=j+1
        end
     end
  end
  reaper.FNG_FreeMidiTake(FNG_Take) -- FreeTake  
end

---------------------------------------------------
--- You can set some additional parameters --------
---------------------------------------------------
Min_Diff = 960/4   -- Set Min Differnce(in PPQ)
InCh_Flag = 0      -- Save Overlaps Inside of a Chord var
-- InCh_Flag = 1   -- Del  Overlaps Inside of a Chord var

--- Start ---
reaper.Undo_BeginBlock()
local Take_ID, ME_Flag = Get_MIDI_Take()
if Take_ID then Del_Overlaps(Take_ID, ME_Flag) end
reaper.Undo_EndBlock("Delete Notes Overlaps (poly)", -1)
reaper.UpdateArrange()

