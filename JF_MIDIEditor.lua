  -- get the package path to MIDIUtils in my repository
package.path = reaper.GetResourcePath() .. '/Scripts/sockmonkey72 Scripts/MIDI/?.lua'
local mu = require 'MIDIUtils'

  -- true by default, enabling argument type-checking, turn off for 'production' code
-- mu.ENFORCE_ARGS = false -- or use mu.MIDI_InitializeTake(), see below

  -- enable overlap correction
mu.CORRECT_OVERLAPS = true
  -- by default, note-ons take precedence when calculating overlap correction
  -- turn this on to favor selected notes' note-off instead
-- mu.CORRECT_OVERLAPS_FAVOR_SELECTION = true

  -- return early if something is missing (currently no dependencies)
if not mu.CheckDependencies('My Script') then return end


function debug_printStack()
  local str = ""
  for x=2, math.huge do
    if debug.getinfo(x) == nil then
      break
      end
    local name = debug.getinfo(x).name
    if name ~= nil then
      str = str .. name .. ": "
      end
    str = str .. debug.getinfo(x).currentline .. "\n"
    end
  reaper.ShowConsoleMsg(str .. "-----" .. "\n")
  end
  
function dummyButton(ctx, length, height)
  reaper.ImGui_PushID(ctx, 1)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0)
  reaper.ImGui_Button(ctx, "", length, height)
  reaper.ImGui_PopStyleColor(ctx, 3)
  reaper.ImGui_PopID(ctx)
  end

function boolToNumber(val)
  if val == true then
    return 1
    end
  return 0
  end

function numberToBool(val)
  if val == 1 then
    return true
    end
  return false
  end
  
function flip(val)
  if type(val) == "table" then
    for x=1, getTableLen(val) do
      val[x] = flip(val[x])
      end
    end
  if type(val) == "number" then
    val = math.abs(val-1)
    end
  if type(val) == "boolean" then
    if val then
      val = false
    else
      val = true
      end
    end
  
  return val
  end
  
function getTableLen(table)
  if table == nil or tonumber(table) then
    debug_printStack()
    end
  local counter = 0
  for index in pairs(table) do
    counter = counter + 1
    end
  return counter
  end
  
function hexColor(r, g, b, a) --optional a
  if a == nil then
    a = 255
    end
  
  local function formatToHex(num)
    num = math.floor(num)
    num = string.format("%x", num)
    if string.len(num) == 1 then
      num = "0" .. num
      end
    return num
    end
  
  local strTable = {}
  table.insert(strTable, "0x")
  table.insert(strTable, formatToHex(r))
  table.insert(strTable, formatToHex(g))
  table.insert(strTable, formatToHex(b))
  table.insert(strTable, formatToHex(a))
  local str = table.concat(strTable)
  
  return tonumber(str)
  end

function removeTrailingZeroes(num)
  local i = string.find(num, ".")
  if i ~= nil then
    local index = string.len(num)
    while string.sub(num, index, index) == "0" do
      num = string.sub(num, 1, index-1)
      if string.sub(num, index-1, index-1) == "." then
        num = string.sub(num, 1, index-2)
        break
        end
      end
    end
  
  return tonumber(num)
  end
  
function getTime()
  if reaper.GetPlayState()&1 == 1 then
    return reaper.GetPlayPosition()
    end
  return reaper.GetCursorPosition()
  end

function getTimeSelection()
  local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, "", "", false)
  return timeSelStart, timeSelEnd
  end

function setTimeSelection(timeStart, timeEnd)
  reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false)
  end

function beatsToTime(measure, beats)
  return reaper.TimeMap2_beatsToTime(0, beats-1, measure-1)
  end

function preserveWidget(ctx, begVal, endVal)
  reaper.ImGui_TextColored(ctx, WHITE, "Preserve audio items starting ")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, 20)
  local retval, text = reaper.ImGui_InputText(ctx, "##BEG", begVal)
  if retval then
    if text == "" then
      text = 0
      end
    if tonumber(text) then
      text = tonumber(text)
      if text >= 0 then
        begVal = tonumber(text)
        end
      end
    end
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextColored(ctx, WHITE, "seconds or less before cursor")
  
  reaper.ImGui_TextColored(ctx, WHITE, "Preserve audio items stopping ")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, 20)
  local retval, text = reaper.ImGui_InputText(ctx, "##END", endVal)
  if retval then
    if text == "" then
      text = 0
      end
    if tonumber(text) then
      text = tonumber(text)
      if text >= 0 then
        endVal = tonumber(text)
        end
      end
    end
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_TextColored(ctx, WHITE, "seconds or less after cursor")
  
  return begVal, endVal
  end

function glueMIDIWidget(ctx, glueMIDIVal)
  if reaper.ImGui_Checkbox(ctx, "Glue MIDI items?", glueMIDIVal) then
    glueMIDIVal = flip(glueMIDIVal)
    end
  return glueMIDIVal
  end

function separateString(str)
  if str == nil then
    debug_printStack()
    end
    
  local list = {}
  while true do
    local i
    local quotes = (string.sub(str, 1, 1) == "\"")
    if quotes then
      i = string.find(str, "\" ")
    else
      i = string.find(str, " ")
      end
    if i == nil then
      local value = str
      if string.sub(value, 1, 1) == "\"" then
        value = string.sub(value, 2, string.len(value)-1)
        end
      table.insert(list, value)
      return list
    else
      local value = string.sub(str, 1, i-1)
      if string.sub(value, 1, 1) == "\"" then
        value = string.sub(value, 2, string.len(value))
        end
      table.insert(list, value)
      if quotes then
        i = i + 1 --hopefully this works
        end
      str = string.sub(str, i+1, string.len(str))
      end
    end
  end

function getMidiViewAndHZoom(midiEditor)
  if not midiEditor then return end
  
  local midiview = reaper.JS_Window_FindChildByID( midiEditor, 0x3E9 )
  local _, width = reaper.JS_Window_GetClientSize( midiview )
  local take =  reaper.MIDIEditor_GetTake( midiEditor )
  local guid = reaper.BR_GetMediaItemTakeGUID( take )
  local item =  reaper.GetMediaItemTake_Item( take )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local guidfound, editviewfound = false, false
  local leftmost_tick, hzoom, timebase
  
  local function setvalue(a)
    a = tonumber(a)
    if not leftmost_tick then leftmost_tick = a
    elseif not hzoom then hzoom = a
    else timebase = a
      end
    end
    
  for line in chunk:gmatch("[^\n]+") do
    if line == "GUID " .. guid then
      guidfound = true
      end
    if (not editviewfound) and guidfound then
      if line:find("CFGEDITVIEW ") then
        line:gsub("([%-%d%.]+)", setvalue, 2)
        editviewfound = true
        end
      end
    if editviewfound then
      if line:find("CFGEDIT ") then
        line:gsub("([%-%d%.]+)", setvalue, 19)
        break
        end
      end
    end
    
  local start_time, end_time, HZoom = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick)
  if timebase == 0 or timebase == 4 then
    end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + (width-1)/hzoom)
  else
    end_time = start_time + (width-1)/hzoom
    end
  HZoom = (width)/(end_time - start_time)
  return start_time, end_time, HZoom
  end

function convertRange(val, oldMin, oldMax, newMin, newMax)
  return ( (val - oldMin) / (oldMax - oldMin) ) * (newMax - newMin) + newMin
  end

function getDirectory()
  local dir = reaper.GetResourcePath() .. "\\JF_MIDIEditor\\"
  --reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getImageDirectory()
  local dir = getDirectory() .. "Images\\"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getTuningDirectory()
  local dir = getDirectory() .. "Tunings\\"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end
  
function getMIDIEditorFileName()
  local dir = getDirectory()
  local fileName = dir .. "settings.txt"
  local file = io.open(fileName, "r")
  if file == nil then
    file = io.open(fileName, "w+")
    file:write("")
    file:close()
    file = io.open(fileName, "r")
    end
  file:close()
  return fileName
  end
  
function getMIDIEditorFileText()
  local fileName = getMIDIEditorFileName()
  local file = io.open(fileName, "r")
  local fileText = file:read("*all")
  return fileText
  end
  
function getMIDIEditorSetting(label)
  local function getDefaultSetting()
    if label == "VIEWMODE" then
      return 0
      end
    end 
    
  local labelLen = string.len(label)
  local fileText = getMIDIEditorFileText()
  for line in fileText:gmatch("[^\r\n]+") do
    if string.sub(line, 1, labelLen+1) == label .. " " then
      return tonumber(string.sub(line, labelLen+2, string.len(line)))
      end
    end
  
  local val = getDefaultSetting()
  setMIDIEditorSetting(label, val)
  return val
  end

