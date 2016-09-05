--[[
   * ReaScript Name:Drums to MIDI(test version)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.01
  ]]

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2, fnt_rgba)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.fnt_rgba = fnt_rgba or {0.7,0.8,0.4,1} --0.7, 0.8, 0.4, 1
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
local Button, Slider, Rng_Slider, Knob, CheckBox, Frame = {},{},{},{},{},{}
  extended(Button,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
    -- Create Slider Child Classes --
    local H_Slider, V_Slider = {},{}
    extended(H_Slider, Slider)
    extended(V_Slider, Slider)
    ---------------------------------
  extended(Rng_Slider, Element)
  extended(Frame,      Element)
  extended(CheckBox,   Element)



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
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = math.min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = math.max(self.norm_val-Step, 0) end
    return true
end
--------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
function V_Slider:set_norm_val()
    local y, h  = self.y, self.h
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((last_y-gfx.mouse_y)/(h*K))
       else VAL = (h-(gfx.mouse_y-y))/h end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
--------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw H_Slider body
end
function V_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = h * self.norm_val
    gfx.rect(x,y+h-val, w, val, true) -- draw V_Slider body
end
--------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw H_Slider label
end
function V_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+h-lbl_h-5;
    gfx.drawstr(self.lbl) -- draw V_Slider label
end
--------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw H_Slider Value
end
function V_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = y+5;
    gfx.drawstr(val) -- draw V_Slider Value
end

------------------------
function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.1
             --if self:set_norm_val_m_wheel() then 
                --if self.onMove then self.onMove() end 
             --end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Rng_Slider Class Methods   -----------------------------------------------
--------------------------------------------------------------------------------
function Rng_Slider:pointIN_Ls(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val
  x = x+val-sb_w -- left sbtn x; x-10 extend mouse zone to the left(more comfortable) 
  return p_x >= x-10 and p_x <= x + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_Rs(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val2
  x = x+val -- right sbtn x; x+10 extend mouse zone to the right(more comfortable)
  return p_x >= x and p_x <= x+10 + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_rng(p_x, p_y)
  local x  = self.rng_x + self.rng_w * self.norm_val  -- start rng
  local x2 = self.rng_x + self.rng_w * self.norm_val2 -- end rng
  return p_x >= x+5 and p_x <= x2-5 and p_y >= self.y and p_y <= self.y + self.h
end
------------------------
function Rng_Slider:mouseIN_Ls()
  return gfx.mouse_cap&1==0 and self:pointIN_Ls(gfx.mouse_x,gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_Rs()
  return gfx.mouse_cap&1==0 and self:pointIN_Rs(gfx.mouse_x,gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_rng()
  return gfx.mouse_cap&1==0 and self:pointIN_rng(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Rng_Slider:mouseDown_Ls()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Ls(mouse_ox,mouse_oy)
end
--------
function Rng_Slider:mouseDown_Rs()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Rs(mouse_ox,mouse_oy)
end
--------
function Rng_Slider:mouseDown_rng()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_rng(mouse_ox,mouse_oy)
end
--------------------------------
function Rng_Slider:set_norm_val()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val --
    if VAL<0 then VAL=0 elseif VAL>self.norm_val2 then VAL=self.norm_val2 end
    self.norm_val=VAL
end
--------
function Rng_Slider:set_norm_val2()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val2 + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val2 --
    if VAL<self.norm_val then VAL=self.norm_val elseif VAL>1 then VAL=1 end
    self.norm_val2=VAL
end
--------
function Rng_Slider:set_norm_val_both()
    local x, w = self.x, self.w
    local diff = self.norm_val2 - self.norm_val -- values difference
    local K = 1           -- K = coefficient
    if Ctrl then K=10 end -- when Ctrl pressed
    local VAL  = self.norm_val  + (gfx.mouse_x-last_x)/(w*K)
    -- valid values --
    if VAL<0 then VAL = 0 elseif VAL>1-diff then VAL = 1-diff end
    self.norm_val  = VAL
    self.norm_val2 = VAL + diff
end
--------------------------------
function Rng_Slider:draw_body()
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h
    local sb_w = self.sb_w 
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.rect(x+val-sb_w, y, val2-val+sb_w*2, h, true) -- draw body
end
--------
function Rng_Slider:draw_sbtns()
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h
    local sb_w = self.sb_w
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.set(r,g,b,0.06)  -- sbtns body color
    gfx.rect(x+val-sb_w, y, sb_w+1, h, true)   -- sbtn1 body
    gfx.rect(x+val2-1,     y, sb_w+1, h, true) -- sbtn2 body
    --gfx.a=0.3 -- frame(if need)
    --gfx.rect(x+val-sb_w, y, sb_w+1, h, false)   -- sbtn1 frame
    --gfx.rect(x+val2-1,     y, sb_w+1, h, false) -- sbtn2 frame
end
--------------------------------
function Rng_Slider:draw_val() -- variant 2
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val  = string.format("%.2f", self.norm_val)
    local val2 = string.format("%.2f", self.norm_val2)
    local val_w,  val_h  = gfx.measurestr(val)
    local val2_w, val2_h = gfx.measurestr(val2)
      local T = 0 -- set T = 0 or T = h (var1, var2 text position) 
      gfx.x = x+5
      gfx.y = y+(h-val_h)/2 + T
      gfx.drawstr(val)  -- draw value 1
      gfx.x = x+w-val2_w-5
      gfx.y = y+(h-val2_h)/2 + T
      gfx.drawstr(val2) -- draw value 2
end
--------
function Rng_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
      local T = 0 -- set T = 0 or T = h (var1, var2 text position)
      gfx.x = x+(w-lbl_w)/2
      gfx.y = y+(h-lbl_h)/2 + T
      gfx.drawstr(self.lbl)
end
--------------------------------
function Rng_Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- set additional coordinates --
    self.sb_w  = h-5
    --self.sb_w  = math.floor(self.w/17) -- sidebuttons width(change it if need)
    --self.sb_w  = math.floor(self.w/40) -- sidebuttons width(change it if need)
    self.rng_x = self.x + self.sb_w    -- range streak min x
    self.rng_w = self.w - self.sb_w*2  -- range streak max w
    -- Get mouse state -------------
          -- Reset Ls,Rs states --
          if gfx.mouse_cap&1==0 then self.Ls_state, self.Rs_state, self.rng_state = false,false,false end
          -- in element --
          if self:mouseIN_Ls() or self:mouseIN_Rs() then a=a+0.1 end
          -- in elm L_down --
          if self:mouseDown_Ls()  then self.Ls_state = true end
          if self:mouseDown_Rs()  then self.Rs_state = true end
          if self:mouseDown_rng() then self.rng_state = true end
          --------------
          if self.Ls_state  == true then a=a+0.2; self:set_norm_val()      end
          if self.Rs_state  == true then a=a+0.2; self:set_norm_val2()     end
          if self.rng_state == true then a=a+0.2; self:set_norm_val_both() end
          if (self.Ls_state or self.Rs_state or self.rng_state) and self.onMove then self.onMove() end
          -- in elm L_up(released and was previously pressed) --
          -- if self:mouseClick() and self.onClick then self.onClick() end
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end
    -- Draw sldr body, frame, sidebuttons --
    gfx.set(r,g,b,a)  -- set color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    self:draw_sbtns() -- draw L,R sidebuttons
    -- Draw label,values --
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz)          -- set lbl,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Knob Class Methods   -----------------------------------------------------   
--------------------------------------------------------------------------------
function Knob:update_xywh() -- redefine method for Knob
    if not Z_w or not Z_h then return end -- return if zoom not defined
    local w_h = math.ceil( math.min(self.def_xywh[3]*Z_w, self.def_xywh[4]*Z_h) )
    self.x = math.ceil(self.def_xywh[1]* Z_w)
    self.y = math.ceil(self.def_xywh[2]* Z_h)
    self.w, self.h = w_h, w_h
    if self.fnt_sz then --fix it!--
      self.fnt_sz = math.max(7, self.def_xywh[5]* (Z_w+Z_h)/2)--fix it!
      self.fnt_sz = math.min(20,self.fnt_sz) 
    end 
end
--------
function Knob:set_norm_val()
    local y, h  = self.y, self.h
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((last_y-gfx.mouse_y)/(h*K))
       else VAL = (h-(gfx.mouse_y-y))/h end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
--------
function Knob:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then return end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = math.min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = math.max(self.norm_val-Step, 0) end
    return true
end
--------
function Knob:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local k_x, k_y, r = x+w/2, y+h/2, (w+h)/4
    local pi=math.pi
    local offs = pi+pi/4
    local val = 1.5*pi * self.norm_val
    local ang1, ang2 = offs-0.01, offs + val
    gfx.circle(k_x,k_y,r-1, false)  -- external
       for i=1,10 do
        gfx.arc(k_x, k_y, r-2,  ang1, ang2, true)
        r=r-1; -- gfx.a=gfx.a+0.005 -- variant
       end
    gfx.circle(k_x, k_y, r-1, true) -- internal
end
--------
function Knob:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+h/2
    gfx.drawstr(self.lbl) -- draw knob label
end
--------
function Knob:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = (y+h/2)-val_h-3
    gfx.drawstr(val) -- draw knob Value
end

------------------------
function Knob:draw()
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
    -- Draw knob body, frame ---
    gfx.set(r,g,b,a)    -- set body,frame color
    self:draw_body()    -- body
    --self:draw_frame() -- frame(if need)
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    --self:draw_lbl()   -- draw lbl(if need)
    self:draw_val()     -- draw value
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
             --if self:set_norm_val_m_wheel() then -- use if need
                --if self.onMove then self.onMove() end 
             --end  
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
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
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
--   Some Default Values   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local srate   = 44100 -- дефолтный семплрейт(не реальный, но здесь не имеет значения)
local n_chans = 2     -- кол-во каналов(трековых), don't change it!
local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 3*60    -- limit maximum time, change, if need.
local defPPQ = 960         -- change, if need.
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10,10,1024,350)
local Gate_Gl  = {}

---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
local Fltr_Frame = Frame:new(10, 370,240,110,  0,0.5,0,0.2 )
local Gate_Frame = Frame:new(260,370,310,110,  0,0.5,0,0.2 )
local Mode_Frame = Frame:new(580,370,454,110,  0,0.5,0,0.2 )
local Frame_TB = {Fltr_Frame, Gate_Frame, Mode_Frame}

----------------------------------------------------------------------------------------------------
---  Create controls objects(btns,sliders etc) and override some methods   -------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = H_Slider:new(20,410,220,18, 0.3,0.5,0.7,0.3, "HP","Arial",15, 0.885 )
-- Filter HP_Freq --------------------------------
local LP_Freq = H_Slider:new(20,430,220,18, 0.3,0.5,0.7,0.3, "LP","Arial",15, 1 )

--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = math.floor(math.exp(sx*math.log(1.059))*8.17742) -- form val
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  --local val = string.format("%.1f", self.form_val)
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val) -- draw Slider Value
end
-------------------------
LP_Freq.draw_val = HP_Freq.draw_val -- Same as the previous(HP_Freq:draw_val())

-- Filter Gain -----------------------------------
local Fltr_Gain = H_Slider:new(80,450,160,18,  0.3,0.5,0.5,0.3, "Out Gain","Arial",15, 0 )
function Fltr_Gain:draw_val()
  self.form_val = self.norm_val*24  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

--------------------------------------------------
-- onUp function for Filter Freq sliders ---------
--------------------------------------------------
function Fltr_Sldrs_onUp()
   if Wave.AA then Wave:Processing()
      if Wave.State then
         Wave:Redraw() 
         Gate_Gl:Apply_toFiltered()
      end
   end
end
----------------
HP_Freq.onUp   = Fltr_Sldrs_onUp
LP_Freq.onUp   = Fltr_Sldrs_onUp
--------------------------------------------------
-- onUp function for Filter Gain slider  ---------
--------------------------------------------------
Fltr_Gain.onUp =
function() 
   if Wave.State then 
      Wave:Redraw()
      Gate_Gl:Apply_toFiltered() 
   end 
end

-------------------------------------------------------------------------------------
--- Gate Sliders --------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Threshold -------------------------------------
local Gate_Thresh = H_Slider:new(270,380,290,18, 0.3,0.5,0.7,0.3, "Threshold","Arial",15, 0.6315 )
function Gate_Thresh:draw_val()
  self.form_val = (self.norm_val-1)*57-3
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val) -- draw Slider Value
  Gate_Thresh:draw_val_line() -- Draw GATE Threshold lines !!!
end
--------------------------------------------------
-- Gate Threshold-lines function -----------------
-------------------------------------------------- 
function Gate_Thresh:draw_val_line()
  if Wave.State then gfx.set(0.8,0.3,0,1)
    local val = (10^(self.form_val/20)) * Wave.Y_scale * Wave.vertZoom * Z_h -- value in gfx
    if val>Wave.h/2 then return end            -- don't draw lines if value out of range
    local val_line1 = Wave.y + Wave.h/2 - val  -- line1 y coord
    local val_line2 = Wave.y + Wave.h/2 + val  -- line2 y coord
    gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
    gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
  end
end
-- Sensetive -------------------------------------
local Gate_Sensetive = H_Slider:new(270,400,290,18, 0.3,0.5,0.7,0.3, "Sensetive","Arial",15, 0.2 )
function Gate_Sensetive:draw_val()
  self.form_val = 2+(self.norm_val)*15       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = H_Slider:new(270,420,290,18, 0.3,0.5,0.5,0.3, "Retrig","Arial",15, 0.0555 )
function Gate_Retrig:draw_val()
  self.form_val  = 20+ self.norm_val * 180   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Detect Velo time ------------------------------ 
local Gate_DetVelo = H_Slider:new(420,450,140,18, 0.3,0.5,0.5,0.3, "Detect Velo","Arial",15, 0.25 )
function Gate_DetVelo:draw_val()
  self.form_val  = 5+ self.norm_val * 20     -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = H_Slider:new(270,450,140,18, 0.3,0.5,0.5,0.3, "Reduce Points","Arial",15, 1 )
function Gate_ReducePoints:draw_val()
  self.cur_max   = self.cur_max or 0 -- current points max
  self.form_val  = math.ceil(self.norm_val * self.cur_max) -- form_val
  if self.form_val==0 and  self.cur_max>0 then self.form_val=1 end -- надо переделать,это принудительно 
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
----------------
Gate_ReducePoints.onUp = 
function()
  if Wave.State then Gate_Gl:Reduce_Points() end
end
--------------------------------------------------
-- onUp function for Gate sliders(except reduce) -
--------------------------------------------------
function Gate_Sldrs_onUp() 
   if Wave.State then Gate_Gl:Apply_toFiltered() end 
end
----------------
Gate_Thresh.onUp    = Gate_Sldrs_onUp
Gate_Sensetive.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp    = Gate_Sldrs_onUp
Gate_DetVelo.onUp   = Gate_Sldrs_onUp


-------------------------------------------------------------------------------------
--- Velo Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(660,450,180,18, 0.3,0.5,0.5,0.3, "Velo Scale","Arial",15, 0.231, 0.79 )
function Gate_VeloScale:draw_val()
  self.form_val  = math.floor(1+ self.norm_val * 126)  -- form_val
  self.form_val2 = math.floor(1+ self.norm_val2 * 126) -- form_val2
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val  = string.format("%d", self.form_val)
  local val2 = string.format("%d", self.form_val2)
  local val_w,  val_h  = gfx.measurestr(val)
  local val2_w, val2_h = gfx.measurestr(val2)
  local T = 0 -- set T = 0 or T = h (var1, var2 text position) 
  gfx.x = x+5
  gfx.y = y+(h-val_h)/2 + T
  gfx.drawstr(val)  -- draw value 1
  gfx.x = x+w-val2_w-5
  gfx.y = y+(h-val2_h)/2 + T
  gfx.drawstr(val2) -- draw value 2
end
--[[----------------------
Gate_VeloScale.onUp = 
function()
   if Wave.State and CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end
end--]]
----------------------------------------
--- Slider_TB --------------------------
----------------------------------------
local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain, 
                   Gate_Thresh,Gate_Sensetive,Gate_Retrig,Gate_DetVelo,Gate_ReducePoints, 
                   Gate_VeloScale}

-------------------------------------------------------------------------------------
--- Buttons -------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Get Selection button --------------------------
local Get_Sel_Button = Button:new(20,380,220,25, 0.4,0.12,0.12,0.3, "Get Selection",    "Arial",15 )
Get_Sel_Button.onClick = 
function()
   local start_time = reaper.time_precise()
   ---------------------
   Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
   Wave.State = false -- reset Wave.State
   if Wave:Create_Track_Accessor() then Wave:Processing()
      if Wave.State then
         Wave:Redraw()
         Gate_Gl:Apply_toFiltered() 
      end
   end
   ---------------------
   --reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n') -- time test 
end
-- Create MIDI Button ----------------------------
local Create_MIDI = Button:new(590,380,250,25, 0.4,0.12,0.12,0.3, "Create MIDI",    "Arial",15 )
Create_MIDI.onClick = 
function()
   if Wave.State then Wave:Create_MIDI() end 
end 
----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Button_TB = {Get_Sel_Button,Create_MIDI}

-------------------------------------------------------------------------------------
--- CheckBoxes ----------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table ---
-------------------------------------------------------------------------------------
--------------------------------------------------
-- MIDI Checkboxes ------------------------------- 0.3,0.5,0.3,0.3 -- green
local CreateMIDIMode = CheckBox:new(590,410,250,18, 0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"Insert new item on new track", "Insert new item on selected track",
                               "Use selected item (auto-replace notes)"} )
