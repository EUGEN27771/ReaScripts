-- FXChain(module)
-- @noindex



--[[
Поскольку мы не можем редактировать непосредственно FXChain, а только в паре с чанком, пришлось заморочится. 
Итого, это 100% самая удобная схема.
Она позволяет легко оперировать FXChain и FX внутри FXChain как на одном треке, так и между треками.
То есть, в любых комбинациях и, что важно, без учета моментов взятия и установки чанка(если нужно), см. use_src_track_chunk.
В функции SetTrackFXChain(track, fx_chain, use_src_track_chunk):
если use_src_track_chunk = false - будет использован target track_chunk(текущий чанк трека на данный момент).
если use_src_track_chunk = true - будет использован source track_chunk(полученный на момент запуска GetChain).
Второй вариант быстрее, подходит для одномоментных операций, не растянутых во времени и только в рамках одного трека!
Выбирать по ситуации.
--]]

local FXChain = {}

---=============================================================================
function msg(m) reaper.ShowConsoleMsg("\n" .. tostring(m)) end
--------
function TimeTest(start_time, end_time, lbl)
  if (not start_time and end_time) then return end
  msg(lbl .. end_time - start_time .. "\n")
end

--==============================================================================
--------  Get-Set TrackChunk functions -----------------------------------------
--==============================================================================
--[[
== GetSet TrackChunk mini-description ============
In standart function GetTrackStateChunk chunk size limited 4194303 = 4094*1024-1 byte
На установку станд. ф-я вроде тянет более 4M, пока пробуем! Если будет косячить - вернуть WDL!
Хотя по тестам - на установке время одинаково...
Примечание по isundo:
isundo = false or isundo = true? See: https://forum.cockos.com/showthread.php?t=181000
Justin: If you use isundo=false, you will get your <PARMENVs  etc .... so disregard it and use false!
--]]
--------------------------------------------------
-- Get track chunk(allow > 4MB) ------------------
--------------------------------------------------
function GetTrackChunk(track)
  if not track then return end
  -- Try standart function -----
  local ret, track_chunk = reaper.GetTrackStateChunk(track, "", false) -- isundo = false
  if ret and track_chunk and #track_chunk < 4194303 then return track_chunk end
  -- If chunk_size >= max_size, use wdl fast string --
  local fast_str = reaper.SNM_CreateFastString("")
  if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
    track_chunk = reaper.SNM_GetFastString(fast_str)
  end
  reaper.SNM_DeleteFastString(fast_str)
  return track_chunk
end

--------------------------------------------------
-- Set track chunk(allow > 4MB) ------------------
--------------------------------------------------
function SetTrackChunk(track, track_chunk)
  if not (track and track_chunk) then return end
  return reaper.SetTrackStateChunk(track, track_chunk, false)
  --[[
  if #track_chunk < 4194303 then return reaper.SetTrackStateChunk(track, track_chunk, false) end  -- isundo = false
  -- If chunk_size >= max_size, use wdl fast string --
  local fast_str, ret 
  fast_str = reaper.SNM_CreateFastString("")
  if reaper.SNM_SetFastString(fast_str, track_chunk) then
    ret = reaper.SNM_GetSetObjectState(track, fast_str, true, false)
  end
  reaper.SNM_DeleteFastString(fast_str)
  return ret
  --]]
end

--==============================================================================
--------  GetSetTrackFXChain functions -----------------------------------------
--==============================================================================
--[[
== Get Chain mini-description ====================
Returned table description:
src_track_chunk - fx chain source track_chunk (исходный чанк)
_start - fx chain start position in track_chunk
_end   - fx chain end position in track_chunk
head - fx chain header content(часть от "<FXCHAIN..." до первого fx-чанка)
fxs[1] ... fxs[n] - fx chunks content, string, from "BYPASS.."  to "WAK .."
tail - fx chain tail content(часть от конца последнего fx-чанка до конца fx chain "...>\n")
------
FXChain.GetEmpty - вспом. функция, вызывается из осн. функции, в случае,
когда цепь либо пуста, либо отсутствует.

== Set Chain mini-description ====================
Мы не можем установить FX chain отдельно от чанка трека, только совместно.
Поэтому, для повышения быстродействия применяем такой метод.
1)Используем booleen use_src_track_chunk = true:
Если мы уверены, что нам подходит исходный трек-чанк(в большинстве ситуаций это так), то оставляем его.
2)Используем booleen use_src_track_chunk = false:
Если необходимо влепить FX chain в другой чанк(на другой трек, или текущий трек успел измениться) - берем по-новой.
------
FXChain.RebuildPLINKS - вспом. функция, вызывается из осн. функции, в случае, когда цепь содержит parameter links.
Если цепь была перестроена, линки перестраиваются соответственно, чтобы сохранить правильную привязку.
За вызов отвечает booleen - rebuild_plinks = true
------
Очень важный момент - в случае, когда fx-чанки содержат parameter modulation в любом виде,
а в настройках Рипера стоит галка Allow live FX multiprocessing, 
то установка такого чанка напрямую приведет к зависону!
Поэтому, такие чанки ф-я FXChain.Set специально устанавливает в два этапа!!!
Сначала - чанк без "<PROGRAMENV...> секций, а затем c ними. Это решает вопрос.
Потеря производительности минимальна(не более 10%), Рипер не ставит повторно идентичные части!
--]]

