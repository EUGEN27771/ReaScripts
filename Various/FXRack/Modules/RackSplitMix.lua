-- RackSplitMix(module)
-- @noindex



--[[Обязательно перепилить все по координатам!!! Все считать от высоты слота, ширины линейки микшера - сплиттера.
Сейчас не нужна такая муть.
По отрисовке объединены. Только init поправить толково и все, это правильный подход.--]]
--------------------------------------------------------------------------------
--*** RACK Mixer/Splitter functions  *******************************************
--------------------------------------------------------------------------------
local SplitMix = {}
local Mixer = {}
local Splitter = {}

------------------------------------------------------------
-- Init Mixer ----------------------------------------------
------------------------------------------------------------
function Mixer.Init(x,y,w,h, rows, gain_png, pan_png, power_png, phase_png, solo_png, summode_png)

  local mix = {x = x, y = y, w = w, h = h} -- Mixer coords

  -- Knobs ---------------------------------------
  local K = {} -- knobs tmp table
  ---- Vol  Knobs -----------
  local xx, yy, ww, hh = x + 4, y + 6, 28, 28 -- Vol Knobs
  for i = 1, rows do
    local key = "Vol"..i
    K[key] = KnobNew(xx, yy, ww, hh, gain_png, 0.5)
    yy = yy + 40
    ------
    K[key].param = (i-1)*5 + 1 -- Linked fx param idx(0-based)
  end

  ---- Pan Knobs -------------
  local xx, yy, ww, hh = x + 38, y + 6, 28, 28 -- Pan Knobs
  for i = 1, rows do
    local key = "Pan"..i
    K[key] = KnobNew(xx, yy, ww, hh, pan_png, 0.5)
    yy = yy + 40
    ------
    K[key].param = (i-1)*5 + 2 -- Linked fx param idx(0-based)
  end
  -------------
  mix.knobs = K -- Set Mixer Knobs

  -- Buttons -------------------------------------
  local B = {} -- btns tmp table
  ---- Power buttons ---------
  local xx, yy, ww, hh = x - 704, y + 11, 17, 18
  for i = 1, rows do
    local key = "Power"..i
    B[key] = TButtonNew(xx, yy, ww, hh, power_png, 0)
    yy = yy + 40
    ------
    B[key].param = (i-1)*5 -- Linked fx param idx(0-based)
  end

  ---- Phase buttons ---------
  local xx, yy, ww, hh = x + 38 + 36, y + 9, 22, 22
  for i = 1, rows do
    local key = "Phase"..i
    B[key] = TButtonNew(xx, yy, ww, hh, phase_png, 0)
    yy = yy + 40
    ------
    B[key].param = (i-1)*5 + 3 -- Linked fx param idx(0-based)
  end


  ---- Solo buttons ----------
  local xx, yy, ww, hh = x + 38 + 30*2, y + 9, 22, 22
  for i = 1, rows do
    local key = "Solo"..i
    B[key] = TButtonNew(xx, yy, ww, hh, solo_png, 0)
    yy = yy + 40
    ------
    B[key].param = (i-1)*5 + 4 -- Linked param idx(0-based)
  end

  ---- SumMode Button --------
  B.SumMode = TButtonNew(x+130, y - 25, 26, 17, summode_png, 0)
  B.SumMode.param = 40
  -------------
  mix.btns = B -- Set Buttons
  
  -- Labels -------------------------------------
  mix.lbls = {}
  mix.lbls.vol = {x = x + 12, y = y + rows * 40 + 9, lbl = "Vol"} -- Vol lbl
  mix.lbls.pan = {x = x + 45, y = y + rows * 40 + 9, lbl = "Pan"} -- Pan lbl
  
  return mix -- return mixer table

end

------------------------------------------------------------
-- Init Splitter -------------------------------------------
------------------------------------------------------------
function Splitter.Init(x, y, w, h, rows, gain_png)

  local split = {x = x, y = y, w = w, h = h} -- Splitter coords

  -- Knobs ---------------------------------------
  local K = {} -- knobs tmp table
  ---- Gain  Knobs -----------
  local xx, yy, ww, hh = x + 26, y + 6, 28, 28
  for i = 1, rows do
    local key = "Gain"..i
    K[key] = KnobNew(xx, yy, ww, hh, gain_png, 0.5)
    yy = yy + 40
    ------
    K[key].param = (i-1) -- Linked fx param idx(0-based)
  end
  -------------
  split.knobs = K -- Set Knobs
  
  -- Labels -------------------------------------
  split.lbls = {}
  split.lbls.gain = {x = x + 30, y = y + rows * 40 + 9, lbl = "Gain"} -- Gain lbl
  
  return split -- return splitter table

end