function setMIDIEditorSetting(label, val)
  local strTable = {}
  local labelLen = string.len(label)
  local fileText = getMIDIEditorFileText()
  for line in fileText:gmatch("[^\r\n]+") do
    if string.sub(line, 1, labelLen+1) ~= label .. " " then
      table.insert(strTable, line)
      end
    end
  table.insert(strTable, label .. " " .. val)
  
  local fileName = getMIDIEditorFileName()
  local file = io.open(fileName, "w+")
  file:write(table.concat(strTable, "\n"))
  file:close()
  end

function round(num)
  local change = 10^5
  return math.floor((num*change+0.5))/change
  end
  
function timeToBeats(time) --measure, beats, timeSigNum, timeSigDenom
  local quarterNote = reaper.TimeMap_timeToQN(time)
  local measure = reaper.TimeMap_QNToMeasures(0, quarterNote) - 1
  local measureStartTime, quarterNoteStart, quarterNoteEnd, timeSigNum, timeSigDenom, tempo = reaper.TimeMap_GetMeasureInfo(proj, measure)
  local numQuarterNotes = (timeSigNum/(timeSigDenom/4))
  local beats = (quarterNote - quarterNoteStart) * timeSigDenom/4 + 1
  
  return math.floor(round(measure+1)), round(beats), timeSigNum, timeSigDenom
  end

function pitchToCents(pitch)
  return pitch * 100
  end

function centsToPitch(cents)
  return math.floor(cents/100)
  end

function getTuningFile(guid) --returs fileText, name
  local dir = getTuningDirectory()
  local fileIndex = 0
  while true do
    local fileName = reaper.EnumerateFiles(dir, fileIndex)
    if not fileName then
      break
      end
    
    local file = io.open(dir .. fileName, "r")
    local line = file:read()
    file:close()
    if line == guid then
      local file = io.open(dir .. fileName, "r")
      local fileText = file:read("*all")
      file:close()
      
      local name = string.sub(fileName, string.len(dir)+1, string.len(fileName)-4)
      return fileText, name
      end
      
    fileIndex = fileIndex + 1
    end
  end

function getLabel(line)
  local i = string.find(line, " ")
  if i == nil then
    return line
    end
  return string.sub(line, 1, i-1)
  end

function getValue(line)
  local i = string.find(line, " ")
  if i == nil then
    return nil
    end
  return string.sub(line, i+1, string.len(line))
  end
  
function getTuningData(guid) --returns name, colorScheme, pitchList, loopSize
  local colorScheme
  local pitchList = {}
  local loopSize
  
  local fileText, name = getTuningFile(guid)
  for line in fileText:gmatch("[^\r\n]+") do
    local label = getLabel(line)
    local value = getValue(line)
    if label == "COLORSCHEME" then
      colorScheme = separateString(value)
      for x=1, getTableLen(colorScheme) do
        colorScheme[x] = tonumber(colorScheme[x])
        end
      end
      
    if tonumber(label) then
      local values = separateString(line)
      for x=1, getTableLen(values) do
        if tonumber(values[x]) then
          values[x] = tonumber(values[x])
          end
        end
      loopSize = values[1]
      table.insert(pitchList, values)
      end
    end
    
  return name, colorScheme, pitchList, loopSize
  end
  
----------------

local openedMidiEditor = 2

local global_focusedText
local midiEditor
local pitchWindowSize
local timeWindowSize

local currentMouseCentsDrag, currentMouseTimeDrag, currentMousePPQPOSDrag
local originalMouseCents, originalMouseTime

--constants
local BLACK = hexColor(0, 0, 0)
local WHITE = hexColor(255, 255, 255)
local YELLOW = hexColor(255, 255, 0)
local HORIZONTAL = 0
local VERTICAL = 1
local tag = "JFMIDIEDITOR_"

local DEFAULTGUID = "{3C40C761-F3E7-4663-939B-01323167E23E}" --12-TET tuning
local DEFAULTCENTS = 4800 --C4

local MINCENTS = 0
local MAXCENTS = 12800

local STRETCHSTARTOFNOTES = 0
local STRETCHENDOFNOTES = 1
local DRAGNOTES = 2

local noteMovement

local toolbarHeight = 20
local settingsHeight = 40
local measureHeight = 55

local editedViewMode = false

local mouseCursor = 0

local regionPitchStart, regionTimeStart

local hoveringStartEdgeNoteID, hoveringEndEdgeNoteID

local backgroundCentsList
local snapCentsList

---image functions---

function toggleSnap()
  reaper.MIDIEditor_OnCommand(midiEditor, 1014)
  end

function toggleViewMode()
  local label = "VIEWMODE"
  viewMode = getMIDIEditorSetting(label)
  setMIDIEditorSetting(label, flip(viewMode))
  
  local pos = getPitchScrollbarPos()
  local size = getPitchScrollbarSize()
  setPitchScrollbarPos(1-(pos+size))
  --reaper.ShowConsoleMsg(pos .. " -> " .. 1-(pos+size) .."\n")
    
  local pos = getTimeScrollbarPos()
  local size = getTimeScrollbarSize()
  setTimeScrollbarPos(1-(pos+size))
  
  editedViewMode = true
  end
  
---define images---
  
local imgList = {}

function defineImage(fileName, func, ...)
  local img0 = reaper.ImGui_CreateImage(getImageDirectory() .. fileName  .. "0.png")
  local img1 = reaper.ImGui_CreateImage(getImageDirectory() .. fileName  .. "1.png")
  table.insert(imgList, {fileName, img0, img1, func, ...})
  end

function getImageFromList(fileName)
  for _, v in ipairs(imgList) do
    if v[1] == fileName then
      return table.unpack(v, 2)
      end
    end
  end
  
defineImage("viewMode", toggleViewMode)
defineImage("snap", toggleSnap)

---define hotkeys---

local hotkeyList = {}

function defineHotkey(commandID, key, ctrl, shift, alt)
  table.insert(hotkeyList, {commandID, key, ctrl, shift, alt})
  end

defineHotkey(40016, reaper.ImGui_Key_Space(), false, false, false) --play/stop

defineHotkey(40010, reaper.ImGui_Key_C(), true, false, false) --copy
defineHotkey(40011, reaper.ImGui_Key_V(), true, false, false) --paste
defineHotkey(40012, reaper.ImGui_Key_X(), true, false, false) --cut

defineHotkey(40013, reaper.ImGui_Key_Z(), true, false, false) --undo
defineHotkey(40014, reaper.ImGui_Key_Z(), true, true, false) --redo

defineHotkey(40006, reaper.ImGui_Key_A(), true, false, false) --select all
defineHotkey(40667, reaper.ImGui_Key_Delete(), false, false, false) --delete
defineHotkey(40046, reaper.ImGui_Key_S(), false, false, false) --split

----------------