--------------------------------------------------
-- Get FX Chain if chain empty or no exist -------
--------------------------------------------------
function FXChain.GetEmpty(track_chunk)
  local _start, _end, head, tail, fxs, s, e, t
  --------
  s, e = track_chunk:find("MAINSEND.-\n") -- firstly, find "MAINSEND" string
  _start, _end, head = track_chunk:find("^(<FXCHAIN\n.-)>\n", e + 1) -- Try find empty FXCHAIN
  --------
  if not _start then -- if empty FXCHAIN not found, use custom values
    _start, _end = e + 1, e -- its correct values for inserting, see FXChain.Set
    head = "<FXCHAIN\nWNDRECT 100 100 100 100\nSHOW 0\nLASTSEL 0\nDOCKED 0\n" 
  end
  --------
  if not _start then return end
  local t = {src_track_chunk = track_chunk, _start = _start, _end = _end, head = head, tail = ">\n", fxs = {} }
  return t
end

--------------------------------------------------
-- Get FX Chain, return table see description  ---
--------------------------------------------------
function FXChain.Get(track)
  if not track then return end
  local track_chunk = GetTrackChunk(track) -- Get Track Chunk
  if not track_chunk then return end
  --------
  local fx_cnt = reaper.TrackFX_GetCount(track)
  if fx_cnt == 0 then return FXChain.GetEmpty(track_chunk) end
  --------
  local _start, _end, head, tail, fxs, s, e, fx_chunk 
  _start, e, head = track_chunk:find("(<FXCHAIN\n.-)BYPASS") -- start, head
  --------
  fxs = {}
  e = e - 6 -- sub "BYPASS" length
  for i = 1, fx_cnt do -- get fx_chunks
    s, e, fx_chunk = track_chunk:find("^(BYPASS %d %d %d\n.-WAK %d\n)", e + 1)
    if fx_chunk then fxs[i] = fx_chunk else return end
  end
  --------
  local s, _end, tail = track_chunk:find("(.->\n)", e + 1) -- end, tail
  --------
  local t = {src_track_chunk = track_chunk, _start = _start, _end = _end, head = head, tail = tail, fxs = fxs} 
  return t
end

--------------------------------------------------
-- Rebuild PLINKS  -------------------------------
--------------------------------------------------
function FXChain.RebuildPLINKS(track, fx_chain)
  --msg("== Rebuild Plink ==") -- Test msg!!!
  -- get src order -----------
  local fx_cnt = reaper.TrackFX_GetCount(track)
  local src = {}
  for i = 1, fx_cnt do
    local guid = reaper.TrackFX_GetFXGUID(track, i-1)
    src[guid] = i-1
  end
  -- get dest(modifed fxchain) order ---
  local pattern = ".+FXID ({%x+%-%x+%-%x+%-%x+%-%x+})\n"
  local dest = {}
  for i = 1, #fx_chain.fxs do
    local guid = fx_chain.fxs[i]:match(pattern)
    dest[guid] = i-1
  end
  -- create convert table ----
  local src2dest = {}
  for k, v in pairs(dest) do -- k = guid; v = idx
    local src, dest = src[k], dest[k]
    if src and dest then
      src2dest[src] = dest
    end
  end
  
  -- Replace Plinks string ---
  local cur_fx -- for repl function and rebuild cycle
  function repl(scale, host_fx, host_fx_rel, host_fxparam, offset)
    local old_host_fx = tonumber(host_fx)     -- old host fx, it's 0-based
    local new_host_fx = src2dest[old_host_fx] -- new host, fx 0-based
    --msg("Plink OK, old_host_fx = " .. old_host_fx .. " , new_host_fx = " .. (new_host_fx or "no new_host_fx!")) -- TEST!!!
    --------------------------
    if new_host_fx then 
      local new_host_fx_rel = new_host_fx - cur_fx
      local new = new_host_fx .. ":" .. new_host_fx_rel -- new str(new_host_fx:new_host_fx_rel)
      local str = "PLINK  " .. scale .. " " .. new .. " " .. host_fxparam .. " " .. offset .. "\n"
      return str
    else return "\n" -- del, if no new_host_fx
    end
  end
  ----------------------------
  for i = 1, #fx_chain.fxs do
    cur_fx = i - 1 -- current fx, 0-based for reaper func
    local pattern = "PLINK (%g+) (%g+):(%g+) (%g+) (%g+)\n"
    fx_chain.fxs[i] = fx_chain.fxs[i]:gsub(pattern, repl)
    --msg(fx_chain.fxs[i]) -- TEST - don't use on long chunks!!! 
  end
  
