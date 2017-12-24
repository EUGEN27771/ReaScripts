-- SimpleControls(module)
-- @noindex

------------------------------------------------------------
function msg(m) reaper.ShowConsoleMsg("\n" .. m) end

------------------------------------------------------------
-- Images Functions ----------------------------------------
------------------------------------------------------------
local Images = {}
--------------------
function Images.FindFirstEmptySlot()
  local img
  for i = 0, 1023 do
    local w, h = gfx.getimgdim(i)
    if w == 0 then img = i break end
  end 
  return img
end
--------------------
function Images.LoadToFirstEmptySlot(filename)
  if not filename then return end
  local img = Images.FindFirstEmptySlot()
  img = gfx.loadimg(img, filename)
  if img >= 0 then Images[filename] = img
    return img
  end 
end
--------------------
function Images.FindLoadedOrLoad(filename)
  if Images[filename] then return Images[filename]
  else return Images.LoadToFirstEmptySlot(filename) 
  end
end

------------------------------------------------------------
-- Load, Set, Draw Control Image ---------------------------
------------------------------------------------------------
--[[ 
ШАБЛОН ДЛЯ ИМЕНОВАНИЯ imagename_(frmw)x(frmh)x(nfrms) - ЭТО ВАЖНО!
Можно добавить дополнительные варианты, для удобства:
Если нет результата по первому - imagename_(frmw)x(frmh) - считать nfrms через gfx.getimgdim().
Если нет результата по первому и второму - считать все через gfx.getimgdim() ориентируясь на ширину.
--]] 
function ControlSetImage(control, img_filename)
  local idx = Images.FindLoadedOrLoad(img_filename)
  ------------------
  if idx then
    local frmw, frmh, nfrms = img_filename:match(".-_(%d+)x(%d+)x(%d+)")
    if frmw and frmh and nfrms then
      control.img = { idx = idx,               -- image idx, slot 0..1024-1 specified by image
                      frmw  = tonumber(frmw),  -- image frame width
                      frmh  = tonumber(frmh),  -- image frame height
                      nfrms = tonumber(nfrms)} -- number of frames
    end
  end
end

------------------------------
function ControlDrawImage(control)
  local x,y,w,h = control.x, control.y, control.w, control.h 
  local normval = control.normval
  local img = control.img 
  local curfrm = math.floor((img.nfrms-1) * normval) -- current frame 
  gfx.blit(img.idx, 1, 0, 0, curfrm * img.frmh, img.frmw, img.frmh, x,y,w,h);
end

------------------------------------------------------------
-- Simple Button -------------------------------------------
------------------------------------------------------------
function TButtonNew(x,y,w,h, img_filename, normval)
  local btn = {x = x, y = y, w = w, h = h, normval = normval}
  ControlSetImage(btn, img_filename)
  return btn
end

------------------------------
function TButtonDraw(btn)
  local x,y,w,h = btn.x, btn.y, btn.w, btn.h
  ------------------
  btn.isMouseOver, btn.isClicked = false, false
  if mouseIN(x,y,w,h) and gfx.mouse_cap&1==0 then btn.isMouseOver = true end
  ------------------
  if mouseDown(x,y,w,h) then
    if btn.normval > 0 then btn.normval = 0 else btn.normval = 1 end
    btn.isClicked = true 
  end
  ------------------
  if btn.isMouseOver then gfx.a = 1 else gfx.a = 0.7 end
  if btn.img then 
    ControlDrawImage(btn)
  else 
    gfx.rect(x,y,w,h, 0)
    gfx.x, gfx.y = x, y; gfx.a = 1
    gfx.drawstr("?", 231, x+w, y+h) -- либо рисовать нативно
  end

end

------------------------------------------------------------
-- Simple Knob ---------------------------------------------
------------------------------------------------------------
function KnobNew(x, y, w, h, img_filename, normval)
  local knob = {x = x, y = y, w = w, h = h, normval = normval, defval = normval}
  ControlSetImage(knob, img_filename)
  return knob
end

------------------------------
function KnobDraw(knob)
  local x,y,w,h = knob.x, knob.y, knob.w, knob.h
  knob.isMouseOver, knob.isChanged, knob.isReleased = false, false, false -- reset to default
  ------------------
  if mouseIN(x,y,w,h) and gfx.mouse_cap&1==0 then knob.isMouseOver = true end 
  ------------------
  if mouseDown(x,y,w,h) then knob.isCaptured = true end -- set cap state
  ------------------  
  if knob.isCaptured and mouse_up then 
    knob.isCaptured = nil -- reset cap state
    knob.isReleased = true -- knob has been released
  end 
  --------
  if knob.isCaptured then
    if mouse_move then  -- change knob value via mouse 
      local K = 600     -- Normal drag(no Ctrl)
      if mouse_Ctrl then K = 2000 end -- K = 1000 Precise drag(if Ctrl pressed)
      knob.normval = knob.normval + (mouse_last_y - gfx.mouse_y) / K 
      knob.normval = minmax(knob.normval, 0, 1)
      knob.isChanged = true -- knob changed - state! 
    end
  end
  --------
  if mouseRDown(x,y,w,h) then 
    knob.normval = knob.defval
    knob.isChanged = true 
  end
  ------------------
  if knob.isCaptured or knob.isMouseOver then gfx.a = 1 else gfx.a = 0.7 end
  if knob.img then 
    ControlDrawImage(knob)
  else 
    gfx.rect(x,y,w,h, 0)
    gfx.x, gfx.y = x, y
    gfx.drawstr("?", 231, x+w, y+h) -- либо рисовать нативно
  end

end
