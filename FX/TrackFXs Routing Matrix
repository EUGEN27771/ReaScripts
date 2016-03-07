
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function pointIN(x,y,w,h)
  return mouse_ox >= x and mouse_ox <= x + w and mouse_oy >= y and mouse_oy <= y + h and
         gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y  >= y and gfx.mouse_y <= y + h
end
-----
function mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---draw current pin---------------------------------------------------------------------------------
function draw_pin(track,fx,isOut,pin,chans, x,y,w,h)
 local Low32,Hi32 = reaper.TrackFX_GetPinMappings(track, fx, isOut, pin)--Get current pin
 local bit,val
 local Click = mouseClick()
 if (pin+1)%2==0 then gfx.set(0,0.6,0) else  gfx.set(0.6,0,0) end --set pin color(odd parity) 
    --------------------------------------
    --draw(and change val if Clicked)-------
    for i = 1, chans do
        bit = 2^(i-1)       --cuurent bit
        val = (Low32&bit)>0 --current bit(aka channel value as booleen)
            if Click and pointIN(x,y,w,h-1) then
                if val then Low32 = Low32 - bit else Low32 = Low32 + bit end 
                reaper.TrackFX_SetPinMappings(track, fx, isOut , pin, Low32, Hi32)--Set pin 
            end
        if val and reaper.TrackFX_GetEnabled(track,fx) then gfx.a = 1 else gfx.a = 0.3 end --set gfx.a
        gfx.rect(x,y,w-2,h-2, val) --bool = val      
        y = y + h --next y
    end 
    --------------------------------------
end
--------------------------------------------------------
---draw_FX_head-----------------------------------------
function draw_FX_head(track,fx,in_Pins,out_Pins, x,y,w,h)
 local _, fx_name = reaper.TrackFX_GetFXName(track, fx, ""); fx_name = fx_name:match(" %P+")
    --draw head and name----------
    y,w,h = y-w ,w*(in_Pins+out_Pins+1.2)-2,h-1 --correct values for head position
    gfx.set(0.5,0.7,0)--set head color
    if reaper.TrackFX_GetEnabled(track,fx) then gfx.a = 1 else gfx.a = 0.3 end --if FX enabled/disabled
       -----------------------
       gfx.x, gfx.y = x, y+(h-gfx.texth)/2
       gfx.rect(x,y,w,h,false) 
       gfx.printf("%.12s",fx_name)
    --Open-Close FX on click-- 
    if mouseClick() and pointIN(x,y,w,h) then
       reaper.TrackFX_SetOpen(track, fx, not reaper.TrackFX_GetOpen(track, fx) )--not bool for change state
    end
end
--------------------------------------------------------
--------------------------------------------------------
---draw current FX--------------------------------------
function draw_FX(track,fx,chans, x,y,w,h)
 local _, in_Pins,out_Pins = reaper.TrackFX_GetIOSize(track,fx) 
 --for some JS-plug-ins---------------------------------
  if out_Pins==-1 and in_Pins~=-1 then out_Pins=in_Pins end --in some JS outs ret "-1" 
  ---------------------------------
  --Draw FX-head-------------------
  draw_FX_head(track,fx,in_Pins,out_Pins, x,y,w,h)
  --------------------------------
  --Draw FX pins,chans etc-- 
    ---------------
    --input pins---
    local isOut=0
    for i=1,in_Pins do
        draw_pin(track,fx,isOut, i-1,chans, x,y,w,h)--(track,fx,isOut, pin,chans, x,y,  w,h)
        x = x + w --next x
    end
    ---------------
    x = x + 1.2*w --Gap between FX in-out pins
    ---------------
    --output pins--
    local isOut=1 
    for i=1,out_Pins do
        draw_pin(track,fx,isOut, i-1,chans, x,y,w,h)--(track,fx,isOut, pin,chans, x,y,  w,h)
        x = x + w --next x
    end   
 return x --return x value for next FX position