-------------------------
local OutNote  = CheckBox:new(590,430,68,18, 0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              --{36,37,38,39,40,41,42,43,44,45,46,47},
                              {'C1: 36', 'C#1: 37', 'D1: 38', 'D#1: 39', 'E1: 40',
                               'F1: 41', 'F#1: 42', 'G1: 43', 'G#1: 44',
                               'A1: 45', 'A#1: 46', 'B1: 47'} 
                              )
-------------------------
local NoteChannel  = CheckBox:new(660,430,88,18, 0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              --{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
                              {'Channel: 1', 'Channel: 2', 'Channel: 3', 'Channel: 4',
                               'Channel: 5', 'Channel: 6', 'Channel: 7', 'Channel: 8',
                               'Channel: 9', 'Channel: 10','Channel: 11','Channel: 12',
                               'Channel: 13','Channel: 14','Channel: 15','Channel: 16'} 
                              )
-------------------------
local NoteLenghth  = CheckBox:new(750,430,90,18, 0.3,0.5,0.5,0.3, "","Arial",15,  3,
                              {"Lenght: 1/4","Lenght: 1/8","Lenght: 1/16","Lenght: 1/32","Lenght: 1/64"} )
-------------------------
-------------------------
local VeloMode = CheckBox:new(590,450,68,18, 0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"Use RMS","Use Peak"} )

