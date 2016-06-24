--[[
   * ReaScript Name: WAVE Generator
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.02
  ]]

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.norm_val = norm_val
    elm.norm_val2 = norm_val2
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end
--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) -- upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = math.max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = math.min(22,self.fnt_sz)
  end       
end
------------------------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseUp() -- its actual for sliders and knobs only!
  return gfx.mouse_cap&1==0 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)         
end
------------------------
function Element:mouseR_Down()
  return gfx.mouse_cap&2==2 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseM_Down()
  return gfx.mouse_cap&64==64 and self:pointIN(mouse_ox,mouse_oy)
end
------------------------
function Element:draw_frame()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, false)            -- frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true) -- frame2         
end
----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local Button = {}
local Slider = {}
local Frame = {}
local CheckBox = {}
  extended(Button,     Element)
  extended(Slider,     Element)
  extended(Frame,      Element)
  extended(CheckBox,   Element)
--- Create Slider Child Classes(V_Slider,H_Slider) ----
local H_Slider = {}
local V_Slider = {}
  extended(H_Slider, Slider)
  extended(V_Slider, Slider)

--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
end
--------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl)
end
------------------------
function Button:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.1 end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(0.7, 0.9, 0.4, 1)   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   CheckBox Class Methods   -------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw checkbox body
end
--------
function CheckBox:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+5; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.1
             if self:set_norm_val_m_wheel() then 
                if self.onMove then self.onMove() end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(0.7, 0.9, 0.4, 1)   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider:set_norm_val_m_wheel()
    local Step = 0.001 -- Set step
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = math.min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = math.max(self.norm_val-Step, 0) end
    return true
end
--------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,100 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
--------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw H_Slider body
end
--------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw H_Slider label
end
--------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.form_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw H_Slider Value
end
--------
function H_Slider:set_form_val()
    self.form_val = self.form_val or self.norm_val
end
------------------------
function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.1
             if self:set_norm_val_m_wheel() then 
                if self.onMove then self.onMove() end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          -- in elm L_up(released and was previously pressed) --
          -- if self:mouseClick() and self.onClick then self.onClick() end
          if self:mouseR_Down() and self.onR_Down then self.onR_Down() end
    
    ----------------------------
    self:set_form_val() -- formatted value
    ----------------------------
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(0.7, 0.9, 0.4, 1)   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   if self:mouseIN() then a=a+0.1 end
   gfx.set(r,g,b,a)   -- set frame color
   self:draw_frame()  -- draw frame
end


----------------------------------------------------------------------------------------------------
---   Controls   -----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Gen_btn = Button:new(20,110,220,30, 0.6,0.4,0.4,0.2, "Generate","Arial",15, 0 )
Gen_btn.onClick = 
function()
    local FilePath, Type, Freq, Gain, duration = GetSet_Values()
    local buf = Gen_Wave(Type, Freq, Gain, duration)
    Create_Wave_File(FilePath, buf, audioFormat, nchans, srate, bitspersample)
    reaper.InsertMedia(FilePath, 0) --  mode = 0
end
-----
local Button_TB = {Gen_btn}

------------------------------
------------------------------
    -- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table --
local Type_cbx = CheckBox:new(20,20,220,20,  0.5,0.5,0.5,0.2, "","Arial",15,  1,
                              {"Sine", "Triangle", "Saw", "WhiteNoise", "PinkNoise"} )
---------
local CheckBox_TB = {Type_cbx}

------------------------------
------------------------------
local Frq_sldr = H_Slider:new(20,50,220,20, 0.5,0.6,0.4,0.2, "Frequency","Arial",15, 0.148324 )
---------
function Frq_sldr:set_form_val()
    local step = 0.01 -- round step
    self.form_val = math.floor((self.norm_val^2*20000)/step + 0.5)*step