------------------------------------------------------------
-- Link Splitter/Mixer To JS -------------------------------
------------------------------------------------------------
-- Распиновка и линковка по одинаковой схеме
function SplitMix.SetPinmap(track, fx_idx) -- fx_idx 1-based!
  local fx = fx_idx - 1 -- fx index 0-based for reaper functions!
  local ret, inPins, outPins = reaper.TrackFX_GetIOSize(track, fx)
  for i = 1, inPins do reaper.TrackFX_SetPinMappings(track, fx, 0, i-1, 2^(i-1), 0) end
  for i = 1, outPins do reaper.TrackFX_SetPinMappings(track, fx, 1, i-1, 2^(i-1), 0) end
end

-----------------------
function SplitMix.LinkToJS(obj, track, fx_idx, fxname) -- fx_idx 1-based!
  obj.track = track                      -- target track
  obj.fx = {idx = fx_idx, name = fxname} -- target fx datas
  SplitMix.SetPinmap(track, fx_idx)    -- set valid pinmap
end

------------------------------------------------------------
-- Splitter/Mixer Last Touched Param functions -------------
------------------------------------------------------------
-- Init Mixer/Splitter LastTouch label ---------------------
function SplitMix.LastTouchInit()
  ---- LastTouch lbl coords --
  SplitMix.LastTouch = {x = 900, y = 6, w = 200, h = 18 }
end
-----------------------
function SplitMix.LastTouchDraw()
  if not (SplitMix.LastTouch and SplitMix.LastTouch.show) then return end
  local lbl = SplitMix.LastTouch.lbl
  local x, y = SplitMix.LastTouch.x, SplitMix.LastTouch.y
  local w, h = SplitMix.LastTouch.w, SplitMix.LastTouch.h
  gfx.x, gfx.y = x, y
  gfx.setfont(1, "Tahoma", 13)
  SetRGB(0xA7C5DB)
  gfx.drawstr(lbl, 4, x + w, y + h);

end
-----------------------
function SplitMix.LastTouchUpdate(track, key, fx, param)
  if not SplitMix.LastTouch then SplitMix.LastTouchInit() end
  ------------------
  local ret, parname = reaper.TrackFX_GetParamName(track, fx, param, "")
  local val = reaper.TrackFX_GetParam(track, fx, param)
  local ret, form_val = reaper.TrackFX_FormatParamValue(track, fx, param, val, "")
  local lbl = parname .. ":  " .. form_val
  if key:match("Vol") or key:match("Gain") then lbl = lbl .. " dB"
  elseif key:match("Pan") then lbl = lbl .. " %"
  end
  SplitMix.LastTouch.key = key
  SplitMix.LastTouch.lbl = lbl
  SplitMix.LastTouch.show = true
end

------------------------------------------------------------
-- Draw Splitter/Mixer -------------------------------------
------------------------------------------------------------
function SplitMix.Draw(obj)
  if not(obj.track and obj.fx and obj.fx.idx) then return end
  local track = obj.track
  local fx = obj.fx.idx - 1 -- fx = 0-based idx for reaper functions
  local mouse_pressed = (gfx.mouse_cap&1==1)
  
  if not reaper.TrackFX_GetEnabled(track, fx) then
    reaper.TrackFX_SetEnabled(track, fx, true) -- Set enabled always
  end

  -- Draw Buttons --
  if obj.btns then
    for key, btn in pairs(obj.btns) do
      TButtonDraw(btn) -- Draw Button
      if btn.isClicked then -- to fx from script
        reaper.TrackFX_SetParamNormalized(track, fx, btn.param, btn.normval)
        SplitMix.LastTouchUpdate(track, key, fx, btn.param)
      else -- from fx to sript
        btn.normval = reaper.TrackFX_GetParamNormalized(track, fx, btn.param)
      end
      --------------
      if btn.isChanged or btn.isMouseOver then 
        SplitMix.LastTouchUpdate(track, key, fx, btn.param)
      end
    end
  end

  -- Draw Knobs ----
  if obj.knobs then
    for key, knob in pairs(obj.knobs) do
      KnobDraw(knob) -- Draw Button
      if knob.isChanged then -- to fx from script
        reaper.TrackFX_SetParamNormalized(track, fx, knob.param, knob.normval)
      else -- from fx to sript
        knob.normval = reaper.TrackFX_GetParamNormalized(track, fx, knob.param)
      end
      --------------
      if knob.isChanged or knob.isMouseOver then 
        SplitMix.LastTouchUpdate(track, key, fx, knob.param)
      end
    end
  end
  
  -- labels --------
  if obj.lbls then
    for key, lbl in pairs(obj.lbls) do
      gfx.x = lbl.x; gfx.y = lbl.y
      gfx.setfont(1, "Tahoma", 13)
      SetRGB(0xA7C5DB)
      gfx.drawstr(lbl.lbl)
    end
  end
  
  -- Last touch ----
  SplitMix.LastTouchDraw()

end

--==========================================================
SplitMix.Splitter = Splitter
SplitMix.Mixer = Mixer
--==========================================================
return SplitMix