VeloMode.onClick = 
function()
   if Wave.State and CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end
end
--------------------------------------------------
-- View Checkboxes -------------------------------
local DrawMode = CheckBox:new(950,380,70,18, 0.3,0.5,0.5,0.3, "Draw: ","Arial",15,  3,
                              { "Very Slow", "Slow", "Medium", "Fast" } )

-- DrawMode.onClick = Get_Sel_Button.onClick (Отключено(работает только при захвате))
-------------------------
local ViewMode = CheckBox:new(950,400,70,18, 0.3,0.5,0.5,0.3, "Show: ","Arial",15,  1,
                              { "All", "Original", "Filtered", "Lines Only" } )
ViewMode.onClick = 
function() 
   if Wave.State then Wave:Redraw() end 
end
--------------------------------------------------
-- Other Checkboxes ------------------------------
local AUChanMode = CheckBox:new(20,450,58,18,  0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"Input 1", "Input 2"} )
AUChanMode.onClick = Get_Sel_Button.onClick
-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {CreateMIDIMode,OutNote,NoteChannel,NoteLenghth,VeloMode, DrawMode, ViewMode, AUChanMode}

---[[ Перенести наверх!!!----------------------
Gate_VeloScale.onUp = 
function()
   if Wave.State and CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end
end--]]