end

--------------------------------------------------
-- Set FX Chain, return true if succefully  ------
--------------------------------------------------
-- Переделать, лишние действия!!!
function FXChain.Set(track, fx_chain, use_src_track_chunk, rebuild_plinks)
  if not (track and fx_chain) then return end
  --------
  local cur_fx_chain
  if use_src_track_chunk then cur_fx_chain = fx_chain else cur_fx_chain = FXChain.Get(track) end
  if not cur_fx_chain then return end
  --------
  local s, e, track_chunk = cur_fx_chain._start - 1, cur_fx_chain._end + 1, cur_fx_chain.src_track_chunk
  --------
  if rebuild_plinks then FXChain.RebuildPLINKS(track, fx_chain) end -- Перестраивает Plink
  --------
  local chunk_start, chunk_end  = track_chunk:sub(1, s) .. fx_chain.head, fx_chain.tail .. track_chunk:sub(e)
  local fx_subchunks = table.concat(fx_chain.fxs) -- full fx-subchunks
  local fx_subchunks_noPE, nrepl = fx_subchunks:gsub("<PROGRAMENV %d+ %d+\n.->", "") -- without PROGRAMENV
  --------
  local track_chunk_noPE = chunk_start .. fx_subchunks_noPE .. chunk_end -- track_chunk without PROGRAMENV
  track_chunk = chunk_start .. fx_subchunks .. chunk_end -- full track_chunk
  --------
  if nrepl == 0 then return SetTrackChunk(track, track_chunk)
  else return SetTrackChunk(track, track_chunk_noPE) and SetTrackChunk(track, track_chunk)
  end
end 

--==============================================================================
--------  Modify FXChain functions ---------------------------------------------
--==============================================================================
--[[
== Modify FXChain mini-description ===============
Эти функции являются простейшими операциями с таблицами.
Многое сюда может быть добавлено и упростит задачи в дальнейшем.
По идее, их можно было не писать, а действовать конкретно по ситуации, но так гораздо удобнее.
Все операции с чанками должны быть безошибочными - в таком виде легче тестировать и ловить косяки.
----
NOTE: idx for ALL functions 1-based(it's Lua!) !!!!!!!
--]]

--------------------------------------------------
-- Get fx(fx_chunk), return fx_chunk  ------------
function FXChain.GetFXChunk(fx_chain, idx)
  return fx_chain.fxs[idx]
end

--------------------------------------------------
-- Set fx_chunk(from fx_chunk) -------------------
function FXChain.SetFXChunk(fx_chain, fx_chunk, idx)
  fx_chain.fxs[idx] = fx_chunk
end

--------------------------------------------------
-- Insert fx(from fx_chunk) to pos = idx ---------
function FXChain.InsertFXFromChunk(fx_chain, fx_chunk, idx)
  table.insert(fx_chain.fxs, idx, fx_chunk)
end

--------------------------------------------------
-- Remove fxs from first_idx to last_idx inclusive
--[[
Если last_idx не указан, last_idx = first_idx.
Если first_idx не указан, first_idx = #fx_chain.fxs(последний в цепи).
Если last_idx указан, first_idx должен быть указан.
На практике - FXChain.RemoveFX(fx_chain) - удаляет последний FX.
FXChain.RemoveFX(fx_chain, first_idx) - удаляет один FX - first_idx.
Это удобно, принцип примерно как в ф-ях Lua.
--]] 
function FXChain.RemoveFX(fx_chain, first_idx, last_idx)
  first_idx = first_idx or #fx_chain.fxs
  last_idx = last_idx or first_idx
  for i = first_idx, last_idx do
    table.remove(fx_chain.fxs, first_idx)
  end
end

--------------------------------------------------
-- Move fx = src_idx to new position = dest_idx --
-- idx-s must be idx >= 1, idx <= #fx_chain.fxs --
function FXChain.MoveFX(fx_chain, src_idx, dest_idx)
  table.insert(fx_chain.fxs, dest_idx, table.remove(fx_chain.fxs, src_idx))
end

--------------------------------------------------
-- Copy fx = src_idx to new position = dest_idx --
-- idx-s must be idx >= 1, idx <= #fx_chain.fxs + 1
function FXChain.CopyFX(fx_chain, src_idx, dest_idx)
  local fx_chunk = fx_chain.fxs[src_idx]
  fx_chunk = fx_chunk:gsub("FXID {%x+%-%x+%-%x+%-%x+%-%x+}", "FXID " .. reaper.genGuid(""), 1) -- New FXID
  table.insert(fx_chain.fxs, dest_idx, fx_chunk)
end

--------------------------------------------------
-- Exchange fxs idx1 <> idx2(меняет местами) -----
function FXChain.ExchangeFX(fx_chain, idx1, idx2)
  fx_chain.fxs[idx1], fx_chain.fxs[idx2] = 
  fx_chain.fxs[idx2], fx_chain.fxs[idx1]
end


--=================================================
return FXChain