end
------------------------------------------------
--draw in-out +/- buttons-----------------------
function draw_track_chan_add_sub(track,chans, x,y,w,h)
       -- "-" --
     gfx.set(0.9,0.8,0, 0.5)
     x = x+1.5*w ; y = y + h*(chans-1.5)
     w, h = w-2, h-2
     local s_w, s_h = gfx.measurestr("-")
     gfx.x, gfx.y = x + (w-s_w)/2 , y + (h-s_h)/2
     gfx.rect(x,y,w,h, 0); gfx.printf("-")
     if mouseClick() and pointIN(x,y,w,h) then reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", math.max(chans-2,2))  end 
       -- "+" --
     y = y+2*h ; 
     s_w, s_h = gfx.measurestr("+")
     gfx.x, gfx.y = x + (w-s_w)/2 , y + (h-s_h)/2 
     gfx.set(0.9,0.8,0, 0.5)
     gfx.rect(x,y,w,h, 0); gfx.printf("+")
     if mouseClick() and pointIN(x,y,w,h) then reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", math.min(chans+2,32)) end 
end
------------------------------------------------
---draw track in/out----------------------------
function draw_track_in_out(type,track,chans, x,y,w,h)
     gfx.x, gfx.y = x, y-2*w
     gfx.set(0.9,0.8,0, 1)
     gfx.printf(type)
     for i=1,chans do 
         if i%2==0 then gfx.set(0,0.6,0, 0.6) else  gfx.set(0.6,0,0, 0.6) end
         gfx.rect(x,y,w-2,h-2, 1)
         y = y + h
     end
end
------------------------------------------------
------------------------------------------------
---Main DRAW function---------------------------
function DRAW()
 local w,h = Z,Z --its only one chan(rectangle) w and h (but it used in all calculation)
 local x,y = 4*w, 4*h  --its first pin of first FX    x and y (but it used in all calculation) 
 local M_Wheel
 ----
 local track = reaper.GetSelectedTrack(0, 0)
   if track then 
      local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
      local fx_count = reaper.TrackFX_GetCount(track)
      local chans = math.min( reaper.GetMediaTrackInfo_Value(track, "I_NCHAN"), 32 ) -- max value for visible chans
    --------------------------------------------------------
    --------------------------------------------------------
    ---Zoom------
     if Ctrl and not Shift then M_Wheel = gfx.mouse_wheel;gfx.mouse_wheel = 0
        if M_Wheel>0 then Z = math.min(Z+1, 30) elseif M_Wheel<0 then Z = math.max(Z-1, 8) end
        gfx.setfont(1,"Calibri", Z)
     end
     ---Rewind---
     if Shift and not Ctrl then M_Wheel = gfx.mouse_wheel;gfx.mouse_wheel = 0
        if M_Wheel>0 then R = math.min(R+1, fx_count) elseif M_Wheel<0 then R = math.max(R-1, 1) end
        gfx.setfont(1,"Calibri", Z)
     end
    --------------------------------------
    --draw track info(name,fx count etc)--
      gfx.set(0.9,0.7,0, 1)
      gfx.x, gfx.y = y, h
      gfx.printf("Track: " .. track_name.."     FXs: "..fx_count )
    --------------------------------------
    --draw track in,chan_add_sub----------
      draw_track_in_out("IN", track,chans, w,y,w,h)
      draw_track_chan_add_sub(track,chans, w,y,w,h) 
    --draw each FX(pins,chans etc)--------
       for i=R, fx_count do --R = 1-st drawing FX(used for rewind FXs)
           x = draw_FX(track, i-1,chans, x,y,w,h) + w*2 -- offset for next FX
       end 
    --------------------------------------
    --draw track out----------------------
      draw_track_in_out("OUT",track,chans, x,y,w,h)
    ----------------------------
    else gfx.set(0.9,0.7,0, 1); gfx.x, gfx.y = 4*w, h; gfx.printf("Track:  " .. "No selected!") 
   end

end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---INIT---------------------------------------------------------------------------------------------
Z = 15 --used as cell w,h(and for change zoom level etc)
R = 1  --used for rewind FXs
gfx.clear=1315860
gfx.init( "TEST", 700,300 )
gfx.setfont(1,"Calibri", Z)
last_mouse_cap=0
mouse_dx, mouse_dy =0,0
---------------------------------------
function mainloop()
 if gfx.mouse_cap&1==1 and last_mouse_cap&1==0 then 
    mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
 end
 Ctrl  = gfx.mouse_cap&4==4
 Shift = gfx.mouse_cap&8==8
 
 ----------------------
 --MAIN DRAW function--
 DRAW()
 ----------------------
 ----------------------
 last_mouse_cap = gfx.mouse_cap
 last_x,last_y = gfx.mouse_x,gfx.mouse_y
 if gfx.getchar()~=-1 then reaper.defer(mainloop) end --defer
 gfx.update();
end
---------------------------------------
-------------
mainloop()