----------------------------------------------------------------------------------------------------------------------------------
--  **************************** **************************** **************************** ---------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Some functions(local functions work faster in big cicles(~30%)) ------------
-- R.Ierusalimschy - "lua Performance Tips" -----------------------------------
-------------------------------------------------------------------------------
local abs  = math.abs
local min  = math.min
local max  = math.max
local sqrt = math.sqrt
local ceil  = math.ceil
local floor = math.floor   

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
  local start_time = reaper.time_precise()--time test
  -----------------------------------------------------
      -------------------------------------------------
      self.State_Points = {}  -- State_Points table 
      -------------------------------------------------
      -- GetSet parameters ----------------------------
      -------------------------------------------------
      -- Threshold, Sensetive ----------
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)      -- Gain from Fltr_Gain slider(need for scaling gate Thresh!)
      local Thresh     = 10^(Gate_Thresh.form_val/20)/gain_fltr * block_size  -- Threshold regard fft scale and gain_fltr
      local Sensetive  = 10^(Gate_Sensetive.form_val/20) -- Gate "Sensetive", diff between - fast and slow envelopes(in dB)
      -- Attack, Release Time -----------
      -- Эти параметры нужно либо выносить в доп. настройки, либо подбирать тщательнее...
      local attTime1  = 0.001                            -- Env1 attack(sec)
      local attTime2  = 0.007                            -- Env2 attack(sec)
      local relTime1  = 0.010                            -- Env1 release(sec)
      local relTime2  = 0.015                            -- Env2 release(sec)
      -----------------------------------
      -- Init counters etc --------------
      ----------------------------------- 
      local retrig_smpls   = floor(Gate_Retrig.form_val/1000*srate)  -- Retrig slider to samples
      local retrig         = retrig_smpls+1                               -- Retrig counter start value!
      local det_velo_smpls = floor(Gate_DetVelo.form_val/1000*srate) -- DetVelo slider to samples 
      -----------------------------------
      local rms_sum, peak_smpl  = 0, 0       -- init rms_sum,   maxRMS
      local maxRMS,  maxPeak    = 0, 0                 -- init max-s
      local minRMS,  minPeak    = math.huge, math.huge -- init min-s
      -------------------
      local smpl_cnt  = 0                   -- Gate sample(for get velo) counter
      local st_cnt    = 1                   -- Gate State counter for State tables
      -----------------------------------
      local envOut1 = Wave.out_buf[1]    -- Peak envelope1 follower start value
      local envOut2 = envOut1            -- Peak envelope2 follower start value
      local Trig = false                 -- Trigger, Trig init state 
      ------------------------------------------------------------------
      -- Compute sample frequency related coeffs ----------------------- 
      local ga1 = math.exp(-1/(srate*attTime1))   -- attack1 coeff
      local gr1 = math.exp(-1/(srate*relTime1))   -- release1 coeff
      local ga2 = math.exp(-1/(srate*attTime2))   -- attack2 coeff
      local gr2 = math.exp(-1/(srate*relTime2))   -- release2 coeff
      
       -----------------------------------------------------------------
       -- Gate main for ------------------------------------------------
       -----------------------------------------------------------------
       for i = 1, Wave.selSamples, 1 do
           local input = abs(Wave.out_buf[i]) -- abs sample value(abs envelope)
           --------------------------------------------
           -- Envelope1(fast) -------------------------
           if envOut1 < input then envOut1 = input + ga1 * (envOut1 - input) 
              else envOut1 = input + gr1 * (envOut1 - input)
           end
           --------------------------------------------
           -- Envelope2(slow) -------------------------
           if envOut2 < input then envOut2 = input + ga2 * (envOut2 - input)
              else envOut2 = input + gr2 * (envOut2 - input)
           end
           
           --------------------------------------------
           -- Trigger ---------------------------------  
           if retrig>retrig_smpls then
              if envOut1>Thresh and (envOut1/envOut2) > Sensetive then
                 Trig = true; smpl_cnt = 0; retrig = 0; rms_sum, peak_smpl = 0, 0 -- set start-values(for capture velo)
              end
            else envOut2 = envOut1 -- уравнивает огибающие,пока триггер неактивен(здесь важно)
           end
           -------------------------------------------------------------
           -- Get samples(for velocity) --------------------------------
           -------------------------------------------------------------
           if Trig then
              if smpl_cnt<=det_velo_smpls then
                 rms_sum   = rms_sum + input*input  -- get  rms_sum   for note-velo
                 peak_smpl = max(peak_smpl, input)  -- find peak_smpl for note-velo
                 smpl_cnt  = smpl_cnt+1 
                 ----------------------------     
                 else 
                      Trig = false -- reset Trig state !!!
                      -----------------------
                      local RMS  = sqrt(rms_sum/det_velo_smpls)  -- calculate RMS
                      --- Trigg point -------
                      self.State_Points[st_cnt]   = i - det_velo_smpls  -- Time point(in Samples!) 
                      self.State_Points[st_cnt+1] = {RMS, peak_smpl}    -- RMS, Peak values
                      --------
                      minRMS  = min(minRMS, RMS)         -- save minRMS for scaling
                      minPeak = min(minPeak, peak_smpl)  -- save minPeak for scaling 
                      maxRMS  = max(maxRMS, RMS)         -- save maxRMS for scaling
                      maxPeak = max(maxPeak, peak_smpl)  -- save maxPeak for scaling             
                      --------
                      st_cnt = st_cnt+2
                      -----------------------
              end
           end       
           ----------------------------------     
           retrig = retrig+1
       end
    -----------------------------
    if minRMS == maxRMS then minRMS = 0 end -- если только одна точка
    self.minRMS, self.minPeak = minRMS, minPeak   -- minRMS, minPeak for scaling MIDI velo
    self.maxRMS, self.maxPeak = maxRMS, maxPeak   -- maxRMS, maxPeak for scaling MIDI velo
    -----------------------------
    Gate_ReducePoints.cur_max = #self.State_Points/2 -- set Gate_ReducePoints slider m factor
    Gate_Gl:normalizeState_TB() -- нормализация таблицы(0...1)
    Gate_Gl:Reduce_Points()     -- Reduce Points
    -----------------------------
    if CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end -- Auto-create MIDI, when mode == 3(use sel item)
    -----------------------------
    collectgarbage("collect") -- collectgarbage(подметает память) 
  -------------------------------
  --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test
  -------------------------------
end

----------------------------------------------------------------------
---  Gate - Normalize points table  ----------------------------------
----------------------------------------------------------------------
function Gate_Gl:normalizeState_TB()
    local scaleRMS  = 1/(self.maxRMS-self.minRMS) 
    local scalePeak = 1/(self.maxPeak-self.minPeak) 
    ---------------------------------
    for i=2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        self.State_Points[i][1] = (self.State_Points[i][1] - self.minRMS)*scaleRMS
        self.State_Points[i][2] = (self.State_Points[i][2] - self.minPeak)*scalePeak
    end
    ---------------------------------
    self.minRMS, self.minPeak = 0, 0 -- норм мин
    self.maxRMS, self.maxPeak = 1, 1 -- норм макс
end