end
---------
Frq_sldr.onR_Down = 
function()
    local ret, UI_val = reaper.GetUserInputs("Freq", 1, "Set Frequency", tostring(Frq_sldr.form_val))
    UI_val = math.abs(tonumber(UI_val) or Frq_sldr.form_val)
    Frq_sldr.norm_val = (UI_val/20000)^0.5 or 0
    Frq_sldr.norm_val = math.min(Frq_sldr.norm_val,1)
end    
---------------
---------------
local Gain_sldr = H_Slider:new(20,80,220,20, 0.5,0.6,0.4,0.2, "Gain","Arial",15, 0.5 )
---------
function Gain_sldr:set_form_val()
    if self.norm_val<0.001 then self.norm_val=0.001 end
    local step = 0.01 -- round step
    self.form_val = 20*math.log(self.norm_val, 10)
    self.form_val = math.floor(self.form_val/step + 0.5)*step
end
---------
Gain_sldr.onR_Down = 
function()
    local ret, UI_val = reaper.GetUserInputs("Gain", 1, "Set Gain", tostring(Gain_sldr.form_val))
    UI_val = tonumber(UI_val) or Gain_sldr.form_val
    Gain_sldr.norm_val = 10^(UI_val/20)
    if Gain_sldr.norm_val>1 then Gain_sldr.norm_val=1 elseif Gain_sldr.norm_val<0.001 then 
       Gain_sldr.norm_val=0.001
    end
end
---------
local Slider_TB = {Frq_sldr, Gain_sldr}
------------------------------
------------------------------
local W_Frame = Frame:new(10,10,240,140,  0,0.5,0,0.4 )
local Frame_TB = {W_Frame}

----------------------------------------------------------------------------------------------------
---   Main DRAW function   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function DRAW()
    for key,btn     in pairs(Button_TB)   do btn:draw()    end
    for key,ch_box  in pairs(CheckBox_TB) do ch_box:draw() end 
    for key,sldr    in pairs(Slider_TB)   do sldr:draw()   end
    for key,frame   in pairs(Frame_TB)    do frame:draw()  end
    --------------------------------------------------
    local Type = Type_cbx.norm_val2[Type_cbx.norm_val]
    if Type=="WhiteNoise" or Type=="PinkNoise" then Gen_btn.lbl = "Generate ".. Type
    else Gen_btn.lbl = "Generate ".. Type.." - "..Frq_sldr.form_val
    end
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values --
    local R,G,B = 20,20,20               -- 0..255 form
    local Wnd_bgd = R + G*256 + B*65536  -- red+green*256+blue*65536  
    local Wnd_Title = "Wave Generator"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,320
    Wnd_W,Wnd_H = 260,160 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()
    -- zoom level --
    Z_w, Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if Z_w<0.7 then Z_w = 0.7 elseif Z_w>1.7 then Z_w = 1.7 end
    if Z_h<0.7 then Z_h = 0.7 elseif Z_h>1.7 then Z_h = 1.7 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4
    Shift = gfx.mouse_cap&8==8
    Alt   = gfx.mouse_cap&16==16 -- Shift state
    -------------------------
    -- DRAW,MAIN functions --
      DRAW() -- Main() 
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset gfx.mouse_wheel 
    char = gfx.getchar()
    if char==32 then reaper.Main_OnCommand(40044, 0) end -- play 
    if char~=-1 then reaper.defer(mainloop) end          -- defer
    -----------  
    gfx.update()
    -----------
end