function runGUI(ctx, windowID)
  reaper.ImGui_SetMouseCursor(ctx, mouseCursor)
  
  local drawList = reaper.ImGui_GetWindowDrawList(ctx)
  
  if openedMidiEditor == 2 then
    openedMidiEditor = 0
    end
  
  if editedViewMode then
    openedMidiEditor = 0
    editedViewMode = false
    end
    
  local take = reaper.MIDIEditor_GetTake(midiEditor)
  local mediaItem = reaper.GetMediaItemTake_Item(take)
  local retval, chunk = reaper.GetItemStateChunk(mediaItem, "", false)
  
  local snapEnabled = numberToBool(reaper.MIDIEditor_GetSetting_int(midiEditor, "snap_enabled"))
  
  function setTextEvent(label, val)
    reaper.PreventUIRefresh(1)
    
    if val == 0 then
      --debug_printStack()
      end
      
    local msgLabel = tag .. label .. " "
    local len = string.len(msgLabel)
    local x = 0
    while true do
      local retval, selected, muted, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(take, x)
      if not retval then
        reaper.MIDI_InsertTextSysexEvt(take, false, false, reaper.MIDI_GetPPQPosFromProjTime(take, 0), 1, msgLabel .. val)
        break
        end
      
      if evtType == 1 and string.sub(msg, 1, len) == msgLabel then
        reaper.MIDI_DeleteTextSysexEvt(take, x)
        reaper.MIDI_InsertTextSysexEvt(take, false, false, reaper.MIDI_GetPPQPosFromProjTime(take, 0), 1, msgLabel .. val)
        break
        end
      x = x + 1
      end
    
    reaper.PreventUIRefresh(-1)
    end
    
  function getTextEvent(label, default)
    local msgLabel = tag .. label .. " "
    local len = string.len(msgLabel)
    local x = 0
    while true do
      local retval, selected, muted, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(take, x)
      if not retval then
        setTextEvent(label, default)
        return default
        end
      
      if evtType == 1 and string.sub(msg, 1, len) == msgLabel then
        local val = string.sub(msg, len+1, string.len(msg))
        if tonumber(val) then
          val = tonumber(val)
          end
        return val
        end
      x = x + 1
      end
    end
  
  function getProgramPitchBendDown()
    return getTextEvent("pitchbend0", 0)
    end
  
  function setProgramPitchBendDown(semitones)
    setTextEvent("pitchbend0", semitones)
    end
  
  function getProgramPitchBendUp()
    return getTextEvent("pitchbend1", 0)
    end
  
  function setProgramPitchBendUp(semitones)
    setTextEvent("pitchbend1", semitones)
    end
    
  --user settings
  local viewMode = getMIDIEditorSetting("VIEWMODE")
  local autoscrollSetting = numberToBool(getTextEvent("AUTOSCROLL" .. viewMode, 0))
  
  --mouse states
  local mouseLeftClicked = reaper.ImGui_IsMouseClicked(ctx, 0)
  local mouseRightClicked = reaper.ImGui_IsMouseClicked(ctx, 1)
  local mouseLeftDoubleClicked = reaper.ImGui_IsMouseDoubleClicked(ctx, 0)
  local mouseRightDoubleClicked = reaper.ImGui_IsMouseDoubleClicked(ctx, 0)
  local mouseLeftReleased = reaper.ImGui_IsMouseReleased(ctx, 0)
  local mouseRightReleased = reaper.ImGui_IsMouseReleased(ctx, 1)
  local leftMouseDown = (reaper.JS_Mouse_GetState(1) & 1 == 1)
  local rightMouseDown = (reaper.JS_Mouse_GetState(2) & 2 == 2)
  local ctrlDown = (reaper.JS_Mouse_GetState(4) & 4 == 4)
  local shiftDown = (reaper.JS_Mouse_GetState(8) & 8 == 8)
  local altDown = (reaper.JS_Mouse_GetState(16) & 16 == 16)
  local mouseX, mouseY = reaper.ImGui_GetMousePos(ctx)
    
  --REAPER states
  local playing = (reaper.GetPlayState()&1 == 1)
  
  local centsRangeStart = pitchToCents(0)
  local centsRangeEnd = pitchToCents(128)
  local visibleStartCents, visibleEndCents
  
  local timeRangeStart, timeRangeEnd
  local visibleStartTime, visibleEndTime, visibleStartPPQPOS, visibleEndPPQPOS
  
  local measureNumbersTable = {}
  
  local executeMotion
  
  local programPitchBendDown = getProgramPitchBendDown()
  local programPitchBendUp = getProgramPitchBendUp()
  local isValidProgramPitchBend = (programPitchBendDown > 0 and programPitchBendUp > 0)
  
  --[[
  -define dimensions of REAPER's MIDI editor (used to overlay our editor over REAPER's)
  -never referenced again after defining window dimensions!
  --]]
  local midiEditor_xMin, midiEditor_yMin, midiEditor_xMax, midiEditor_yMax
  local envelopeHeight = 0
  local numCCEnvelopes = 0
  
  for line in chunk:gmatch("[^\r\n]+") do
    if string.sub(line, 1, 8) == "CFGEDIT " then
      local values = separateString(line)
      local conversionFactor = 1.2495

      midiEditor_xMin = tonumber(values[14]) / conversionFactor + 7
      midiEditor_yMin = tonumber(values[15]) / conversionFactor
      midiEditor_xMax = tonumber(values[16]) / conversionFactor - 7
      midiEditor_yMax = tonumber(values[17]) / conversionFactor - 7

      --crop
      midiEditor_xMin = midiEditor_xMin
      midiEditor_yMin = midiEditor_yMin + 80
      midiEditor_xMax = midiEditor_xMax
      midiEditor_yMax = midiEditor_yMax - 13
      end
      
    if string.sub(line, 1, 8) == "VELLANE " then
      local values = separateString(line)
      envelopeHeight = envelopeHeight + tonumber(values[3])
      numCCEnvelopes = numCCEnvelopes + 1
      end
    end
  envelopeHeight = envelopeHeight * 0.8 + numCCEnvelopes*7
  
  if midiEditor_xMin > midiEditor_xMax or midiEditor_yMin > midiEditor_yMax then
    --some seemingly random crashes when resizing?
  else
    --define dimensions of entire window
    local window_xMin, window_yMin, window_xMax, window_yMax
    local windowSizeX, windowSizeY
    
    window_xMin = midiEditor_xMin
    window_yMin = midiEditor_yMin
    window_xMax = midiEditor_xMax
    window_yMax = midiEditor_yMax-envelopeHeight
    
    windowSizeX = window_xMax-window_xMin
    windowSizeY = window_yMax-window_yMin
    
    local toolbar_xMin, toolbar_yMin, toolbar_xMax, toolbar_yMax
    toolbar_xMin = window_xMin
    toolbar_yMin = window_yMin
    toolbar_xMax = window_xMax
    toolbar_yMax = toolbar_yMin + toolbarHeight
    
    local settings_xMin, settings_yMin, settings_xMax, settings_yMax
    settings_xMin = window_xMin
    settings_yMin = toolbar_yMax
    settings_xMax = window_xMax
    settings_yMax = settings_yMin + settingsHeight
    
    --define dimensions of just the editable note window
    local noteEditor_xMin, noteEditor_yMin, noteEditor_xMax, noteEditor_yMax
    
    if viewMode == HORIZONTAL then
      noteEditor_xMin = window_xMin+60
      noteEditor_yMin = settings_yMax + measureHeight
      noteEditor_xMax = window_xMax - 19
      if isValidProgramPitchBend then
        noteEditor_yMax = window_yMax - 16
      else
        noteEditor_yMax = noteEditor_yMin
        end
    else
      noteEditor_xMin = window_xMin+60
      noteEditor_yMin = window_yMin
      if isValidProgramPitchBend then
        noteEditor_xMax = window_xMax - 17
      else
        noteEditor_xMax = noteEditor_xMin
        end
      noteEditor_yMax = window_yMax-40 
      end
    
    function getNotePitchBend(noteID)
      --local _, val = mu.MIDI_GetCCValueAtTime(take, 176, 0, 11, time)
      end
    
    function setNotePitchBend(noteID, val)
      
      end
      
    function processHotkeys()
      for x=1, getTableLen(hotkeyList) do
        local data = hotkeyList[x]
        
        local commandID = data[1]
        local key = data[2]
        local ctrl = data[3]
        local shift = data[4]
        local alt = data[5]
        
        if reaper.ImGui_IsKeyPressed(ctx, key) and ctrl == ctrlDown and shift == shiftDown and alt == altDown then
          reaper.MIDIEditor_OnCommand(midiEditor, commandID)
          end
        end
      end
      
    function mousePositionInRect(x1, y1, x2, y2)
      local xMin = math.min(x1, x2)
      local xMax = math.max(x1, x2)
      local yMin = math.min(y1, y2)
      local yMax = math.max(y1, y2)
      return mouseX >= xMin and mouseX <= xMax and mouseY >= yMin and mouseY <= yMax
      end
    
    local hoveringNoteEditor = mousePositionInRect(noteEditor_xMin, noteEditor_yMin, noteEditor_xMax, noteEditor_yMax)
    
    function drawBackground(xMin, yMin, xMax, yMax, color)
      reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, color)
      end
      
    function getXYCoor(pitchMin, pitchMax, timeMin, timeMax)
      local xMin, yMin, xMax, yMax
      if viewMode == HORIZONTAL then
        xMin = timeMin
        yMin = pitchMin
        xMax = timeMax
        yMax = pitchMax
      else
        xMin = pitchMin
        yMin = timeMin
        xMax = pitchMax
        yMax = timeMax
        end
      return xMin, yMin, xMax, yMax
      end
    
    --[[
    define window position coordinates (x, y):
      HORIZONTAL VIEW: (time, pitch)
      VERTICAL VIEW: (pitch, time)
    ]]--
    local windowPos_pitchMin, windowPos_pitchMax, windowPos_timeMin, windowPos_timeMax
    if viewMode == HORIZONTAL then
      windowPos_pitchMin, windowPos_timeMin, windowPos_pitchMax, windowPos_timeMax = getXYCoor(noteEditor_xMin, noteEditor_xMax, noteEditor_yMin, noteEditor_yMax)
    else
      windowPos_pitchMin, windowPos_timeMin, windowPos_pitchMax, windowPos_timeMax = getXYCoor(noteEditor_xMin, noteEditor_xMax, noteEditor_yMin, noteEditor_yMax)
      end
    
    function getBackgroundTuningGUID()
      return getTextEvent("tuning0", DEFAULTGUID)
      end
    
    function setBackgroundTuningGUID(guid)
      setTextEvent("tuning0", guid)
      end
    
    function getSnapTuningGUID()
      return getTextEvent("tuning1", DEFAULTGUID)
      end
    
    function setSnapTuningGUID(guid)
      setTextEvent("tuning1", guid)
      end
    
    function getBackgroundBaseCents()
      return getTextEvent("basecents0", DEFAULTCENTS)
      end
    
    function setBackgroundBaseCents(cents)
      setTextEvent("basecents0", cents)
      end
    
    function getSnapBaseCents()
      return getTextEvent("basecents1", DEFAULTCENTS)
      end
    
    function setSnapBaseCents(cents)
      setTextEvent("basecents1", cents)
      end
      
    function setPitchScrollbarPos(val)
      local scrollbarSize = getPitchScrollbarSize()
      
      local scrollbarPosPixels = pitchWindowSize*val
      local scrollbarSizePixels = pitchWindowSize*scrollbarSize
      if scrollbarPosPixels + scrollbarSizePixels > pitchWindowSize then
        scrollbarPosPixels = pitchWindowSize - scrollbarSizePixels
        val = scrollbarPosPixels/pitchWindowSize
        end
      
      if val > 1 then
        val = 0
        end
      if val < 0 then
        val = 0
        end
        
      setTextEvent("pitchscrollbarpos", val)
      end
      
    function getPitchScrollbarPos()
      return getTextEvent("pitchscrollbarpos", 0)
      end
      
    function setPitchScrollbarSize(val)
      local scrollbarPos = getPitchScrollbarPos()
      
      local scrollbarPosPixels = pitchWindowSize*scrollbarPos
      local scrollbarSizePixels = pitchWindowSize*val
      if scrollbarPosPixels + scrollbarSizePixels > pitchWindowSize then
        scrollbarSizePixels = pitchWindowSize - scrollbarPosPixels
        val = scrollbarSizePixels/pitchWindowSize
        end
      
      if val + scrollbarPos > 1 then
        val = 1 - scrollbarPos
        end
      if val < 0.01 then
        val = 0.01
        end
        
      setTextEvent("pitchscrollbarsize", val)
      end
      
    function getPitchScrollbarSize()
      return getTextEvent("pitchscrollbarsize", 0.25)
      end
    
    function setTimeScrollbarPos(val)
      local scrollbarSize = getTimeScrollbarSize()
      
      local scrollbarPosPixels = timeWindowSize*val
      local scrollbarSizePixels = timeWindowSize*scrollbarSize
      if scrollbarPosPixels + scrollbarSizePixels > timeWindowSize then
        scrollbarPosPixels = timeWindowSize - scrollbarSizePixels
        val = scrollbarPosPixels/timeWindowSize
        end
      
      if val > 1 then
        val = 0
        end
      if val < 0 then
        val = 0
        end
        
      setTextEvent("timescrollbarpos", val)
      end
      
    function getTimeScrollbarPos()
      return getTextEvent("timescrollbarpos", 0)
      end
      
    function setTimeScrollbarSize(val)
      local scrollbarPos = getTimeScrollbarPos()
        
      local scrollbarPosPixels = timeWindowSize*scrollbarPos
      local scrollbarSizePixels = timeWindowSize*val
      if scrollbarPosPixels + scrollbarSizePixels > timeWindowSize then
        scrollbarSizePixels = timeWindowSize - scrollbarPosPixels
        val = scrollbarSizePixels/timeWindowSize
        end
      
      if val + scrollbarPos > 1 then
        val = 1 - scrollbarPos
        end
      if val < 0.01 then
        val = 0.01
        end
        
      setTextEvent("timescrollbarsize", val)
      end
      
    function getTimeScrollbarSize()
      return getTextEvent("timescrollbarsize", 0.25)
      end

    local scrollbarSize = getPitchScrollbarSize()
    local scrollbarPos = getPitchScrollbarPos()
    local startPos = scrollbarPos
    local endPos = scrollbarPos + scrollbarSize
    local pitchSize = convertRange(2/128, startPos, endPos, windowPos_pitchMin, windowPos_pitchMax) - convertRange(1/128, startPos, endPos, windowPos_pitchMin, windowPos_pitchMax)

    function refreshZOrder(hwnd)
      local retval, text = reaper.BR_Win32_GetWindowText(midiEditor)
      local retval, focusedText = reaper.BR_Win32_GetWindowText(reaper.JS_Window_GetFocus())
      if (focusedText == "midiview" or focusedText == "midipianoview") and global_focusedText ~= focusedText then
        reaper.JS_Window_SetZOrder(midiEditor, "INSERTAFTER", hwnd)
        end
      global_focusedText = focusedText
      end
    
    function centsToWindowPos(cents)
      local min
      local max
      if viewMode == VERTICAL then
        min = windowPos_pitchMin
        max = windowPos_pitchMax
      else
        min = windowPos_pitchMax
        max = windowPos_pitchMin
        end
      return convertRange(cents, visibleStartCents, visibleEndCents, min, max)
      end
    
    function windowPosToCents(windowPos)
      local min
      local max
      if viewMode == VERTICAL then
        min = windowPos_pitchMin
        max = windowPos_pitchMax
      else
        min = windowPos_pitchMax
        max = windowPos_pitchMin
        end
      return convertRange(windowPos, min, max, visibleStartCents, visibleEndCents)
      end
      
    function timeToWindowPos(time)
      local min
      local max
      if viewMode == HORIZONTAL then
        min = windowPos_timeMin
        max = windowPos_timeMax
      else
        min = windowPos_timeMax
        max = windowPos_timeMin
        end
      return convertRange(time, visibleStartTime, visibleEndTime, min, max)
      end
    
    function windowPosToTime(windowPos)
      local min
      local max
      if viewMode == HORIZONTAL then
        min = windowPos_timeMin
        max = windowPos_timeMax
      else
        min = windowPos_timeMax
        max = windowPos_timeMin
        end
      return convertRange(windowPos, min, max, visibleStartTime, visibleEndTime)
      end
    
    function pitchToWindowPos(pitch)
      return centsToWindowPos(pitchToCents(pitch))
      end
    
    function getHoveredPitch()
      for pitch=0, 127 do
        local condition
        if viewMode == HORIZONTAL then
          condition = pitchToWindowPos(pitch+1) <= mouseY
        else
          condition = pitchToWindowPos(pitch+1) >= mouseX
          end
        if condition then
          return pitch
          end
        end
      end
    
    function getHoveredTime()
      if viewMode == HORIZONTAL then
        return windowPosToTime(mouseX)
        end
      return windowPosToTime(mouseY)
      end
      
    function addSizeButton()
      local pitchScrollbarPos = getPitchScrollbarPos()
      local timeScrollbarPos = getTimeScrollbarPos()
      
      --reaper.ShowConsoleMsg(pitchScrollbarPos .. " " .. timeScrollbarPos .. "\n")
      
      local width, height
      if viewMode == HORIZONTAL then
        width = timeWindowSize
        height = pitchWindowSize
      else
        width = pitchWindowSize
        height = timeWindowSize
        end
      --reaper.ShowConsoleMsg(width .. ", " .. height .. "\n")
      reaper.ImGui_PushID(ctx, 1)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), BLACK)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), BLACK)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), BLACK)
      reaper.ImGui_Button(ctx, "##size button", width, height)
      reaper.ImGui_PopStyleColor(ctx, 3)
      reaper.ImGui_PopID(ctx)
      end
      
    function addScrollbars()
      local function getCoor(isVertical)
        local xMin, yMin, xMax, yMax
        if isVertical then
          xMin = window_xMax-13
          yMin = window_yMin
          xMax = xMin+10
          yMax = window_yMax
        else
          xMin = window_xMin
          yMin = window_yMax-13
          xMax = window_xMax
          yMax = yMin+10
          end
        return xMin, yMin, xMax, yMax
        end
      local function getScroll(isVertical)
        if isVertical then
          return reaper.ImGui_GetScrollY(ctx)
        else
          return reaper.ImGui_GetScrollX(ctx)
          end
        end
      local function setScroll(isVertical, val)
        if isVertical then
          reaper.ImGui_SetScrollY(ctx, val)
        else
          reaper.ImGui_SetScrollX(ctx, val)
          end
        end
      local function getMouseModifier(isVertical)
        if isVertical then
          return ctrlDown
        else
          return altDown
          end
        end
    
      local function pitchScrollbar(isVertical)
        local scrollbarSize = getPitchScrollbarSize()
        local scrollbarPos = getPitchScrollbarPos()
        
        local percentage
        if viewMode == VERTICAL then
          percentage = scrollbarPos
        else
          percentage = 1-scrollbarPos-scrollbarSize
          end
        visibleStartCents = convertRange(percentage, 0, 1, centsRangeStart, centsRangeEnd)
        local percentage
        if viewMode == VERTICAL then
          percentage = scrollbarPos+scrollbarSize
        else
          percentage = 1-scrollbarPos
          end
        visibleEndCents = convertRange(percentage, 0, 1, centsRangeStart, centsRangeEnd)

        if viewMode == HORIZONTAL then
          pitchWindowSize = (windowSizeY)/scrollbarSize
        else
          pitchWindowSize = (windowSizeX)/scrollbarSize --?? (works)
          end
        local scrollStored = math.floor(pitchWindowSize*scrollbarPos+0.5)
        
        if openedMidiEditor == 0 then
          setScroll(isVertical, scrollStored)
          end
        
        scroll = getScroll(isVertical)
        
        --reaper.ShowConsoleMsg(scrollStored .. " " .. scroll .. " " .. boolToNumber(isVertical) .. "\n")
        if openedMidiEditor == 1 then
          if getMouseModifier(isVertical) then
            local wheel = reaper.ImGui_GetMouseWheel(ctx)
            if wheel ~= 0 then
              scrollbarSize = scrollbarSize + wheel/100
              setPitchScrollbarSize(scrollbarSize)
              setScroll(isVertical, scrollStored) --depends
              end
          else
            if scroll ~= scrollStored then
              --reaper.ShowConsoleMsg(scroll .. " ~= " .. scrollStored .. " " .. pitchWindowSize .. "\n")
              setPitchScrollbarPos(scroll/pitchWindowSize)
              end
            end
          
          if viewMode == HORIZONTAL then
            pitchWindowSize = (windowSizeY)/scrollbarSize
          else
            pitchWindowSize = (windowSizeX)/scrollbarSize --?? (works)
            end
          end
        end
        
      local function timeScrollbar(isVertical)
        local scrollbarSize = getTimeScrollbarSize()
        local scrollbarPos = getTimeScrollbarPos()
        
        timeRangeStart = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
        timeRangeEnd = timeRangeStart + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
        
        if playing and autoscrollSetting then
          visibleStartTime = getTime()
          setTimeScrollbarPos(convertRange(visibleStartTime, timeRangeStart, timeRangeEnd, 0, 1))
        else
          local percentage
          if viewMode == HORIZONTAL then
            percentage = scrollbarPos
          else
            percentage = 1-scrollbarPos-scrollbarSize
            end
          visibleStartTime = convertRange(percentage, 0, 1, timeRangeStart, timeRangeEnd)
          end
        local percentage
        if viewMode == HORIZONTAL then
          percentage = scrollbarPos+scrollbarSize
        else
          percentage = 1-scrollbarPos
          end
        visibleEndTime = convertRange(percentage, 0, 1, timeRangeStart, timeRangeEnd)
        visibleStartPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, visibleStartTime)
        visibleEndPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, visibleEndTime)
        
        --reaper.ShowConsoleMsg(scrollbarPos .. " " .. visibleStartTime .. " " .. visibleEndTime .. "\n")
        
        if viewMode == HORIZONTAL then
          timeWindowSize = (windowSizeX)/scrollbarSize
        else
          timeWindowSize = (windowSizeY)/scrollbarSize
          end
        local scrollStored = math.floor(timeWindowSize*scrollbarPos+0.5)
          
        if openedMidiEditor == 0 then
          setScroll(isVertical, scrollStored)
          end
        
        scroll = getScroll(isVertical)
                      
        if openedMidiEditor == 1 then
          if getMouseModifier(isVertical) then
            local wheel = reaper.ImGui_GetMouseWheel(ctx)
            if wheel ~= 0 then
              scrollbarSize = scrollbarSize + wheel/100
              setTimeScrollbarSize(scrollbarSize)
              setScroll(isVertical, scrollStored)
              end
          else
            if scroll ~= scrollStored and not (playing and autoscrollSetting) then
              setTimeScrollbarPos(scroll/timeWindowSize)
              end
            end
          
          if viewMode == HORIZONTAL then
            timeWindowSize = (windowSizeX)/scrollbarSize
          else
            timeWindowSize = (windowSizeY)/scrollbarSize
            end
          end
        end
      
      pitchScrollbar(viewMode==0)
      timeScrollbar(viewMode==1)
      end
      
    function drawToolbar()
      drawBackground(toolbar_xMin, toolbar_yMin, toolbar_xMax, settings_yMax, BLACK)
      if viewMode == HORIZONTAL then
        drawBackground(toolbar_xMin, toolbar_yMin, noteEditor_xMin, noteEditor_yMin, BLACK)
        end
      
      for x=1, getTableLen(imgList) do
        local imgName = imgList[x][1]
        local imgOff, imgOn, imgFunc = getImageFromList(imgName)
        
        
        local isImageOn
        
        if imgName == "snap" then
          isImageOn = snapEnabled
          end
        if imgName == "viewMode" then
          isImageOn = numberToBool(viewMode)
          end
        
        --[[
        local img
        if isImageOn then
          img = imgOn
        else
          img = imgOff
          end
        --]]
        
        local img = imgOn
        
        local yMin = toolbar_yMin
        local yMax = yMin + (toolbar_yMax-toolbar_yMin)
        local xMin = toolbar_xMin + (toolbar_yMax-toolbar_yMin+5)*(x-1)
        local xMax = xMin + (yMax-yMin)
        
        local tintColor
        if isImageOn then
          tintColor = YELLOW
        else
          tintColor = hexColor(128, 128, 128)
          end
         
        reaper.ImGui_DrawList_AddImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
        
        if mousePositionInRect(xMin, yMin, xMax, yMax) then
          if mouseLeftClicked then
            imgFunc()
            end
          end
        end
      
      --[[
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Checkbox(ctx, "Autoscroll?", autoscrollSetting) then
        autoscrollSetting = flip(autoscrollSetting)
        setTextEvent("AUTOSCROLL" .. viewMode, boolToNumber(autoscrollSetting))
        end
      --]]
      end
      
    function drawPitchGridLines()
      local scrollbarSize = getPitchScrollbarSize()
      local scrollbarPos = getPitchScrollbarPos()
      
      local startPos, endPos
      if viewMode == HORIZONTAL then
        startPos = scrollbarPos
        endPos = scrollbarPos + scrollbarSize
      else
        startPos = scrollbarPos + scrollbarSize
        endPos = scrollbarPos
        end
      
      local rectColor = hexColor(255, 255, 255, 255)
      
      local bgTuningGUID = getBackgroundTuningGUID()
      local name, colorScheme, pitchList, loopSize = getTuningData(bgTuningGUID)
      local baseCents = getBackgroundBaseCents()
      
      local centsAtLoopPoint = loopSize
      while centsAtLoopPoint > MINCENTS do
        centsAtLoopPoint = centsAtLoopPoint - loopSize
        end
      
      backgroundCentsList = {}
      
      while centsAtLoopPoint < MAXCENTS do
        for x=1, getTableLen(pitchList) do
          local data = pitchList[x]
          local name = data[2]
          local colorID = data[3]
          local color = colorScheme[colorID+1] --include full alpha
          
          local centsMin
          if x == 1 then
            centsMin = centsAtLoopPoint
          else
            centsMin = pitchList[x-1][1] + centsAtLoopPoint
            end
          local centsMax = pitchList[x][1] + centsAtLoopPoint
          
          local pitchPosMin = centsToWindowPos(centsMin)
          local pitchPosMax = centsToWindowPos(centsMax)
          
          table.insert(backgroundCentsList, {pitchPosMin, pitchPosMax, name})
          
          local xMin, yMin, xMax, yMax
          if viewMode == HORIZONTAL then
            xMin = windowPos_timeMin 
            yMin = pitchPosMax
            xMax = windowPos_timeMax
            yMax = pitchPosMin
          else
            xMin = pitchPosMin
            yMin = windowPos_timeMin
            xMax = pitchPosMax
            yMax = windowPos_timeMax
            end
          
          local r, g, b = reaper.ColorFromNative(color)

          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, hexColor(r, g, b))
          
          reaper.ImGui_DrawList_AddLine(drawList, xMin, pitchPosMin, xMax, pitchPosMin, hexColor(230, 230, 230))
          end
        
        centsAtLoopPoint = centsAtLoopPoint + loopSize
        end
      end
      
    function drawTimeGridLines()
      local posBeg = reaper.MIDI_GetPPQPos_StartOfMeasure(take, visibleStartPPQPOS)
      local posEnd = reaper.MIDI_GetPPQPos_EndOfMeasure(take, visibleEndPPQPOS)

      local qnBeg = reaper.MIDI_GetProjQNFromPPQPos(take, posBeg)
      local qnEnd = reaper.MIDI_GetProjQNFromPPQPos(take, posEnd)
      
      local startPos, endPos, endOfFirstMeasurePos
      if viewMode == HORIZONTAL then
        startPos = timeToWindowPos(reaper.TimeMap_QNToTime(qnBeg))
        endPos = timeToWindowPos(reaper.TimeMap_QNToTime(qnBeg+1))
      else
        endPos = timeToWindowPos(reaper.TimeMap_QNToTime(qnBeg))
        startPos = timeToWindowPos(reaper.TimeMap_QNToTime(qnBeg+1))
        end
      
      local grid, swing = reaper.MIDI_GetGrid(take)
      
      local qnWindowSize = endPos-startPos
      
      local gridDivision = grid
      local i = 0
      while qnWindowSize*gridDivision < 25 do --time lines no closer than 25 pixels apart
        gridDivision = gridDivision * 2
        
        if i == 10 then
          break
          end
        i = i + 1
        end
      
      local thickLineColor = hexColor(140, 140, 140)
      local thinLineColor = hexColor(200, 200, 200)
      local thickness = 1
      local showText
      for qn=qnBeg, qnEnd, gridDivision do
        local time = reaper.TimeMap_QNToTime(qn)
        local pos = timeToWindowPos(time)
        local xMin, yMin, xMax, yMax = getXYCoor(windowPos_pitchMin, windowPos_pitchMax, pos, pos)
        local measure, beats, num, denom = timeToBeats(time)
        
        local color
        local num, denom, tempo = reaper.TimeMap_GetTimeSigAtTime(0, time)
        
        if beats*(denom/4) % 1 == 0 then
          color = thickLineColor
        else
          color = thinLineColor
          end
          
        reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMax, color, thickness)
        
        if beats == 1 then
          showText = true
        else
          showText = flip(showText)
          end
        if showText then
          table.insert(measureNumbersTable, {xMin, yMin, xMax, yMax, color, thickness, measure, beats, num, denom})
          end
        end
      end
    
    function drawMeasureNumbers()
      local xMin, yMin, xMax, yMax
      local top
      if viewMode == HORIZONTAL then
        xMin = noteEditor_xMin
        yMin = settings_yMax
        xMax = noteEditor_xMax
        yMax = noteEditor_yMin
        top = yMin
      else
        xMin = window_xMin
        yMin = settings_yMax
        xMax = noteEditor_xMin
        yMax = window_yMax
        top = xMin
        end
      
      drawBackground(xMin, yMin, xMax, yMax, hexColor(210, 210, 210))
      
      for x=xMin, xMax do
        local time = windowPosToTime(x)
        local _, val = mu.MIDI_GetCCValueAtTime(take, 176, 0, 11, time)
        
        local c = val*2
        local color = hexColor(c, c, 256-c)
        reaper.ImGui_DrawList_AddRectFilled(drawList, x, yMin, x+1, yMax, color)
        end
        
      for x=1, getTableLen(measureNumbersTable) do
        local data = measureNumbersTable[x]
        
        local xMin = data[1]
        local yMin = data[2]
        local xMax = data[3]
        local yMax = data[4]
        local lineColor = data[5]
        local thickness = data[6]
        local measure = data[7]
        local beats = removeTrailingZeroes(data[8])
        local num = data[9]
        local denom = data[10]
        
        local text
        
        if beats == 1 then
          text = measure
          local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, text, 0, 0)
          if viewMode == HORIZONTAL then
            reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, top, lineColor, thickness)
            reaper.ImGui_DrawList_AddText(drawList, xMin+5, top+12, BLACK, text)
          else
            reaper.ImGui_DrawList_AddLine(drawList, top, yMin, xMin, yMax, lineColor, thickness)
            reaper.ImGui_DrawList_AddText(drawList, xMin-textSizeX-5, yMin-15, BLACK, text) 
            end
        else
          text = measure .. "." .. beats
          local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, text, 0, 0)
          if viewMode == HORIZONTAL then
            reaper.ImGui_DrawList_AddText(drawList, xMin-(textSizeX/2), noteEditor_yMin-20, BLACK, text)
          else

            reaper.ImGui_DrawList_AddText(drawList, ((window_xMin+noteEditor_xMin)/2)-(textSizeX/2)+4, yMin-(textSizeY/2), BLACK, text)
            end
          end
        end
      end
      
    function drawPlayCursor()
      local pos = timeToWindowPos(getTime())
      local xMin, yMin, xMax, yMax = getXYCoor(windowPos_pitchMin, windowPos_pitchMax, pos, pos)
      reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMax, hexColor(255, 0, 0), thickness)
      end
      
    function drawTimeSelection() --TODO FIX
      local timeSelStart, timeSelEnd = getTimeSelection()
      if timeSelEnd > 0 then
        local xMin = timeToWindowPos(timeSelStart)
        if xMin == nil then
          xMin = windowPos_timeMin
          end
        local xMax = timeToWindowPos(timeSelEnd)
        if xMin < windowPos_timeMax and xMax ~= nil and xMax > windowPos_timeMin then
          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, window_yMin, xMax, window_yMax, 934834834989)
          end
        end
      end
    
    function getNoteName(pitch)
      local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
      
      local letter = noteNames[pitch%12 + 1]
      local octave = math.floor(pitch/12) - 1
      
      return letter .. octave
      end
    
    function drawNoteNames()
      local desiredDelta
      if viewMode == HORIZONTAL then
        reaper.ImGui_DrawList_AddRectFilled(drawList, window_xMin, noteEditor_yMin, noteEditor_xMin, window_yMax, BLACK)
        desiredDelta = 15
      else
        reaper.ImGui_DrawList_AddRectFilled(drawList, window_xMin, noteEditor_yMax, window_xMax, window_yMax, BLACK)
        desiredDelta = 25
        end
      
      local delta
      local prevPos
      local currentPos
      
      for x=1, getTableLen(backgroundCentsList) do
        local data = backgroundCentsList[x]
        local pitchPosMin = data[1]
        local pitchPosMax = data[2]
        local noteName = data[3]
        
        local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, noteName, 0, 0)
        
        local rectSizePitch = pitchPosMax-pitchPosMin
        local xPos, yPos
        if viewMode == HORIZONTAL then
          xPos = noteEditor_xMin-textSizeX-8
          yPos = pitchPosMin+(rectSizePitch - textSizeY)/2
          currentPos = yPos
        else
          xPos = pitchPosMin+(rectSizePitch - textSizeX)/2
          yPos = windowPos_timeMax + 5
          currentPos = xPos
          end
        
        local function add()
          reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, WHITE, noteName)
          end
          
        if delta == nil then
          delta = 0
          prevPos = currentPos
          add()
        else
          delta = math.abs(currentPos - prevPos)
          if delta > desiredDelta then
            prevPos = currentPos
            add()
            end
          end
        end
      
      if viewMode == VERTICAL then
        drawBackground(window_xMin, noteEditor_yMax, noteEditor_xMin, window_yMax, BLACK)
        end
      end
      
    function drawAndHandleNotes()
      --calculate drag
      if mouseLeftClicked then
        if viewMode == HORIZONTAL then
          originalMouseTime = windowPosToTime(mouseX)
          originalMouseCents = windowPosToCents(mouseY)
        else
          originalMouseCents = windowPosToCents(mouseX)
          originalMouseTime = windowPosToTime(mouseY)
          end
        end
      if originalMouseCents ~= nil then
        if viewMode == HORIZONTAL then
          currentMouseCentsDrag = windowPosToCents(mouseY) - originalMouseCents
          currentMouseTimeDrag = windowPosToTime(mouseX) - originalMouseTime
        else
          currentMouseCentsDrag = windowPosToCents(mouseX) - originalMouseCents
          currentMouseTimeDrag = windowPosToTime(mouseY) - originalMouseTime
          end
        currentMousePPQPOSDrag = reaper.MIDI_GetPPQPosFromProjTime(take, currentMouseTimeDrag)
        end
      
      local noteTable = {}
      
      local clickedAnyNote
      local noteIDToDelete
      local foundEdge = false  
      local selectedNoteCount = 0
      
      executeMotion = (noteMovement ~= nil and mouseLeftReleased)
      if executeMotion then
        reaper.Undo_BeginBlock2(0)
        end
      
      --check for pitch bend values attached to notes, add default if not
      local noteID = 0
      while true do
        local retval, selected, muted, noteStartPPQPOS, noteEndPPQPOS, chan, pitch, vel = reaper.MIDI_GetNote(take, noteID)
        if not retval then
          break
          end
        
        local noteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
        
        --reaper.ShowConsoleMsg(
        noteID = noteID + 1
        end
      
      local noteID = 0
      while true do
        local retval, selected, muted, noteStartPPQPOS, noteEndPPQPOS, chan, pitch, vel = reaper.MIDI_GetNote(take, noteID)
        if not retval then
          break
          end
        
        --animate/execute dragging
        if noteMovement ~= nil then
          if noteMovement == STRETCHSTARTOFNOTES and (selected or hoveringStartEdgeNoteID == noteID) then
            noteStartPPQPOS = noteStartPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              noteStartPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)))
              end
            end
          if noteMovement == STRETCHENDOFNOTES and (selected or hoveringEndEdgeNoteID == noteID) then
            noteEndPPQPOS = noteEndPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              noteEndPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, reaper.MIDI_GetProjTimeFromPPQPos(take, noteEndPPQPOS)))
              end
            end
          if noteMovement == DRAGNOTES and selected then
            noteStartPPQPOS = noteStartPPQPOS + currentMousePPQPOSDrag
            noteEndPPQPOS = noteEndPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              local time = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
              reaper.ShowConsoleMsg(time - reaper.SnapToGrid(0, time) .. "\n")
              
              local originalPPQPOS = noteStartPPQPOS
              noteStartPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)))
              noteEndPPQPOS = noteEndPPQPOS + (noteStartPPQPOS - originalPPQPOS)
              end
            pitch = centsToPitch(pitchToCents(pitch) + currentMouseCentsDrag)
            end
          
          if mouseLeftReleased then
            reaper.MIDI_SetNote(take, noteID, nil, nil, noteStartPPQPOS, noteEndPPQPOS, nil, pitch, nil, true)
            end
          end
        
        local noteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
        local noteEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, noteEndPPQPOS)
        
        local noteStartTimePos, noteEndTimePos
        if viewMode == HORIZONTAL then
          noteStartTimePos = timeToWindowPos(noteStartTime)
          noteEndTimePos = timeToWindowPos(noteEndTime)
        else
          noteStartTimePos = timeToWindowPos(noteEndTime)
          noteEndTimePos = timeToWindowPos(noteStartTime)
          end
        local notePitchPosMin = pitchToWindowPos(pitch)
        local notePitchPosMax = pitchToWindowPos(pitch+1)
        
        local pitchBend = getNotePitchBend(noteID)
        
        local color
        local alpha = 175
        if selected then
          color = hexColor(255, 40, 255, alpha)
        else
          color = hexColor(255, 40, 60, alpha)
          end
        
        --draw note
        local xMin, yMin, xMax, yMax = getXYCoor(notePitchPosMin, notePitchPosMax, noteStartTimePos, noteEndTimePos)
        if viewMode == HORIZONTAL then
          yMax = yMax + 1
          end
        reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, color)

        local hoveringNote = mousePositionInRect(xMin, yMin, xMax, yMax)
        
        local err = 8
        if viewMode == HORIZONTAL then
          if mousePositionInRect(xMin, yMin, xMin+err, yMax) then
            hoveringStartEdgeNoteID = noteID
            hoveringEndEdgeNoteID = nil
            foundEdge = true
            end
          if mousePositionInRect(xMax-err, yMin, xMax, yMax) then
            hoveringStartEdgeNoteID = nil
            hoveringEndEdgeNoteID = noteID
            foundEdge = true
            end
        else
          if mousePositionInRect(xMin, yMax-err, xMax, yMax) then
            hoveringStartEdgeNoteID = noteID
            hoveringEndEdgeNoteID = nil
            foundEdge = true
            end
          if mousePositionInRect(xMin, yMin, xMax, yMin+err) then
            hoveringStartEdgeNoteID = nil
            hoveringEndEdgeNoteID = noteID
            foundEdge = true
            end
          end
          
        if mouseLeftClicked then
          if hoveringStartEdgeNoteID then
            noteMovement = STRETCHSTARTOFNOTES
            end
          if hoveringEndEdgeNoteID then
            noteMovement = STRETCHENDOFNOTES
            end
          if hoveringNote and noteMovement == nil then
            noteMovement = DRAGNOTES
            mouseCursor = 0
            end
          end
        
        if hoveringStartEdgeNoteID or hoveringEndEdgeNoteID or noteMovement == STRETCHSTARTOFNOTES or noteMovement == STRETCHENDOFNOTES then
          if viewMode == HORIZONTAL then
            mouseCursor = reaper.ImGui_MouseCursor_ResizeEW()
          else
            mouseCursor = reaper.ImGui_MouseCursor_ResizeNS()
            end
        else
          mouseCursor = 0
          end
          
        if mouseLeftReleased and reaper.ImGui_GetMouseCursor(ctx) ~= 0 then
          mouseCursor = 0
          end
          
        table.insert(noteTable, {xMin, yMin, xMax, yMax, noteStartPPQPOS, noteEndPPQPOS, noteStartTime, noteEndTime, color, pitch, selected, hoveringNote})
        
        if selected then
          selectedNoteCount = selectedNoteCount + 1
          end
          
        noteID = noteID + 1
        end
      
      if executeMotion then
        reaper.MIDI_Sort(take)
        
        noteMovement = nil
        
        originalMouseCents = nil
        originalMouseTime = nil
        currentMouseCentsDrag = nil
        currentMouseTimeDrag = nil
        
        reaper.Undo_EndBlock2(0, "JF_move_notes", -1) --FIX
        end
      
      if not foundEdge and noteMovement == nil then
        hoveringStartEdgeNoteID = nil
        hoveringEndEdgeNoteID = nil
        end
        
      for noteID=0, getTableLen(noteTable)-1 do
        local data = noteTable[noteID+1]
        
        --define values
        local xMin = data[1]
        local yMin = data[2]
        local xMax = data[3]
        local yMax = data[4]
        local noteStartPPQPOS = data[5]
        local noteEndPPQPOS = data[6]
        local noteStartTime = data[7]
        local noteEndTime = data[8]
        local color = data[9]
        local pitch = data[10]
        local selected = data[11]
        local hoveringNote = data[12]
        
        --draw black border around note
        reaper.ImGui_DrawList_AddRect(drawList, xMin, yMin, xMax, yMax, BLACK, nil, nil, 1)
        
        --draw text inside note
        local noteName = getNoteName(pitch)
        local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, noteName, 0, 0)
        local rectSizeX = xMax-xMin
        local rectSizeY = yMax-yMin
        local xPos, yPos
        if viewMode == HORIZONTAL then
          xPos = xMin+3
          yPos = yMin+(rectSizeY - textSizeY)/2
        else
          xPos = xMin+(rectSizeX - textSizeX)/2 + 1 --extra 1 seems to help center the text
          yPos = yMin+(rectSizeY - textSizeY)/2
          end
        local color
        if selected then
          color = BLACK
        else
          color = WHITE
          end
        reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, color, noteName)
        
        --handle clicking inside note editor
        if mouseLeftClicked and hoveringNoteEditor then
          if hoveringNote then
            if mouseLeftDoubleClicked then
              noteIDToDelete = noteID
            else
              selected = true
              reaper.MIDI_SetNote(take, noteID, selected)
              clickedAnyNote = true
              end
          else
            if not ctrlDown and selected and selectedNoteCount > 0 then
              --reaper.MIDI_SetNote(take, noteID, false)
              end
            end
          end
        
        --handle releasing inside note editor
        if mouseLeftReleased and hoveringNoteEditor then
          if selectedNoteCount > 0 then
            --[[
            selected = true
            reaper.MIDI_SetNote(take, noteID, selected)
            clickedAnyNote = true
            end
            --]]
            if hoveringNote then
              reaper.MIDI_SetNote(take, noteID, true)
            elseif not ctrlDown and selectedNoteCount > 0 then
              reaper.MIDI_SetNote(take, noteID, false)
              end
            end
          end
        end
        
      --handle double clicking inside note editor
      if mouseLeftDoubleClicked and hoveringNoteEditor then
        if noteIDToDelete == nil then
          local startTime = getTime()
          if snapEnabled then
            time = reaper.SnapToGrid(0, startTime)
            end
          local grid, swing = reaper.MIDI_GetGrid(take)
          local endTime = startTime + reaper.TimeMap_QNToTime(grid)
          reaper.MIDI_InsertNote(take, true, false, reaper.MIDI_GetPPQPosFromProjTime(take, startTime), reaper.MIDI_GetPPQPosFromProjTime(take, endTime), 0, getHoveredPitch(), 127)
        else
          reaper.MIDI_DeleteNote(take, noteIDToDelete)
          end
        end
      
      --set edit cursor position
      if mouseLeftClicked and not clickedAnyNote and hoveringNoteEditor then
        local time
        if viewMode == HORIZONTAL then
          time = windowPosToTime(mouseX)
        else
          time = windowPosToTime(mouseY)
          end
        if snapEnabled then
          time = reaper.SnapToGrid(0, time)
          end
        reaper.SetEditCurPos(time, false, false)
        end
      end
    
    function drawRegion()
      if mouseRightClicked and hoveringNoteEditor then
        regionPitchStart = getHoveredPitch()
        regionTimeStart = getHoveredTime()
        end
      
      local hoveredPitch = getHoveredPitch()
      local hoveredTime = getHoveredTime()
      if regionPitchStart ~= nil then
        local window_pitch1 = pitchToWindowPos(regionPitchStart)
        local window_pitch2 = pitchToWindowPos(hoveredPitch)
        local window_time1 = timeToWindowPos(regionTimeStart)
        local window_time2 = timeToWindowPos(hoveredTime)
        
        local xMin, yMin, xMax, yMax
        if viewMode == HORIZONTAL then
          xMin = math.min(window_time1, window_time2)
          xMax = math.max(window_time1, window_time2)
          yMin = math.min(window_pitch1, window_pitch2)
          yMax = math.max(window_pitch1, window_pitch2)
        else
          xMin = math.min(window_pitch1, window_pitch2)
          xMax = math.max(window_pitch1, window_pitch2)
          yMin = math.min(window_time1, window_time2)
          yMax = math.max(window_time1, window_time2)
          end
        
        if xMin < noteEditor_xMin then
          xMin = noteEditor_xMin
          end
        if yMin < noteEditor_yMin then
          yMin = noteEditor_yMin
          end
        if xMax > noteEditor_xMax then
          xMax = noteEditor_xMax
          end
        if yMax > noteEditor_yMax then
          yMax = noteEditor_yMax
          end
        reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, hexColor(255, 255, 0, 64))
        
        if not rightMouseDown then
          local pitchMin = math.min(regionPitchStart, hoveredPitch)
          local pitchMax = math.max(regionPitchStart, hoveredPitch)
          local timeMin = math.min(regionTimeStart, hoveredTime)
          local timeMax = math.max(regionTimeStart, hoveredTime)
          
          local noteID = 0
          while true do
            local retval, selected, muted, noteStartPPQPOS, noteEndPPQPOS, chan, pitch, vel = reaper.MIDI_GetNote(take, noteID)
            if not retval then
              break
              end
            
            local noteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
            local noteEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, noteEndPPQPOS)
            
            local condition
            if noteEndTime < noteStartTime then
              condition = (noteStartTime <= timeMax and noteEndTime >= timeMin and pitch >= pitchMin and pitch <= pitchMax)
            else
              condition = (noteStartTime >= timeMin and noteStartTime <= timeMax and noteEndTime >= timeMin and noteEndTime <= timeMax and pitch >= pitchMin and pitch <= pitchMax)
              end
            local selected = condition
            reaper.MIDI_SetNote(take, noteID, selected)
            
            noteID = noteID + 1
            end
            
          regionPitchStart = nil
          regionTimeStart = nil
          end
        end
      end
    
    processHotkeys()
    
    reaper.ImGui_SetNextWindowSize(ctx, windowSizeX, windowSizeY)
    reaper.ImGui_SetNextWindowPos(ctx, window_xMin, window_yMin)
    
    local windowTitle = "MIDI Editor"
    local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, reaper.ImGui_WindowFlags_NoScrollWithMouse()+reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()+reaper.ImGui_WindowFlags_AlwaysVerticalScrollbar()+reaper.ImGui_WindowFlags_NoDecoration())
    if visible then
      local imgui_hwnd = reaper.JS_Window_Find(windowTitle, true)
      refreshZOrder(imgui_hwnd)
        
      addScrollbars(ctx)
      
      addSizeButton()
              
      drawBackground(window_xMin, window_yMin, window_xMax, window_yMax, hexColor(210, 210, 210))
      
      drawPitchGridLines()
      
      drawTimeGridLines()
      
      drawAndHandleNotes()
             
      drawPlayCursor()
      
      drawTimeSelection()
      
      drawMeasureNumbers()
      
      drawNoteNames()
      
      drawRegion()
      
      drawToolbar()
      
      reaper.ImGui_End(ctx)
      end
    
    reaper.ImGui_SetNextWindowSize(ctx, settings_xMax-settings_xMin, settings_yMax-settings_yMin)
    reaper.ImGui_SetNextWindowPos(ctx, settings_xMin, settings_yMin)

    local windowTitle = "Settings"
    local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, reaper.ImGui_WindowFlags_NoBackground()+reaper.ImGui_WindowFlags_TopMost()+reaper.ImGui_WindowFlags_NoFocusOnAppearing()+reaper.ImGui_WindowFlags_NoScrollWithMouse()+reaper.ImGui_WindowFlags_NoDecoration())
    if visible then
      --local imgui_hwnd = reaper.JS_Window_Find(windowTitle, true)
      --refreshZOrder(imgui_hwnd)
      
      reaper.ImGui_SetNextItemWidth(ctx, 40)
      if reaper.ImGui_BeginCombo(ctx, "Select tuning...##" .. windowID, "") then
        
        reaper.ImGui_EndCombo(ctx)
        end
      
      --program pitch bend
      reaper.ImGui_SetNextItemWidth(ctx, 30)
      reaper.ImGui_SameLine(ctx)
      local display
      if programPitchBendDown == 0 then
        display = ""
      else
        display = "-" .. programPitchBendDown
        end
      local retval, text = reaper.ImGui_InputText(ctx, "PB Down##" .. windowID, display)
      if retval then
        local semitones
        if tonumber(text) then
          semitones = math.floor(math.abs(tonumber(text)))
        else
          semitones = 0
          end
        setProgramPitchBendDown(semitones)
        end
      reaper.ImGui_SetNextItemWidth(ctx, 30)
      reaper.ImGui_SameLine(ctx)
      local display
      if programPitchBendUp == 0 then
        display = ""
      else
        display = "+" .. programPitchBendUp
        end
      local retval, text = reaper.ImGui_InputText(ctx, "PB Up##" .. windowID, display)
      if retval then
        local semitones
        if tonumber(text) then
          semitones = math.floor(math.abs(tonumber(text)))
        else
          semitones = 0
          end
        setProgramPitchBendUp(semitones)
        end
        
      reaper.ImGui_End(ctx)
      end
    end
  
  if openedMidiEditor == 0 then
    openedMidiEditor = 1
    end

  end

----------------

local ctx = reaper.ImGui_CreateContext("MIDI Editor")

function loop()
  midiEditor = reaper.MIDIEditor_GetActive()
  if midiEditor ~= nil and reaper.MIDIEditor_GetSetting_int(midiEditor, "list_cnt") == 0 then
    
    --[[
    (TEST, printing midi chunk...)
    
    local editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then
      local take = reaper.MIDIEditor_GetTake(editor)
      local mediaItem = reaper.GetMediaItemTake_Item(take)
      local retval, chunk = reaper.GetItemStateChunk(mediaItem, "", false)
      reaper.ShowConsoleMsg(chunk)
      end
    --]]
    
    --ctx = reaper.ImGui_CreateContext("MIDI Editor")
    runGUI(ctx, 0)
    end
  reaper.defer(loop)
  end

loop()