----------------------------------------------------------------------
---  Gate - Reduce trig points  --------------------------------------
----------------------------------------------------------------------
function Gate_Gl:Reduce_Points() -- Надо допилить!!!
    local mode = VeloMode.norm_val
    local tmp_tb = {} -- временная таблица для сортировки и поиска нужного значения
    ---------------------------------
    for i=2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        tmp_tb[i/2] = self.State_Points[i][mode] -- mode - учитываются текущие настройки
    end
    ---------------------------------
    table.sort(tmp_tb) -- сортировка, default, от меньшего к большему
    ---------------------------------
    local pointN = ceil((1-Gate_ReducePoints.norm_val) * #tmp_tb)  -- здесь form_val еще не определено, поэтому так!
    local reduce_val = 0
    if #tmp_tb>0 and pointN>0 then reduce_val = tmp_tb[pointN] end -- искомое значение(либо 0)
    ---------------------------------
    self.Res_Points = {}
    for i=1, #self.State_Points, 2 do
       -- В результирующую таблицу копируются значения, входящие в диапазон --
       if self.State_Points[i+1][mode]>= reduce_val then
         local p = #self.Res_Points+1
         self.Res_Points[p]   = self.State_Points[i]
         self.Res_Points[p+1] = {self.State_Points[i+1][1], self.State_Points[i+1][2]}
       end
    end 
    -- Дальше всегда используется результирующая таблица --
    -----------------------------
    if CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end -- Auto-create MIDI, when mode == 3(use sel item)
    -----------------------------
    
end

----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------
function Gate_Gl:draw_Lines()
  --if not self.Res_Points or #self.Res_Points==0 then return end -- return if no lines
  if not self.Res_Points then return end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    local mode = VeloMode.norm_val
    local offset = Wave.h * Gate_VeloScale.norm_val
    self.scale = Gate_VeloScale.norm_val2 - Gate_VeloScale.norm_val
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    self.Yop = Wave.y + Wave.h - offset        -- y start wave coord for velo points
    self.Ysc = Wave.h * self.scale             -- y scale for velo points 
       
    --------------------------------------------------------
    -- Draw, capture trig lines ----------------------------
    --------------------------------------------------------
    gfx.set(1, 1, 0, 0.7) -- gate line, point color
    ----------------------------
    for i=1, #self.Res_Points, 2 do
        local line_x   = Wave.x + (self.Res_Points[i] - self.start_smpl) * self.Xsc  -- line x coord
        local velo_y   = self.Yop -  self.Res_Points[i+1][mode] * self.Ysc           -- velo y coord    
        ------------------------
        -- draw line, velo -----
        ------------------------
        if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
           gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-1)  -- Draw Trig Line
           gfx.circle(line_x, velo_y, 2,1,1)             -- Draw Velocity point
        end
        
        ------------------------
        -- Get mouse -----------
        ------------------------
        if not self.cap_ln and abs(line_x-gfx.mouse_x)<10 then 
           if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
        end
    end
    
    --------------------------------------------------------
    -- Operations with captured lines(if exist) ------------
    --------------------------------------------------------
    Gate_Gl:manual_Correction()
    -- Update captured state if mouse released -------------
    if self.cap_ln and Wave:mouseUp() then self.cap_ln = false  
       if CreateMIDIMode.norm_val == 3 then Wave:Create_MIDI() end -- Auto-create MIDI, if mode == 3(use sel item)
    end
        
end

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:manual_Correction()
    -- Change Velo, Move, Del Line ---------------
    if self.cap_ln then
        -- Change Velo ---------------------------
        if Ctrl then
            local curs_x = Wave.x + (self.Res_Points[self.cap_ln] - self.start_smpl) * self.Xsc  -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), Wave.y+Wave.h)                            -- y coord
            gfx.set(1, 1, 1, 1) -- cursor color 
            gfx.line(curs_x-12, curs_y, curs_x+12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y-12, curs_x, curs_y+12) -- cursor line
            gfx.circle(curs_x, curs_y, 5, 0, 1)            -- cursor point
            --------------------
            local newVelo = (self.Yop - curs_y)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo   = min(max(newVelo,0),1)
            --------------------
            self.Res_Points[self.cap_ln+1] = {newVelo, newVelo}   -- veloRMS, veloPeak from mouse y
        end
        -- Move Line -----------------------------
        if Shift then 
            local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), self.Yop)        -- y coord
            gfx.set(1, 1, 1, 1) -- cursor color 
            gfx.line(curs_x-12, curs_y, curs_x+12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y-12, curs_x, curs_y+12) -- cursor line
            gfx.circle(curs_x, curs_y, 5, 0, 1)            -- cursor point
            --------------------
            self.Res_Points[self.cap_ln] = self.start_smpl + (curs_x-Wave.x) / self.Xsc -- Set New Position
        end
        -- Delete Line ---------------------------
        if Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
            if gfx.showmenu("Delete")==1 then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
            end
        end       
    end
    
    -- Insert Line(on mouseR_Down) -------------------------
    if not self.cap_ln and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
        if gfx.showmenu("Insert")==1 then
            local line_pos = self.start_smpl + (mouse_ox-Wave.x)/self.Xsc  -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo,0),1)
            --------------------             
            table.insert(self.Res_Points, line_pos)           -- В конец таблицы
            table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
        end
    end 

end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
---  GetSet_MIDITake  ----------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает новый айтем, либо удаляет выбранную ноту в выделленном.
function Wave:GetSet_MIDITake()
    local tracknum, midi_track, item, take
    -- New item on new track(mode 1) ------------
    if CreateMIDIMode.norm_val == 1 then       
        tracknum = reaper.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
        reaper.InsertTrackAtIndex(tracknum, false)
        midi_track = reaper.GetTrack(0, tracknum)
        reaper.TrackList_AdjustWindows(0)
        item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = reaper.GetActiveTake(item)
        return item, take
    -- New item on sel track(mode 2) ------------
    elseif CreateMIDIMode.norm_val == 2 then
        midi_track = reaper.GetSelectedTrack(0, 0)
        if not midi_track or midi_track==self.track then return end -- if no sel track or sel track==self.track
        item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = reaper.GetActiveTake(item)
        return item, take
    -- Use selected item(mode 3) ----------------
    elseif CreateMIDIMode.norm_val == 3 then
        item = reaper.GetSelectedMediaItem(0, 0)
        if item then take = reaper.GetActiveTake(item) end
            if take and reaper.TakeIsMIDI(take) then
               local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
               local findpitch = 35 + OutNote.norm_val -- from checkbox
               local note = 0
                -- Del old notes with same pith --
                for i=1, notecnt do
                    local ret, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
                    if pitch==findpitch then 
                       reaper.MIDI_DeleteNote(take, note); note = note-1 -- del note witch findpitch and update counter
                    end  
                    note = note+1
                end
            reaper.MIDI_Sort(take)
            reaper.UpdateItemInProject(item)
            return item, take
        end   
    end  
end