------------------------------------------------------------------------------------------------------------------------
--  Script main functions ----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  Create_Wave_File -----------------------------------------------------------
--------------------------------------------------------------------------------
function Create_Wave_File(FilePath, buf, audioFormat, nchans, srate, bitspersample)
  if not (FilePath and buf and audioFormat and nchans and srate and bitspersample) then return reaper.MB("No data!","Info",0) end
  ----------------------------------------------------------
  local Pfmt --------------- Pack format -------------------
  if     audioFormat==3 and bitspersample==32 then Pfmt = "f"        -- 32 FP
  elseif audioFormat==3 and bitspersample==64 then Pfmt = "d"        -- 64 FP
  --elseif audioFormat==1 and bitspersample==24 then Pfmt = "i3"     -- 24 will be added in next version, don't use it now!
  --elseif audioFormat==1 and bitspersample==16 then Pfmt = "i2"     -- 16 will be added in next version, don't use it now! 
  else return reaper.MB( "Not supported format(32,64 bit, format 3 need!) !","Info",0) -- If format not supported
  end
  ----------------------------------------------------------
  local numSamples = #buf -- numSamples -------------------- 
  if numSamples<2 then return reaper.MB( "numSamples < 2","Info",0) end -- If numSamples < 2
  local data_ChunkDataSize = numSamples * nchans * bitspersample/8      -- Calculate data_ChunkDataSize!
  -----------------------------------------------------------------------------------------------------------------
  -- RIFF_Chunk =  RIFF_ChunkID, RIFF_chunkSize, RIFF_Type --------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------
    local RIFF_Chunk, RIFF_ChunkID, RIFF_chunkSize, RIFF_Type 
    RIFF_ChunkID   = "RIFF"
    RIFF_chunkSize = 36 + data_ChunkDataSize  -- 4 + (8+fmt_ChunkDataSize) + (8+data_ChunkDataSize)
    RIFF_Type      = "WAVE"
    RIFF_Chunk = string.pack("<c4 I4 c4",
                              RIFF_ChunkID,
                              RIFF_chunkSize,
                              RIFF_Type)  --------------------------------------------->>> Pack RIFF
  -----------------------------------------------------------------------------------------------------------------
  -- fmt_Chunk = fmt_ChunkID, fmt_ChunkDataSize, audioFormat, nchans, srate, byterate, blockalign, bitspersample --
  -----------------------------------------------------------------------------------------------------------------
    local fmt_Chunk, fmt_ChunkID, fmt_ChunkDataSize, byterate, blockalign
    fmt_ChunkID       = "fmt "
    fmt_ChunkDataSize = 16 
    byterate          = srate * nchans * bitspersample/8
    blockalign        = nchans * bitspersample/8
    fmt_Chunk  = string.pack("< c4 I4 I2 I2 I4 I4 I2 I2",
                              fmt_ChunkID,
                              fmt_ChunkDataSize,
                              audioFormat,
                              nchans,
                              srate,
                              byterate,
                              blockalign,
                              bitspersample)  ----------------------------------------->>> Pack fmt
  -----------------------------------------------------------------------------------------------------------------
  -- data_Chunk  =  data_ChunkID, data_ChunkDataSize, Data(bytes) - is written to a file later --------------------
  -----------------------------------------------------------------------------------------------------------------
    local data_Chunk, data_ChunkID
    data_ChunkID = "data"
    data_Chunk = string.pack("< c4 I4",
                              data_ChunkID,
                              data_ChunkDataSize)  ------------------------------------>>> Pack data(ID,size only)
  
  -----------------------------------------------------------------------------------------------------------------
  -- Pack data(samples) and Write to File -------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------
    local file = io.open(FilePath,"wb")  -- Open file in "wb"
    if not file then return reaper.MB("File not aviable!","Info",0) end -- If file not aviable
      ---------------------------------------------------
      -- Pack values(samples), using Pfmt  --------------
      ---------------------------------------------------
      --[[ You can use simple version: for i=1, numSamples do Data_buf[i] = string.pack(Pfmt, buf[i] ) end
           But it is very slower, it is checked. Much faster packing blocks!!! ]]--
      ---------------------------------------------------
      local n = 1024                              -- Block size for packing(it can be changed)
      local rest = numSamples % n                 -- Rest, remainder of the division
      local Pfmt_str = "<" .. string.rep(Pfmt, n) -- Pack format string, for full blocks
      local Data_buf = {}
      -- Pack full blocks --------------
      local b = 1
      for i = 1, numSamples-rest, n do
          Data_buf[b] = string.pack(Pfmt_str, table.unpack( buf, i, i+n-1 ) ) ------------------->>>  Pack samples(Blocks)
          b = b+1
      end
      -- Pack rest ---------------------
      Pfmt_str = "<" .. string.rep(Pfmt, rest)    -- Pack format string, for rest
      Data_buf[b] = string.pack(Pfmt_str, table.unpack( buf, numSamples-rest+1, numSamples ) ) -->>>  Pack samples(Rest)
  
  -------------------------------------------------------
  -- Write Data to file ---------------------------------
  -------------------------------------------------------
  file:write(RIFF_Chunk,fmt_Chunk,data_Chunk, table.concat(Data_buf) ) ---------------->>>  Write All to File
  file:close()
 return true
