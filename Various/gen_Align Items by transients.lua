--[[
   * ReaScript Name:Align Items by transients
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
-- Controls ----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--------------------------------------------------
-- Sliders ---------------------------------------
--------------------------------------------------
local Sensitivity = H_Slider:new(10,10,300,18,  0.3,0.5,0.5,0.3, "Sensitivity","Arial",15, 0.2 )
function Sensitivity:draw_val()
  self.form_val = math.ceil(self.norm_val*100)  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val).." %"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

---------------
local Threshold = H_Slider:new(10,30,300,18,  0.3,0.5,0.5,0.3, "Threshold","Arial",15, 0.7 )
function Threshold:draw_val()
  self.form_val = -60 + self.norm_val*60  -- form value
  self.form_val = math.floor(self.form_val/0.2)*0.2
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

---------------
local Retrig = H_Slider:new(10,50,300,18,  0.3,0.5,0.5,0.3, "Retrig","Arial",15, 0.3 )
function Retrig:draw_val()
  self.form_val = 50+ math.floor(self.norm_val*500)
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

---------------
local Align = H_Slider:new(10,70,300,18,  0.3,0.5,0.5,0.3, "Align","Arial",15, 1 )
function Align:draw_val()
  self.form_val = math.ceil(self.norm_val*100)  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val).." %"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

--------------------------------------------------
-- Checboxes -------------------------------------
--------------------------------------------------
local RefItem = CheckBox:new(10,100,300,18,  0.3,0.5,0.5,0.3, "", "Arial",15,  1,
                              {"Reference"} )

--------------------------------------------------
-- Buttons ---------------------------------------
--------------------------------------------------
local Quantize = Button:new(170,130,140,20,  0.3,0.5,0.5,0.3, "Quantize markers", "Arial",15 )


--------------------------------------------------
-- controls functions ----------------------------
--------------------------------------------------
function onUp_Main()
  Run_Main = true
end
---------------
Sensitivity.onUp  = onUp_Main
Threshold.onUp  = onUp_Main  
Retrig.onUp     = onUp_Main
Align.onUp      = onUp_Main
RefItem.onClick = onUp_Main
Quantize.onClick = 
function()
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  if sel_end - sel_start>0 then reaper.Main_OnCommand(41847, 0)
     else reaper.Main_OnCommand(41846, 0)
  end 
end

--------------------------------------------------
-- Controls Tables -------------------------------
--------------------------------------------------
local Slider_TB   = {Sensitivity, Threshold, Retrig, Align}
local CheckBox_TB = {RefItem}
--local Button_TB   = {Quantize}




----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--   SCRIPT - MAIN   -------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Time_Test(start_time, msg_txt)  -- time test function
  local msg_txt = msg_txt or "Proccessing Time = "
  return reaper.ShowConsoleMsg(msg_txt .. reaper.time_precise()-start_time ..'\n')
end
----------------------------------------------------------------------
--  Set Threshold, Sensitivity Values  ---------------------------------
----------------------------------------------------------------------
function Set_ThreshSens_Values()
  -- Set Sensitivity --------
  reaper.Main_OnCommand(967, 0)  -- "reset" Sensitivity
  for i=1, Sensitivity.form_val do          -- set new value
     reaper.Main_OnCommand(41536, 0)
  end
  -- Set threshold --------
  reaper.Main_OnCommand(968, 0)  -- "reset" Threshold
  for i=1, (60 + Threshold.form_val)/0.2 do -- set new value
     reaper.Main_OnCommand(40218, 0)
  end
end

----------------------------------------------------------------------
-- Normalize - UnNormalise Item -----------------------------------------
----------------------------------------------------------------------
-- нормализация с учетом уровня айтема и тейка, сохр. ориг уровней ---
function Normalize(item, take) 
  -- Save item, take vols for restoring --
  local item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL") 
  local take_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
  -- Full normalize --
  reaper.SetMediaItemInfo_Value(item, "D_VOL", 1) -- reset item_vol to 1 (0 dB)
  reaper.Main_OnCommand(40108, 0)                 -- normalize(take vol change)
  return item_vol, take_vol -- need for restoring previos values