--------------------------------------------------------------------------------
---  Create MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает миди-ноты в соответствии с настройками и полученными из аудио данными
function Wave:Create_MIDI()
  reaper.Undo_BeginBlock() 
  -------------------------------------------
    local item, take = Wave:GetSet_MIDITake()
    if not take then return end 
    -- Velocity scale ----------
    local mode = VeloMode.norm_val
    local velo_scale  = Gate_VeloScale.form_val2 - Gate_VeloScale.form_val
    local velo_offset = Gate_VeloScale.form_val
    -- Note parameters ---------
    local pitch = 35 + OutNote.norm_val        -- pitch from checkbox
    local chan  = NoteChannel.norm_val - 1     -- midi channel from checkbox
    local len   = defPPQ/NoteLenghth.norm_val  -- note lenght(its always use def ppq(960)!)
    local sel, mute = 1, 0
    local startppqpos, endppqpos, vel, next_startppqpos
    ----------------------------
    local points_cnt = #Gate_Gl.Res_Points
    for i=1, points_cnt, 2 do
        startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i]/srate )
        endppqpos   =  startppqpos + len
        -- По идее,нет смысла по два раза считать,можно просто ставить предыдущую - переделать! --
        if i<points_cnt-2 then next_startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i+2]/srate )
           -- С учетом точек добавленных вручную(но, по хорошему, их надо было добавлять не в конец таблицы, а между текущими) --
           if next_startppqpos>startppqpos then  endppqpos = min(endppqpos, next_startppqpos) end -- del overlaps 
        end
        -- Insert Note ---------
        vel = floor(velo_offset + Gate_Gl.Res_Points[i+1][mode] * velo_scale)
        reaper.MIDI_InsertNote(take, sel, mute, startppqpos, endppqpos, chan, pitch, vel, true)
    end
    ----------------------------
    reaper.MIDI_Sort(take)           -- sort notes
    reaper.UpdateItemInProject(item) -- update item
  -------------------------------------------
  reaper.Undo_EndBlock("~Create_MIDI~", -1) 
end


--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor() 
    self.track = reaper.GetSelectedTrack(0,0)
    if self.track then self.AA = reaper.CreateTrackAudioAccessor(self.track) 
         self.AA_Hash  = reaper.GetAudioAccessorHash(self.AA, "")
         self.AA_start = reaper.GetAudioAccessorStartTime(self.AA)
         self.AA_end   = reaper.GetAudioAccessorEndTime(self.AA)
         self.buffer   = reaper.new_array(block_size*2)-- L,R main block-buffer
         self.buffer.clear()
         return true
    end
end
--------
function Wave:Validate_Accessor()
    if self.AA then 
       if not reaper.AudioAccessorValidateState(self.AA) then return true end 
    end
end
--------
function Wave:Destroy_Track_Accessor()
    if self.AA then reaper.DestroyAudioAccessor(self.AA) 
       self.buffer.clear()
    end
end
--------
function Wave:Get_TimeSelection()
    local sel_start,sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    local sel_len = sel_end - sel_start
    if sel_len<0.25 then return end -- 0.25 minimum
    -------------- 
    self.sel_start, self.sel_end, self.sel_len = sel_start,sel_end,sel_len  -- selection start, end, lenght
    return true
end


----------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------
-- Filter_FFT ----------------------------------------------
------------------------------------------------------------  
function Wave:Filter_FFT(lowband, hiband)
  local buf = self.buffer
    ----------------------------------------
    -- Filter(re = Lchan, im = Rchan ) -----
    ----------------------------------------
    buf.fft(block_size,true)       -- FFT
      -----------------------------
      -- Clear lowband bins --
      buf.clear(0, 1, lowband)                       -- clear start part
      buf.clear(0,  block_size*2 - lowband + 1 )     -- clear end part
      -- Clear hiband bins  --
      buf.clear(0, hiband+1, (block_size-hiband)*2 ) -- clear mid part
      -----------------------------  
    buf.ifft(block_size,true)      -- iFFT
    ----------------------------------------
end  