end

--------------------------------------------------------------------------------
-- Generate Wave(code from JS) -------------------------------------------------
--------------------------------------------------------------------------------
--  Sine, Triangle, Saw, WhiteNoise, PinkNoise -- 
function Gen_Wave(Type, Freq, Gain, duration)
  local start_time = reaper.time_precise()   -- start time_test
    ------------------
    if not Freq then return end
    Freq = math.min(math.max(Freq,10),22050)
    local buf = {}
    local Pi     = math.pi
    local Two_Pi = 2*Pi 
    local adj = Two_Pi/srate * Freq
    local pos = Pi/2
    if Type=="Saw" then pos = Pi end
    local tone
    local b0,b1,b2,b3,b4,b5,b6 = 0,0,0,0,0,0,0
      -- Generate Wave --------------
      for i=1, srate*duration, 1 do 
          if     Type=="Sine"     then -- Sine 
                 tone = math.cos(pos)
          elseif Type=="Triangle" then -- Triangle
                 tone = 2*pos/Pi-1
                 if tone>1 then tone = 2-tone end
          elseif Type=="Saw"      then -- Saw
                 tone = 1-pos/Pi
          elseif Type=="WhiteNoise" then     -- pseudo "white"
                 tone = 2*math.random() - 1
          elseif Type=="PinkNoise"  then     -- pseudo "pink"
                 local white = 2*math.random()-1
                 b0 = 0.99886 * b0 + white * 0.0555179; 
                 b1 = 0.99332 * b1 + white * 0.0750759; 
                 b2 = 0.96900 * b2 + white * 0.1538520; 
                 b3 = 0.86650 * b3 + white * 0.3104856; 
                 b4 = 0.55000 * b4 + white * 0.5329522; 
                 b5 = -0.7616 * b5 - white * 0.0168980; 
                 tone = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362)/6
                 b6 = white * 0.115926; 
          end
          -- to buf ---- 
          buf[i]   = tone * Gain
          pos = pos+adj
          --------------     
          if pos>=Two_Pi then pos = pos-Two_Pi end
      end
      ------------------
  --reaper.ShowConsoleMsg("Generate time = ".. reaper.time_precise()-start_time .. '\n') -- generate time_test
  return buf
end

--------------------------------------------------------------------------------
-- GetSet_Values ---------------------------------------------------------------
--------------------------------------------------------------------------------
function GetSet_Values()
  local Type = Type_cbx.norm_val2[Type_cbx.norm_val]
  local Freq = Frq_sldr.form_val
  local Gain = Gain_sldr.norm_val
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local duration = sel_end - sel_start
  if duration~=0 then reaper.SetEditCurPos(sel_start, true, false) else duration=1 end
  duration = math.min(duration, 60) -- limit duration 1 min 
    --------------------
    local WaveName = Gen_btn.lbl:gsub("Generate ","")
    local FilePath = reaper.GetProjectPathEx(0,"").."/"..WaveName
          FilePath = FilePath:gsub("\\","/")
    --------------------
    local FP_i = FilePath 
    for i=1, 100 do 
       if reaper.file_exists(FP_i..".wav") then FP_i = FilePath .."-"..i 
          else FilePath = FP_i..".wav" break
       end
    end
  return FilePath, Type, Freq, Gain, duration
end

-------------------------------------------------------------------------------------------------------------------------
-- Start ----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

audioFormat = 3
nchans = 1
srate = 44100
bitspersample = 32
----------------
----------------
Init()
mainloop()