end

-- восстановление оригинальных уровней айтема и тейка ------
function UnNormalise(item, take, item_vol, take_vol)
  reaper.SetMediaItemInfo_Value(item, "D_VOL", item_vol)
  reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", take_vol)
end

----------------------------------------------------------------------
-- Del Stretch Markers in range ------------------------------------------
----------------------------------------------------------------------
function Del_StretchMarkers()  -- Удаляет существующие маркеры на обр. участке
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  if sel_end-sel_start>0 then reaper.Main_OnCommand(41845, 0) -- remove str-marks(in time sel) -- case 1
     else reaper.Main_OnCommand(41844, 0)                     -- remove str-marks(All) -- case 2
  end
end
----------------------------------------------------------------------
-- Create Stretch Markers tables -------------------------------------
----------------------------------------------------------------------
function Create_MarkersTable(item, take, mrks_start, mrks_end)
  local mark_tb = {}
  ----------------------
  reaper.SelectAllMediaItems(0, false)     -- unsel all items
  reaper.SetMediaItemSelected(item, true)  -- sel only current item
  -- Del old markers from time sel or all from item --
  -- Возможно, работа по time sel не имеет особого смысла...убрать?
  Del_StretchMarkers() -- Удаляет существующие маркеры на обр. участке
  ----------------------
  local item_vol, take_vol = Normalize(item, take) -- Normalize
  ----------------------
  local retrig = Retrig.form_val/1000
  local last_trig = - retrig
  local curs_pos, last_curs_pos
  ----------------------
  reaper.SetEditCurPos(mrks_start, false, false)  -- cursor to mrks_start 
  mark_tb[1] = mrks_start                         -- first mark(in mrks_start)
  --------------------------------------
  while true do reaper.Main_OnCommand(40375, 0)   -- cursor to next transient(in sel item)
      curs_pos = reaper.GetCursorPosition()       -- get current curs_pos time 
      if curs_pos>mrks_end or curs_pos==last_curs_pos then break
         elseif curs_pos-last_trig>retrig then 
           --------------
           mark_tb[#mark_tb+1] = curs_pos         -- Используется проектное время - так проще!
           last_trig = curs_pos                   -- upd last_trig pos   
           --------------
      end
      last_curs_pos = curs_pos                    -- upd last_curs pos
  end
  --------------------------------------
  mark_tb[#mark_tb+1] = mrks_end                  -- last mark(in mrks_end)
  ----------------------
  UnNormalise(item, take, item_vol, take_vol)     -- Un-Normalise
  ----------------------
  return mark_tb 
end

----------------------------------------------------------------------
--  Compare_StretchMarkers(ref_tb and proc_tb)  ----------------------
----------------------------------------------------------------------
function Compare_MarkersTables(ref_tb, proc_tb, ref_take, proc_take)
  ------------------------------------------
  local search_zone = (Retrig.form_val/1000)/2 -- зона поиска "парных" маркеров 
  ------------------------------------------
  -- compare and rebuild marker-tables -----
  local next=1
  for i=1, #ref_tb do 
      local ref_pos  = ref_tb[i]    -- Позиция референсного маркера(из ref_tb) 
      local min_diff = search_zone
      local proc_pos, diff 
      ------------------------
      for j=next, #proc_tb  do
          proc_pos = proc_tb[j]     -- Позиция текущего маркера(из proc_tb)
          -- for break -------
          if proc_pos>ref_pos+search_zone then break end -- Выход из цикла по выходу из зоны поиска
          --------------------
          diff = math.abs(ref_pos-proc_pos)
          --------------------
          if diff<min_diff then min_diff = diff    -- обнов. мин. значение и сопутствующие
                 proc_tb[j] = {proc_pos, ref_pos}  -- найденный марк, ориг. позиция и необх. значение
            else proc_tb[j] = false                -- proc-маркер без пары - на удаление
          end
          --------------------
          next = j+1
      end
      ------------------------
  end
  ------------------------------------------
  -- process rest from proc_tb if need -----
  for i=next, #proc_tb do proc_tb[i] = false end  -- удаляет оставшиеся за бортом proc-маркеры

end

----------------------------------------------------------------------
--  Insert Ref Stretch Markers ------------------------------------------
----------------------------------------------------------------------
function Insert_RefStretchMarkers(ref_item, ref_take, ref_tb)
  local item_start = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION" )
  local playrate = reaper.GetMediaItemTakeInfo_Value(ref_take, 'D_PLAYRATE') 
  -- Insert ref markers --
  for i=1, #ref_tb do
      local pos = (ref_tb[i]-item_start)*playrate
      reaper.SetTakeStretchMarker(ref_take, -1, pos)
  end 
end

----------------------------------------------------------------------
--  Insert and Align Proc Stretch Markers(proc to ref)  --------------
----------------------------------------------------------------------
function Insert_Align_ProcStretchMarkers(proc_item, proc_take, proc_tb)
  local proc_offs  = reaper.GetMediaItemTakeInfo_Value(proc_take, 'D_STARTOFFS') -- нужно для srcposIn!
  local item_start = reaper.GetMediaItemInfo_Value(proc_item, "D_POSITION" )
  local playrate = reaper.GetMediaItemTakeInfo_Value(proc_take, 'D_PLAYRATE') -- playrate
  local align_mlt = Align.norm_val
  -- Insert, align markers --
  for i=1, #proc_tb do
     if proc_tb[i] then 
        local orig_pos     = (proc_tb[i][1]-item_start)*playrate       -- original position
        local new_pos_max  = (proc_tb[i][2]-item_start)*playrate       -- 100% align position
        local new_pos  = orig_pos + (new_pos_max-orig_pos)*align_mlt   -- new position regard align_mlt
        -- добавить проверку позиций! --
        local mark_idx = reaper.SetTakeStretchMarker(proc_take, -1, orig_pos, orig_pos+proc_offs) -- add mark to orig pos
        reaper.SetTakeStretchMarker(proc_take, mark_idx, new_pos)                                 -- change position
     end   
  end 
end

----------------------------------------------------------------------
-- Get Start, End Range ----------------------------------------------
----------------------------------------------------------------------
function Get_StartEndRange(ref_item, proc_item)
  local ref_item_start, ref_item_end, proc_item_start, proc_item_end   
  ref_item_start = reaper.GetMediaItemInfo_Value(ref_item, 'D_POSITION')
  ref_item_end   = ref_item_start+reaper.GetMediaItemInfo_Value(ref_item, 'D_LENGTH')
  proc_item_start = reaper.GetMediaItemInfo_Value(proc_item, 'D_POSITION')
  proc_item_end   = proc_item_start+reaper.GetMediaItemInfo_Value(proc_item, 'D_LENGTH')
  -------------
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0) 
  -------------
  if  sel_end-sel_start>0 then 
         return math.max(sel_start,ref_item_start,proc_item_start), math.min(sel_end,ref_item_end,proc_item_end)
    else return math.max(ref_item_start,proc_item_start), math.min(ref_item_end,proc_item_end)
  end
end

----------------------------------------------------------------------
-- Get Items and active Takes ----------------------------------------
----------------------------------------------------------------------
function Get_SelItemsTakes()
  local items_cnt = reaper.CountSelectedMediaItems(0)
  -------------
  local items_tb = {}
  for i=0, items_cnt-1 do 
      local item = reaper.GetSelectedMediaItem(0, i)
      local take = reaper.GetActiveTake(item)
      if take and not reaper.TakeIsMIDI(take) then items_tb[#items_tb+1] = {item, take} end
  end
  -------------
  return items_tb
end

----------------------------------------------------------------------
-- Main --------------------------------------------------------------
----------------------------------------------------------------------
function MAIN()
  Set_ThreshSens_Values() -- Set Detection settings
  -- Get selected Items, active Takes --
  local items_tb = Get_SelItemsTakes()
  if #items_tb<2 then return reaper.MB("Need two or more selected Audio-Items!", "Info", 0) end
    ---------------------------------
    -- исправить, перестройку меню -- 
    -- перенести в контролы! --------    
    RefItem.norm_val2 = {}
    for k,v in pairs(items_tb) do
       local retval, name = reaper.GetSetMediaItemTakeInfo_String(items_tb[k][2], "P_NAME", "", false)
       name = "Reference : "..name
       local len = #name 
       while gfx.measurestr(name)>RefItem.w-15 do
             len = len-1  
             name = name:sub(1,len)..".."
       end 
       RefItem.norm_val2[k] = name
    end
   --------------------------------- 
   local ref = RefItem.norm_val
   ---------------------------------
   if ref>#items_tb then ref = 1; RefItem.norm_val = 1 end -- if sel items will be changed
  
  ------------------------------------------------
  ------------------------------------------------
  reaper.PreventUIRefresh(777)
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEVIEW"), 0) -- SAVE VIEW
  local usr_curs_pos = reaper.GetCursorPosition() -- store usr(current) cursor pos
  
    ------------------------------------------------ 
    local ref_item, ref_take = items_tb[ref][1], items_tb[ref][2]      -- Reference
    -- Реф. таблицу - созд. один раз и в дальнейшем коприруется --
    local mrks_start, mrks_end = Get_StartEndRange(ref_item, ref_item) -- передается Ref-айтем в арг. чтобы не переписывать
    local ref_tb = Create_MarkersTable(ref_item, ref_take, mrks_start, mrks_end) -- ref str_marks(реф. маркеры - не трогаются)
    ------------------------------------------------
    ------------------------------------------------  
    for i=1, #items_tb do 
      if i~=ref then -- Рефер не должен проходить!
        ----------------------------------------------
        -- Get StartEndRange - selection(or items edges in sel) --
        local proc_item, proc_take = items_tb[i][1], items_tb[i][2]     
        local mrks_start, mrks_end = Get_StartEndRange(ref_item, proc_item) -- Для текущей пары айтемов
        ----------------------------------------------
        -- Create markers tables ---------------------
        local proc_tb = Create_MarkersTable(proc_item, proc_take, mrks_start, mrks_end) -- proc str_marks
        ----------------------------------------------
        --- Compare, Insert, Align markers -----------
        Compare_MarkersTables(ref_tb, proc_tb, ref_take, proc_take)
        Insert_Align_ProcStretchMarkers(proc_item, proc_take, proc_tb)  -- insert and align proc
      end 
    end
    ------------------------------------------------
    ------------------------------------------------
    Insert_RefStretchMarkers(ref_item, ref_take, ref_tb) -- insert refs(все, влючая непарные)
    reaper.SelectAllMediaItems(0, false)           -- unsel all items
    for i=1, #items_tb do reaper.SetMediaItemSelected(items_tb[i][1], true) end -- restore sel items 
    ---------------------
  reaper.SetEditCurPos(usr_curs_pos, false, false) -- restore usr cursor pos
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTOREVIEW"), 0) -- RESTORE VIEW
  reaper.Undo_EndBlock("Align Items by transients", -1)
  reaper.PreventUIRefresh(-777)
  ------------------------------------------------
  ------------------------------------------------
  reaper.UpdateTimeline()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    --for key,btn    in pairs(Button_TB)   do btn:draw()    end 
    for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    --for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
end
--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 20,20,20              -- 0...255 format
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "Align Items"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,350 
    Wnd_W,Wnd_H = 320,130 -- global values(used for define zoom level)
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
    -- MAIN functions -------
    -------------------------
    draw_controls()
    if Run_Main then MAIN(); Run_Main = false  end
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset mouse_wheel
    local char = gfx.getchar()
    if char==32 then reaper.Main_OnCommand(40044, 0) end -- play
    if char~=-1 then reaper.defer(mainloop) end          -- defer     
    -----------  
    gfx.update()
    -----------
end

--------------------------------------------------------------------------------
-- START -----------------------------------------------------------------------
--------------------------------------------------------------------------------
Run_Main = true
Init()
mainloop()