--------------------------------------------------------------------------------------------
--- DRAW -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered -----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw() -- 
    local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    ---------------
    gfx.dest = 1           -- set dest gfx buffer1
    gfx.a    = 1           -- gfx.a - for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(Wave)
    gfx.setimgdim(1,w,h)   -- set gfx buffer w,h
    ---------------
      if ViewMode.norm_val == 1 then self:draw_waveform(1,  0.3,0.4,0.7,1) -- Draw Original(1, r,g,b,a)
                                     self:draw_waveform(2,  0.7,0.1,0.3,1) -- Draw Filtered(2, r,g,b,a)
        elseif ViewMode.norm_val == 2 then self:draw_waveform(1,  0.3,0.4,0.7,1) -- Only original
        elseif ViewMode.norm_val == 3 then self:draw_waveform(2,  0.7,0.1,0.3,1) -- Only filtered
      end
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r,g,b,a)
    local Peak_TB, Ysc
    local Y = self.Y
    ----------------------------
    if mode==1 then Peak_TB = self.in_peaks;  Ysc = self.Y_scale * self.vertZoom end  
    if mode==2 then Peak_TB = self.out_peaks;
       -- Its not real Gain - но это обязательно учитывать в дальнейшем, экономит время...
       local fltr_gain = 10^(Fltr_Gain.form_val/20)               -- from Fltr_Gain Sldr!
       Ysc = self.Y_scale/block_size * fltr_gain * self.vertZoom  -- Y_scale for filtered waveform drawing 
    end   
    ----------------------------
    ----------------------------
    local w = self.def_xywh[3] -- 1024 = def width
    local Zfact = self.max_Zoom/self.Zoom  -- zoom factor
    local Ppos = self.Pos*self.max_Zoom    -- старт. позиция в "мелкой"-Peak_TB для начала прорисовки  
    local curr = ceil(Ppos+1)
    local n_Peaks = w*self.max_Zoom        -- Макс. доступное кол-во пиков
    gfx.set(r,g,b,a)                       -- set color
    -- уточнить ----------------
    for i=1, w do            
       local next = min( i*Zfact + Ppos, n_Peaks ) -- грубоватое исправление...
       local min_peak, max_peak, peak = 0, 0, 0 
          for p=curr, next do
              peak = Peak_TB[p][1]
              min_peak = min(min_peak, peak)
              peak = Peak_TB[p][2]
              max_peak = max(max_peak, peak)
          end
        curr = ceil(next) 
        local y, y2 = Y - min_peak *Ysc, Y - max_peak *Ysc 
        gfx.line(i,y, i,y2) -- здесь всегда x=i
    end  
    ----------------------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode) -- mode = 1 for oriinal, mode = 2 for filtered
    local buf
    if mode==1 then buf = self.in_buf    -- for input(original)    
               else buf = self.out_buf   -- for output(filtered)
    end
    ----------------------------
    ----------------------------
    local Peak_TB = {}
    local w = self.def_xywh[3] -- 1024 = def width 
    local pix_dens = self.pix_dens
    local smpl_inpix = (self.selSamples/w) /self.max_Zoom  -- кол-во семплов на один пик(при макс. зуме!)
    -- норм --------------------
    local curr = 1
    for i=1, w * self.max_Zoom do
        local next = i*smpl_inpix
        local min_smpl, max_smpl, smpl = 0, 0, 0 
        for s=curr, next, pix_dens do  
            smpl = buf[s]
              min_smpl = min(min_smpl, smpl)
              max_smpl = max(max_smpl, smpl)
        end
        Peak_TB[#Peak_TB+1] = {min_smpl, max_smpl} -- min, max val to table
        curr = ceil(next)   
    end
    ----------------------------
    if mode==1 then self.in_peaks = Peak_TB else self.out_peaks = Peak_TB end    
    ----------------------------
end


------------------------------------------------------------------------------------------------------------------------
-- WAVE - (Get samples(in_buf) > filtering > to out-buf > Create in, out peaks ) ---------------------------------------
------------------------------------------------------------------------------------------------------------------------
function Wave:table_move(tmp_buf)
  local j = AUChanMode.norm_val
  for i = 1, #tmp_buf/2, 1 do  
      tmp_buf[i] = tmp_buf[j]
      j=j+2
  end
  return tmp_buf
end
-------
function Wave:table_plus(mode, size, tmp_buf)
  local buf
  if mode==1 then buf=self.in_buf else buf=self.out_buf end
  local j = AUChanMode.norm_val
  for i = size+1, size + #tmp_buf/2, 1 do  
      buf[i] = tmp_buf[j]
      j=j+2 
  end
end
--------------------------------------------------------------------------------
-- Wave:Set_Values() - set main values, cordinates etc -------------------------
--------------------------------------------------------------------------------
function Wave:Set_Values()
  -- gfx buffer always used default Wave coordinates! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    -- Get Selection ----------------
    if not self:Get_TimeSelection() then return end    -- Get time sel start,end,lenght
    ---------------------------------
    -- Calculate some values --------
    self.sel_len    = min(self.sel_len,time_limit)     -- limit lenght(deliberate restriction) 
    self.selSamples = floor(self.sel_len*srate)        -- time selection lenght to samples
    -- init Horizontal --------------
    self.max_Zoom = 50 -- maximum zoom level(желательно ок.150-200,но зав. от длины выдел.(нужно поправить в созд. пиков!))
    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    -- init Vertical ---------------- 
    self.max_vertZoom = 6       -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1  -- init vertical Zoom 
    ---------------------------------
    -- pix_dens - нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 2^(DrawMode.norm_val-1)            -- 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд.
    self.X, self.Y  = x, h/2                           -- waveform position(X,Y axis)
    self.X_scale    = w/self.selSamples                -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                              -- Y_scale for waveform drawing
    ---------------------------------
    -- Some other values ------------
    self.crsx   = block_size/8   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
    self.Xblock = block_size-self.crsx*2               -- active part of full block
    -----------
    local max_size = 2^22 - 1 -- Макс. доступно(при создании из таблицы можно больше, но...)
    local div_fact = self.Xblock*n_chans -- Размеры полн. и ост. буфера здесь всегда должны быть кратны Xblock*n_chans --
    self.full_buf_sz  = (max_size//div_fact)*div_fact   -- размер полного буфера с учетом кратности div_fact(Xblock*n_chans)
    self.n_Full_Bufs  = (self.selSamples*n_chans)//self.full_buf_sz -- кол-во полных буферов в выделении
    self.n_XBlocks_FB = self.full_buf_sz/div_fact                   -- кол-во X-блоков в полном буфере(с учетом каналов!)
    -----------
    local rest_smpls  = self.selSamples*n_chans - self.n_Full_Bufs*self.full_buf_sz -- остаток семплов
    self.rest_buf_sz  = ceil(rest_smpls/div_fact) * div_fact   -- размер остаточного(окр. вверх для захв. полн. участка)
    self.n_XBlocks_RB = self. rest_buf_sz/div_fact             -- кол-во X-блоков в остаточном буфере(с учетом каналов!) 
  -------------
  return true
end

-----------------------------------
function Wave:Processing()
  local start_time = reaper.time_precise()--time test
    local info_str = "Processing ."
    -------------------------------
    -- Filter values --------------
    -------------------------------
    -- LP = HiFreq, HP = LowFreq --
    local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
    local bin_freq = srate/(block_size*2)          -- freq step 
    local lowband  = Low_Freq/bin_freq             -- low bin
    local hiband   = Hi_Freq/bin_freq              -- hi bin
    -- lowband, hiband to valid values(need even int) ------------
    lowband = floor(lowband/2)*2
    hiband  = ceil(hiband/2)*2  
    -------------------------------------------------------------------------
    -- Get Original(input) samples to in_buf >> to table >> create peaks ----
    -------------------------------------------------------------------------
    if not self.State then
        if not self:Set_Values() then return end -- set main values, coordinates etc   
        ------------------------------------------------------ 
        ------------------------------------------------------
        local size
        local buf_start = self.sel_start
        for i=1,  self.n_Full_Bufs+1 do 
            if i>self.n_Full_Bufs then size = self.rest_buf_sz else size = self.full_buf_sz end  
            local tmp_buf = reaper.new_array(size)
            reaper.GetAudioAccessorSamples(self.AA, srate,n_chans, buf_start, size/n_chans, tmp_buf) -- orig samples to in_buf for drawing
            --------
            if i==1 then self.in_buf = self:table_move(tmp_buf.table()) else self:table_plus(1,(i-1)*self.full_buf_sz/2, tmp_buf.table() ) end
            --------
            buf_start = buf_start + (self.full_buf_sz/n_chans)/srate -- to next
            ------------------------
            info_str = info_str.."."; self:show_info(info_str..".")  -- show info_str
        end
        self:Create_Peaks(1)  -- Create_Peaks input(Original) wave peaks
        self.in_buf  = nil    -- входной больше не нужен
    end
    
    -------------------------------------------------------------------------
    -- Filtering >> samples to out_buf >> to table >> create peaks ----------
    -------------------------------------------------------------------------
    local size, n_XBlocks
    local buf_start = self.sel_start
    for i=1, self.n_Full_Bufs+1 do
       if i>self.n_Full_Bufs then size, n_XBlocks = self.rest_buf_sz, self.n_XBlocks_RB 
                             else size, n_XBlocks = self.full_buf_sz, self.n_XBlocks_FB
       end
       ------
       local tmp_buf = reaper.new_array(size)
       ---------------------------------------------------------
       local block_start = buf_start - (self.crsx/srate)/n_chans  -- first block in current buf start(regard crsx)   
       for block=1, n_XBlocks do reaper.GetAudioAccessorSamples(self.AA, srate,n_chans, block_start,block_size, self.buffer)
           --------------------
           self:Filter_FFT(lowband, hiband)                       -- Filter(note: don't use out of range freq!)
           tmp_buf.copy(self.buffer, self.crsx+1, n_chans*self.Xblock, (block-1)* n_chans*self.Xblock + 1 ) -- copy block to out_buf with offset
           --------------------
           block_start = block_start + self.Xblock/srate   -- next block start_time
       end
       ---------------------------------------------------------
       if i==1 then self.out_buf = self:table_move(tmp_buf.table()) else self:table_plus(2,(i-1)*self.full_buf_sz/2, tmp_buf.table() ) end
       --------
       buf_start = buf_start + (self.full_buf_sz/n_chans)/srate -- to next
       ------------------------
       info_str = info_str.."."; self:show_info(info_str..".")  -- show info_str
    end
    -------------------------------------------------------------------------
    self:Create_Peaks(2)  -- Create_Peaks output(Filtered) wave peaks
    -------------------------------------------------------------------------
    -------------------------------------------------------------------------
    self.State = true -- Change State
    -------------------------
  --reaper.ShowConsoleMsg("Filter time = " .. reaper.time_precise()-start_time .. '\n')--time test   
end 


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = reaper.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.7,0.7,1)
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
  --- play cursor ---
  if reaper.GetPlayState()&1 == 1 then local P_Curs = reaper.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(0.5,0.5,0.5,1)
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
     end
     --------------------------------------------
     -- Auto-scroll(Test Only !!!) --
     --------------------------------------------
     --[[ var1
     if self.Pcx > self.w then 
     self.Pos = self.Pos + self.w/(self.Zoom*Z_w)
     self.Pos = math.max(self.Pos, 0)
     self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
     Wave:Redraw()
     end --]]
     --[[ var2
     if (self.Pcx-512)>20 then 
     self.Pos = self.Pos + 20/(self.Zoom*Z_w)
     self.Pos = math.max(self.Pos, 0)
     self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
     Wave:Redraw()
     end --]]
     --------------------------------------------
     --------------------------------------------
  end
end 
--------------------------
function Wave:Set_Cursor()
  if self:mouseDown() and not(Ctrl or Shift) then  
    if self.insrc_mx then local New_Pos = self.sel_start + (self.insrc_mx/self.X_scale )/srate
       reaper.SetEditCurPos(New_Pos, false, true)    -- true-seekplay(false-no seekplay) 
    end
  end
end 
----------------------------------------------------------------------------------------------------
---  Wave - Get Mouse  -----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Mouse()
    -----------------------------
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
    ----------------------------- 
    --- Wave get-set Cursors ----
    self:Get_Cursor()
    self:Set_Cursor()   
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel
      -------------------
      if     M_Wheel>0 then self.Zoom = min(self.Zoom*1.25, self.max_Zoom)   
      elseif M_Wheel<0 then self.Zoom = max(self.Zoom*0.75, 1)
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      -------------------
      Wave:Redraw() -- redraw after horizontal zoom
    end
    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and Shift and gfx.mouse_wheel~=0 and not Ctrl then 
     M_Wheel = gfx.mouse_wheel
     -------------------
     if     M_Wheel>0 then self.vertZoom = min(self.vertZoom*1.2, self.max_vertZoom)   
     elseif M_Wheel<0 then self.vertZoom = max(self.vertZoom*0.8, 1)
     end                 
     -------------------
     Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
    --- Wave Move ---------------------------
    if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      --------------------
      Wave:Redraw() -- redraw after move view
    end
        
end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()
  self:update_xywh()   -- update coord
  -- draw Wave frame, axis -------------
  gfx.set(0,0.5,0,0.2) -- set color
  gfx.line(self.x, self.y+self.h/2, self.x+self.w-1, self.y+self.h/2 )
  self:draw_frame() 
  -- Insert Wave from gfx buffer1 ------
  gfx.a = 1 -- gfx.a for blit
  local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
  gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)
  -- Get Mouse -------------------------
  self:Get_Mouse()     -- get mouse(for zoom, move etc) 
end  

--------------------------------------------------------------------------------
---  Wave - show_help, info ----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
 local fnt_sz = 16
 fnt_sz = math.max(9,  fnt_sz* (Z_w+Z_h)/2)
 fnt_sz = math.min(20, fnt_sz)
 gfx.setfont(1, "Arial", fnt_sz)
 gfx.set(0.7, 0.7, 0.4, 1)
 gfx.x, gfx.y = self.x+10, self.y+10
 gfx.drawstr(
  [[
  Select track, set time selection(maximum 180s).
  It is better to use not more than 60s selection.
  Press "Get Selection" button.
  Use sliders for change detection setting.
  Ctrl + drag - fine tune.
  ----------------
  On Waveform Area:
  Mouswheel - Horizontal Zoom,
  Shift+Mouswheel - Vertical Zoom, 
  Middle drag - Move View(Scroll),
  Left click - Set Edit Cursor,
  Shift+Left drag - Move Marker,
  Ctrl+Left drag - Change Velocity,
  Shift+Ctrl+Left drag - Move Marker and Change Velocity,
  Right click on Marker - Delete Marker,
  Right click on Empty Space - Insert Marker,
  Space - Play. 
  ]]) 
end

--------------------------------
function Wave:show_info(info_str)
  if self.State or self.sel_len<15 then return end
  gfx.update()
  gfx.setfont(1, "Arial", 40)
  gfx.set(0.7, 0.7, 0.4, 1)
  gfx.x = self.x+self.w/2-200; gfx.y = self.y+(self.h)/2
  gfx.drawstr(info_str)
  gfx.update()
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()
  if Project_Change() then 
     --if not Wave:Validate_Accessor() then Wave.State = false end
     if not Wave:Verify_Project_State() then Wave.State = false end  
  end
  -- Draw Wave, lines etc ------
  if Wave.State then 
       Wave:from_gfxBuffer() -- Wave from gfx buffer
       Gate_Gl:draw_Lines()  -- Draw Gate trig-lines
  else Wave:show_help()      -- else show help
  end
  -- Draw sldrs, btns etc ------
  draw_controls()
end
--------------------------------
-- Get Project Change ----------
--------------------------------
function Project_Change()
    local cur_cnt = reaper.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then proj_change_cnt = cur_cnt
       return true  
    end
end
--------------------------------
-- Verify Project State --------
--------------------------------
-- проверяет только наличие трека, без проверки содержимого AA
-- нужно для маркеров и тп, допилить!
function Wave:Verify_Project_State() -- 
    if self.AA and reaper.ValidatePtr2(0, self.track, "MediaTrack*") then
       --local AA = reaper.CreateTrackAudioAccessor(self.track)
       --if self.AA_Hash == reaper.GetAudioAccessorHash(AA, "") then
          --reaper.DestroyAudioAccessor(AA) -- destroy temporary AA
          return true 
       --end
   end 
end 
--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key,btn    in pairs(Button_TB)   do btn:draw()    end 
    for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 20,20,20              -- 0...255 format
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "TEST"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
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
    if Z_w<0.65 then Z_w = 0.65 elseif Z_w>1.8 then Z_w = 1.8 end 
    if Z_h<0.65 then Z_h = 0.65 elseif Z_h>1.8 then Z_h = 1.8 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    Alt   = gfx.mouse_cap&16==16 -- Shift state
    -------------------------
    -- MAIN function --------
    -------------------------
    MAIN() -- main function
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset mouse_wheel
    local char = gfx.getchar()
    if char==32 then reaper.Main_OnCommand(40044, 0) end -- play
    if char~=-1 then reaper.defer(mainloop)              -- defer
       else Wave:Destroy_Track_Accessor()
    end          
    -----------  
    gfx.update()
    -----------
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------
--reaper.ClearConsole()
Init()
mainloop()
