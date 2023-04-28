debug_initialTime = nil
debug_recentTime = nil
debug_list = {}

local backgroundModified
local snapModified

local mouseX = 1000000 --dummy
local mouseY = 1000000 --dummy

local noteIDToDrawPoints
local adjustBezierNoteID
local adjustBezierTime
local adjustBezierCents

local global_pointCCTypes = {
{"Pitch Bend", nil},
{"Note H", "noteH"},
{"Note S", "noteS"},
{"Note V", "noteV"},
{"Note Size", "noteSize"},
{"Note Alpha", "noteAlpha"}
}
      
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

function debug_funcTime(str)
  if true or str ~= nil and str ~= "end" then
    return
    end
    
  local function getFuncInitialTime()
    return debug_initialTime
    end
    
  local function getFuncList()
    return debug_list
    end
  
  if (str ~= nil and getFuncInitialTime() == nil) then
    return
    end
  
  local percentageThreshold = 3
   
  if str == nil then
    debug_initialTime = reaper.time_precise()
    debug_recentTime = debug_initialTime
    debug_list = {}
    end
    
  local timeDifference = reaper.time_precise() - debug_recentTime
  debug_recentTime = reaper.time_precise()
    
  local added = false
  for x=1, getTableLen(debug_list) do
    if debug_list[x][1] == str then
      added = true
      debug_list[x][2] = debug_list[x][2] + timeDifference
      break
      end
    end
    
  if not added then
    if str == nil then
      str = ""
      end
    table.insert(debug_list, {str, timeDifference})
    end
  
  if str == "end" then
    local strTable = {string.upper("Runtime") .. ":"}
    
    local totalTime = reaper.time_precise()-getFuncInitialTime()
    
    --sort
    local list = {}
    for x=1, getTableLen(getFuncList()) do
      local data = getFuncList()[x]
      local val = data[2]
      local inserted = false
      for x=getTableLen(list), 1, -1 do
        if val > list[x][2] then
          table.insert(list, x+1, data)
          inserted = true
          break
          end
        end
      if not inserted then
        table.insert(list, 1, data)
        end
      end
      
    for x=getTableLen(list), 1, -1 do
      local str = list[x][1]
      local time = list[x][2]
      local percentage = math.floor((time/totalTime)*1000)/10
      if percentage < percentageThreshold then
        break
        end
      table.insert(strTable, str .. ": " .. time .. " (" .. percentage .. "%)")
      end
    
    table.insert(strTable, "")
    table.insert(strTable, "Total Time: " .. totalTime)
    table.insert(strTable, "-------------")
    reaper.ShowConsoleMsg(table.concat(strTable, "\n"))
    
    debug_initialTime = nil
    end
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

function isInTable(t, data) --returns bool, id
  for x=1, getTableLen(t) do
    local testData = t[x]
    if type(testData) == "table" then
      testData = t[x][1]
      end
    if testData == data then
      return true, x
      end
    end
  return false
  end
  
function alphabetToNumber(letter)
  local ascii = string.byte(string.upper(letter))
  return ascii - 64
  end

function numberToAlphabet(num)
  local letter = string.char(num+64)
  return letter
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
    local testCount = 0
    while string.sub(num, index, index) == "0" do
      num = string.sub(num, 1, index-1)
      if string.sub(num, index-1, index-1) == "." then
        num = string.sub(num, 1, index-2)
        break
        end
      
      testCount = testCount + 1
      if testCount > 100 then
        debug_printStack()
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

function removeExtraDecimalZeroes(num)
  num = round(num, 3)
  
  local numStr = tostring(num)
  local i = string.find(num, "%.")
  if i ~= nil then
    for charID=string.len(numStr), i, -1 do
      local testChar = string.sub(numStr, charID, charID)
      if testChar == "." then
        numStr = string.sub(numStr, 1, string.len(numStr)-1)
        break
        end
      if testChar ~= "0" then
        break
        end
      numStr = string.sub(numStr, 1, string.len(numStr)-1)
      end
    end
  
  return numStr
  end

function noQuotes(str)
  return (string.find(str, '["\']') == nil)
  end
  
function separateString(str)
  if str == nil then
    debug_printStack()
    end
    
  local list = {}
  local testCount = 0
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
    
    testCount = testCount + 1
    if testCount > 100 then
      debug_printStack()
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

function getAutogeneratedTuningsDirectory()
  local dir = getTuningDirectory() .. "Autogenerated Tunings\\"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end
  
function getTempDirectory()
  local dir = getDirectory() .. "temp\\"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function clearTempDirectory()
  local dir = getTempDirectory()
  
  reaper.EnumerateFiles(dir, -1)
  
  local fileIndex = 0
  local testCount = 0
  while true do
    local fileName = reaper.EnumerateFiles(dir, fileIndex)
    if not fileName then
      break
      end

    local filePath = dir .. fileName
    os.remove(filePath)
      
    fileIndex = fileIndex + 1
    
    testCount = testCount + 1
    if testCount > 100 then
      debug_printStack()
      end
    end
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
    return 0
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

function round(num, exp)
  if exp == nil then
    exp = 5
    end
  local change = 10^exp
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
  
function getTuningList() --returs fileText, name
  local list = {}
  local dir = getTuningDirectory()
  local fileIndex = 0
  local testCount = 0
  while true do
    local fileName = reaper.EnumerateFiles(dir, fileIndex)
    if not fileName then
      break
      end
    
    local name = string.sub(fileName, 1, string.find(fileName, "%.")-1)
    table.insert(list, {name, fileIndex})
    
    fileIndex = fileIndex + 1
    
    testCount = testCount + 1
    if testCount > 100 then
      debug_printStack()
      end
    end
  return list
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

function getTuningGUID(isSnap)
  return getTextEvent("tuning" .. math.floor(boolToNumber(isSnap)), DEFAULTGUID)
  end

local testTable = {{"A", -6}, {"B", -4} }

for x=1, getTableLen(testTable) do
  if testTable[x][1] == gensbelow then
    return testTable[x][2]
    end
  end

function getEDOValue(fileText)
  local _, _, pitchList, loopSize = getTuningData(fileText)
  
  local centsSizeToCheck
  for pitchID=1, getTableLen(pitchList) do
    local centsSize = pitchList[pitchID][1]
    if pitchID == 1 then
      centsSizeToCheck = centsSize
    else
      if centsSize ~= centsSizeToCheck then
        return
        end
      end
    end
  
  return loopSize, getTableLen(pitchList)
  end
  
function centsToHz(cents)
  local referenceHz = 8.1757989156 -- Hz value of C-1
  local hz = referenceHz * (2 ^ (cents / 1200))
  return round(hz, 2)  
  end

function hzToCents(hz)
  local referenceHz = 8.1757989156 -- Hz value of C-1
  local cents = 1200 * (math.log(hz / referenceHz) / math.log(2))
  return round(cents, 2) 
  end

function getFraction(input, tolerance)
  if math.floor(input) == input then
    return math.floor(input) .. "/1"
    end
  
  if tolerance == nil then
    tolerance = 3
    end
    
  local h1=1
  local h2=0
  local k1=0
  local k2=1
  local b = input;
  local testCount = 0
  
  while math.abs(1200*math.log(math.abs(input/(h1/k1)))/math.log(2)) > tolerance or testCount < 2 do
    local a = math.floor(b)
    local aux = h1
    h1 = a*h1+h2
    h2 = aux
    aux = k1
    k1 = a*k1+k2
    k2 = aux
    b = 1/(b-a)
    
    testCount = testCount + 1
    
    if testCount > 100 then
      debug_printStack()
      end
    end
  
  return h1 .. "/" .. k1
  end

function fractionToDecimal(str)
  local i = string.find(str, "/")
  if i == nil then
    return tonumber(str)
    end
    
  local num = tonumber(string.sub(str, 1, i-1))
  local denom = tonumber(string.sub(str, i+1, string.len(str)))
  return num/denom
  end

function gcf(a, b)
  local testCount = 0
  while b ~= 0 do
    a, b = b, a % b
    
    testCount = testCount + 1
    if testCount > 100 then
      debug_printStack()
      end
    end
  return a
end

function getSuperscript(num)
  --[[
  local list = {"⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"}
  local val
  if list[num+1] ~= nil then
    val = list[num+1]
  else
    val = num
    end
  return val
  --]]
  
  return "(" .. num .. ")"
  end
  
function genscalemap(edo,genindex,gensbelow,tonicletter,smallestletter,wkeynumber,prdperedo,equave,shrpstr,fltstr,dblshrpstr,dblfltstr,edostepstr) --numgens, noteLetter, accidental, colorID
  local function sharptotext(x)
    if shrpstr == nil then
      --shrpstr = "♯"
      shrpstr = "#"
      end
    if fltstr == nil then
      --fltstr = "♭"
      fltstr = "b"
      end
    if dblshrpstr == nil then
      --dblshrpstr = "x"
      dblshrpstr = "x"
      end
    if dblfltstr == nil then
      --dblfltstr = "♭♭"
      dblfltstr = "bb"
      end
      
    local output=""
    if math.abs(x)>4 then
      local hdigit
      if math.abs(x)>=10 then
        hdigit=getSuperscript(math.floor((math.abs(x)%100)/10))
      else 
        hdigit=""
        end
      local tdigit=getSuperscript(math.floor((math.abs(x)%10)))
      if x>0 then
        output=shrpstr..hdigit..tdigit
      else
        output=fltstr..hdigit..tdigit
        end
    else
      if x%2==1 then
        if x>0 then
          output=shrpstr 
        else
          output=fltstr
          end
        end
      if x>1 then
        for y=1, math.floor(x/2) do
          output=output..dblshrpstr
          end
      elseif x<-1 then  
        for y=1, math.floor(x/-2) do
          output=output..dblfltstr
          end
        end
      end
    
    return output
    end
    
  --genindex is the 5th

  if gensbelow == nil then
    gensbelow = -1
    elseif tonumber(gensbelow)==nil then  --letters should only be used in a fifth generated, 7 note system
      gensbelow=(-1)*((2*alphabetToNumber(gensbelow)+2)%7)
      end
  if tonicletter == nil then
    tonicletter = "C"
    end
  if smallestletter == nil then
    smallestletter = "A"
    end
  if wkeynumber == nil then
    wkeynumber = 7
    end
  if prdperedo == nil then
    prdperedo = 1
    end
  if equave == nil then
    equave = 2
    else equave=fractionToDecimal(equave)
    end
  if edostepstr == nil then
    edostepstr = "^" 
    end
  
  --making a big indexed but empty set
  local resulttable={}
  for x=1, edo do
    table.insert(resulttable,"")
    end
    
  --giving resulttable its generator mappings
  local maxgenstack = math.floor(edo/gcf(genindex,edo))
  wkeynumber=math.min(wkeynumber,maxgenstack)
  local rings=math.ceil(maxgenstack/wkeynumber)
  local negativegens=math.floor( ((rings-1)*wkeynumber)/2)
  for stack=0, maxgenstack-1 do
    local index = (stack*genindex)%edo + 1
    local val = (stack-gensbelow+negativegens)%maxgenstack-negativegens
    resulttable[index]=val
    end
  
  --making a list with the number of sharps
  local numsharps = {}
  for x=1,edo do
    if tonumber(resulttable[x]) then
      table.insert(numsharps,math.floor(resulttable[x]/wkeynumber))
      else table.insert(numsharps,"")
      end
    end
    
 --assigning generator values to note names
  local gennames = {}
  for x=1,wkeynumber do
    table.insert(gennames,"")
    end
  local tonicnumber=alphabetToNumber(tonicletter)
  local letternamecount=0 
  local smallestletternumber=alphabetToNumber(smallestletter)
  for x=1,edo do
    if numsharps[x]==0 then
      letternamecount=letternamecount+1
      local wkeyalphabet= ( letternamecount+tonicnumber-2 )%wkeynumber+smallestletternumber-1
      gennames[resulttable[x]+1]=numberToAlphabet(wkeyalphabet+1)
      end
    end
  
  --assigning notenames to reachable notes
  for x=1,edo do
    if tonumber(resulttable[x])then
      local negoffset=0
      if numsharps[x]<0 then
        negoffset=1
        end
      colorID=math.abs(2*numsharps[x]+negoffset)*gcf(genindex,edo)
      resulttable[x]={
        resulttable[x],--the preexisting value from the table
        gennames[resulttable[x]%wkeynumber+1],--the letter name
        sharptotext(numsharps[x]), --the accidentals
        colorID,
        numsharps[x],
        0} --num arrows
    end
  end
  
  local lastworking
  local lastworkingindex
  for x=1,edo do
    if tonumber(resulttable[x][1])then
      lastworking=1
      lastworkingindex=x
      else
      local notename=resulttable[lastworkingindex][2]
      local noteaccidental=resulttable[lastworkingindex][3]
      local notecolor=resulttable[lastworkingindex][4]
      local sharpnum=resulttable[lastworkingindex][5]
      local arrowstring=""
      for y=1,lastworking do
        arrowstring=arrowstring..edostepstr
        end
      resulttable[x]={
          resulttable[lastworkingindex],
          notename,
          arrowstring..noteaccidental,
          notecolor+lastworking,
          sharpnum,
          lastworking}
      lastworking=lastworking+1
      end 
    end
    
  local str = ""
  for x=1, getTableLen(resulttable) do
    local data = resulttable[x]
    str = str .. data[2] .. data[3] .. " " .. data[4] .. "\n"
    end
  --reaper.ShowConsoleMsg(str .. "\n")
  
  table.insert(resulttable, {shrpstr,fltstr,dblshrpstr,dblfltstr,edostepstr})
  return resulttable
  end 

function getintervalmap(centlist,interval) --optional interval
  if interval==nil then
    interval = 701.955 --fifth
    end
  local intmap
  local bestdiff = interval
  for pitchid = 1 , getTableLen(centlist)do
    if math.abs(centlist[pitchid]-interval)<bestdiff then
      bestdiff=math.abs(centlist[pitchid]-interval)
      intmap = pitchid
      end
    end
  return intmap-1
  end
  
function generateDefaultEDOData(equaveCents, divisions)
  local centsSize = equaveCents/divisions
  
  --generate increasing cents list
  local currentCents = 0
  local centsTable = {}
  for pitchID=1, divisions do
    table.insert(centsTable, currentCents)
    currentCents = currentCents + centsSize
    end
  
  local fifth = getintervalmap(centsTable)
  
  --generate pitchlist
  local pitchStrTable = {}
  local largestColorID = 0
  local largestSharpNumAbs = 0
  local resulttable = genscalemap(divisions, fifth)
  
  local sharpNumTable = {}
  
  for x=1, getTableLen(resulttable)-1 do
    local data = resulttable[x]
    
    local numgens = data[1]
    local noteLetter = data[2]
    local accidentalStr = data[3]
    local colorID = data[4]
    local sharpNum = data[5]
    local numArrows = data[6]
    
    if not isInTable(sharpNumTable, colorID) then
      table.insert(sharpNumTable, {colorID, sharpNum, numArrows})
      end
      
    local fullNoteName = noteLetter .. accidentalStr
    table.insert(pitchStrTable, centsSize .. " \"" .. fullNoteName .. "\" " .. colorID)
    
    if colorID > largestColorID then
      largestColorID = colorID
      end
    if math.abs(sharpNum) > largestSharpNumAbs then
      largestSharpNumAbs = math.abs(sharpNum)
      end
    end
  
  local function colorIDToSharpNum(colorID)
    for x=1, getTableLen(sharpNumTable) do
      if sharpNumTable[x][1] == colorID then
        return sharpNumTable[x][2], sharpNumTable[x][3]
        end
      end
    end
    
  --generate colorscheme line
  local colorSchemeStr = "COLORSCHEME"
  for colorID=0, largestColorID do
    local sharpNum, numArrows = colorIDToSharpNum(colorID)
    local isSharp = boolToNumber(sharpNum > 0)
    
    local color
    local alpha = 0
    if sharpNum == 0 then
      if numArrows == 0 then
        color = hexColor(alpha, 255, 255, 255)
      else
        local grayVal = (255-(255/(numArrows+1)))
        local r = grayVal*0.9
        local g = grayVal
        local b = grayVal*0.9
        color = hexColor(alpha, r, g, b)
        end
    else
      local b = (255*(1-isSharp))*((math.abs(sharpNum))/(largestSharpNumAbs*4+1))
      local g = (255-(255/(numArrows+1)))/4
      local r = (255*isSharp)*((math.abs(sharpNum))/(largestSharpNumAbs*4+1))
      color = hexColor(alpha, r, g, b)
      end
    colorSchemeStr = colorSchemeStr .. " " .. color
    end
  local str = colorSchemeStr .. "\n" .. table.concat(pitchStrTable, "\n")
  
  return str
  end
  
----------------

local openedMidiEditor = 2

local global_focusedText
local midiEditor
local pitchWindowSize
local timeWindowSize

local originalMouseCents, originalMouseCentsSnapped, originalMouseTime
local currentMouseWindowCentsDrag = 0
local currentMouseWindowTimeDrag = 0
local currentMouseCentsDrag = 0
local currentMouseCentsDragSnappped = 0
local currentMouseTimeDrag = 0

--constants
local BLACK = hexColor(0, 0, 0)
local WHITE = hexColor(255, 255, 255)
local YELLOW = hexColor(255, 255, 0)
local HORIZONTAL = 0
local VERTICAL = 1
local tag = "JFMIDIEDITOR_"
local PITCHBENDCC = 0xE0

local DEFAULTGUID = "{3C40C761-F3E7-4663-939B-01323167E23E}" --12-EDO tuning
local DEFAULTCENTS = 4800 --C4

local MINCENTS = 0
local MAXCENTS = 12800

local STRETCHSTARTOFNOTES = 0
local STRETCHENDOFNOTES = 1
local DRAGNOTES = 2
local ADJUSTVELOCITY = 3
local ADJUSTBEZIER = 4

local noteMovement

local toolbarHeight = 20
local globalSettingsHeight = 80
local tuningSettingsHeight
local measureHeight = 55
local scrollbarHeight = 13

local editedViewMode = false

local mouseCursor = 0

local regionCentsStart, regionTimeStart, regionCentsEnd, regionTimeEnd

local hoveringStartEdgeNoteID, hoveringEndEdgeNoteID, hoveringTopEdgeNoteID, hoveringBottomEdgeNoteID

local selectedColorID

local editedTuningFile

local showTuningSettings

local global_windowXMin
local global_windowYMin
local global_windowXMax
local global_windowYMax
  
---image functions---

function toggleSnap()
  reaper.MIDIEditor_OnCommand(midiEditor, 1014)
  end

function toggleViewMode()
  local label = "VIEWMODE"
  setMIDIEditorSetting(label, flip(getMIDIEditorSetting(label)))
  
  local pos = getPitchScrollbarPos()
  local size = getPitchScrollbarSize()
  setPitchScrollbarPos(1-(pos+size))
    
  local pos = getTimeScrollbarPos()
  local size = getTimeScrollbarSize()
  setTimeScrollbarPos(1-(pos+size))
  
  editedViewMode = true
  end

function toggleCentered()
  local label = "CENTERED"
  setMIDIEditorSetting(label, flip(getMIDIEditorSetting(label)))
  editedViewMode = true
  end

function toggleBlur()
  local label = "BLUR"
  setMIDIEditorSetting(label, flip(getMIDIEditorSetting(label)))
  end

function toggleShowVelocity()
  local label = "SHOWVELOCITY"
  setMIDIEditorSetting(label, flip(getMIDIEditorSetting(label)))
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
defineImage("centered", toggleCentered)
defineImage("blur", toggleBlur)
defineImage("showVelocity", toggleShowVelocity)

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
  
  local global_backgroundPitchList = {}
  local global_snapPitchList = {}
  
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
  local mediaItemGUID = reaper.BR_GetMediaItemTakeGUID(take)
  
  local hoveringPoint = false
  
  function getCCValueAtTime(take, msg1, chan, time, ccIDToStart, msg2)
    local CBEZ_ITERS = 8
    local startCCID
    
    local function EVAL_CBEZ(a,b,c,d,t)
      local _t2=t*t
      local tx=(a*t*_t2+b*_t2+c*t+d)
      return tx
    end
    
    local function LICE_CBezier_GetCoeffs(ctrl_x1, ctrl_x2, ctrl_x3, ctrl_x4, ctrl_y1, ctrl_y2, ctrl_y3, ctrl_y4)
      local pAX, pBX, pCX
      local pAY, pBY, pCY
    
      pCX = 3.0 * (ctrl_x2 - ctrl_x1)
      local cx = pCX
      pBX = 3.0 * (ctrl_x3 - ctrl_x2) - cx
      local bx = pBX
      pAX = (ctrl_x4 - ctrl_x1) - cx - bx
      pCY =  3.0 * (ctrl_y2 - ctrl_y1)
      local cy = pCY
      pBY = 3.0 * (ctrl_y3 - ctrl_y2) - cy
      local by = pBY
      pAY = (ctrl_y4 - ctrl_y1) - cy - by
      return pAX, pBX, pCX, pAY, pBY, pCY
    end
    
    local function LICE_CBezier_GetY(ctrl_x1, ctrl_x2, ctrl_x3, ctrl_x4, ctrl_y1, ctrl_y2, ctrl_y3, ctrl_y4, x)
      local pNextX = 0
      local pdYdX = 0
      local ptLo = 0
      local ptHi = 0
    
      if x < ctrl_x1 then
        pNextX = ctrl_x1
        pdYdX = 0
        return ctrl_y1, pNextX, pdYdX, ptLo, ptHi
      end
    
      if x >= ctrl_x4 then
        pNextX = ctrl_x4
        pdYdX = 0
        return ctrl_y4, pNextX, pdYdX, ptLo, ptHi
      end
    
      local ax, bx, cx, ay, by, cy =
        LICE_CBezier_GetCoeffs(ctrl_x1, ctrl_x2, ctrl_x3, ctrl_x4, ctrl_y1, ctrl_y2, ctrl_y3, ctrl_y4)
    
      local tx, t
      local tLo = 0.0
      local tHi = 1.0
      local xLo=0.0
      local xHi=0.0
      local yLo, yHi
    
      for i = 1, CBEZ_ITERS do
        t = 0.5 * (tLo + tHi)
        tx = EVAL_CBEZ(ax, bx, cx, ctrl_x1, t)
        if tx < x then
          tLo = t
          xLo = tx
        elseif tx > x then
          tHi = t
          xHi = tx
        else
          tLo = t
          xLo = tx
          tHi = t + 1.0 / (2.0 ^ CBEZ_ITERS)
          if tHi > 1.0 then tHi = 1.0 end -- floating point error
          xHi = EVAL_CBEZ(ax, bx, cx, ctrl_x1, tHi)
          break
        end
      end
    
      if tLo == 0. then xLo = EVAL_CBEZ(ax, bx, cx, ctrl_x1, 0.) end
      if tHi == 1. then xHi = EVAL_CBEZ(ax, bx, cx, ctrl_x1, 1.) end
    
      yLo = EVAL_CBEZ(ay, by, cy, ctrl_y1, tLo)
      yHi = EVAL_CBEZ(ay, by, cy, ctrl_y1, tHi)
    
      local dYdX = (xLo == xHi and 0.0 or (yHi - yLo) / (xHi - xLo))
      local y = yLo + (x - xLo) * dYdX
    
      pNextX = xHi
      pdYdX = dYdX
    
      ptLo = tLo
      ptHi = tHi
    
      return y, pNextX, pdYdX, ptLo, ptHi
    end
    
    local function calculateCCValueAtTime(val1, val2, pos, shape, beztension)
      if not val2 then
        val2 = val1
        end
        
      if shape == 0 then -- square
        return val1, startCCID
      elseif shape == 1 then -- linear
        return val1 + ((val2 - val1) * pos), startCCID
      elseif shape == 2 then -- slow start/end
        return val1 + ((val2 - val1) * (pos ^ 2) * (3 - 2 * pos)), startCCID
      elseif shape == 3 then -- fast start
        return val1 + ((val2 - val1) * (1. - ((1. - pos) ^ 3))), startCCID
      elseif shape == 4 then -- fast end
        return val1 + ((val2 - val1) * (pos ^ 3)), startCCID
      elseif shape == 5 then -- bezier TODO
        local x0, x1, x2, x3, y0, y1, y2, y3
        x0, y0 = 0., val1
        x3, y3 = 1., val2
        x1, y1 = 0.25, val1 + ((val2 - val1) * 0.25)
        x2, y2 = 0.75, val1 + ((val2 - val1) * 0.75)
        
        x1 = x1 + beztension * (beztension > 0 and 1 - x1 or x1 - 0)
        y1 = y1 - beztension * (beztension > 0 and y1 - val1 or val2 - y1)
        x2 = x2 + beztension * (beztension > 0 and 1 - x2 or x2 - 0)
        y2 = y2 - beztension * (beztension > 0 and y2 - val1 or val2 - y2)
        
        local bezy = LICE_CBezier_GetY(x0, x1, x2, x3, y0, y1, y2, y3, pos)
        
        return bezy, startCCID
        end
      return val1, startCCID
      end
    
    local ccID
    if ccIDToStart then
      ccID = ccIDToStart
    else
      ccID = 0
      end
    
    local val1, val2, startPPQPOS, endPPQPOS
    local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, time)
    
    while true do
      local retval, selected, muted, testPPQPOS, chanMsg, testChan, testMsg2, msg3 = reaper.MIDI_GetCC(take, ccID)
      if not retval then
        break
        end
      if chanMsg == msg1 and testChan == chan and (msg2 == nil or testMsg2 == msg2) then
        if not val2 and ppqpos >= testPPQPOS then
          if not msg2 then
            val1 = testMsg2 + msg3*128
          else
            val1 = msg3
            end
          startPPQPOS = testPPQPOS
          startCCID = ccID
          end
        if testPPQPOS > ppqpos then
          if not val1 then
            reaper.ShowConsoleMsg("ERROR " .. "\n")
            return
            end
          if not msg2 then
            val2 = testMsg2 + msg3*128
          else
            val2 = msg3
            end
          endPPQPOS = testPPQPOS
          break
          end
        end
      ccID = ccID + 1
      end
    
    if startCCID == nil then
      return 127
      end
      
    local range, pos
    if not val2 then
      range = 0
      pos = 0
    else
      range = endPPQPOS - startPPQPOS
      pos = (ppqpos - startPPQPOS) / range
      end
    --reaper.ShowConsoleMsg("PPQPOS: " .. startPPQPOS .. " " .. ppqpos .. " " .. endPPQPOS .. "\n")
    local _, shape, beztension = reaper.MIDI_GetCCShape(take, startCCID)
    return calculateCCValueAtTime(val1, val2, pos, shape, beztension)
    end
  
  function generateDefaultTuningFileText()
    return
    DEFAULTGUID .. "\n" ..
    "COLORSCHEME 16777215 0\n" .. 
    "100 \"C\" 0\n" ..
    "100 \"C#\" 1\n" ..
    "100 \"D\" 0\n" ..
    "100 \"D#\" 1\n" ..
    "100 \"E\" 0\n" ..
    "100 \"F\" 0\n" ..
    "100 \"F#\" 1\n" ..
    "100 \"G\" 0\n" ..
    "100 \"G#\" 1 \n" ..
    "100 \"A\" 0\n" ..
    "100 \"A#\" 1\n" ..
    "100 \"B\" 0\n"
    end
  
  function getTuningFileFromGUID(guid) --fileText, fileName, filePath
    local fileText, fileName, filePath
    
    local function processFilesInDirectory(dir)
      if fileText ~= nil then
        return
        end
      
      reaper.EnumerateFiles(dir, -1)
      reaper.EnumerateSubdirectories(dir, -1)
      
      local subDirIndex = 0
      local testCount = 0
      while true do
        local subDir = reaper.EnumerateSubdirectories(dir, subDirIndex)
        if not subDir then
          break
          end
        subDir = dir .. subDir .. "\\"
        processFilesInDirectory(subDir)
        subDirIndex = subDirIndex + 1
        
        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        end
       
      local fileIndex = 0
      local testCount = 0
      while true do
        local fileNameToCheck = reaper.EnumerateFiles(dir, fileIndex)
        if not fileNameToCheck then
          break
          end
        local file = io.open(dir .. fileNameToCheck, "r")
        local line = file:read()
        file:close()
        if line == guid then
          local file = io.open(dir .. fileNameToCheck, "r")
          fileText = file:read("*all")
          fileName = fileNameToCheck
          filePath = dir .. fileName
          file:close()
          break
          end
        fileIndex = fileIndex + 1
        
        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        end
      end
    
    processFilesInDirectory(getTuningDirectory())
    
    return fileText, fileName, filePath
    end
    
  function getTuningEDOGUID(equaveCents, divisions)
    local guid
    
    local function processFilesInDirectory(dir)
      if fileText ~= nil then
        return
        end
      
      reaper.EnumerateFiles(dir, -1)
      reaper.EnumerateSubdirectories(dir, -1)
      
      local subDirIndex = 0
      local testCount = 0
      while true do
        local subDir = reaper.EnumerateSubdirectories(dir, subDirIndex)
        if not subDir then
          break
          end
        subDir = dir .. subDir .. "\\"
        processFilesInDirectory(subDir)
        subDirIndex = subDirIndex + 1
        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        end
        
      local fileIndex = 0
      local testCount = 0
      while true do
        local fileName = reaper.EnumerateFiles(dir, fileIndex)
        if not fileName then
          break
          end

        local file = io.open(dir .. fileName, "r")
        local fileText = file:read("*all")
        file:close()
        
        local testEquaveCents, testDivisions = getEDOValue(fileText)
        if testEquaveCents == equaveCents and testDivisions == divisions then
          local file = io.open(dir .. fileName, "r")
          guid = file:read()
          file:close()
          break
          end
          
        fileIndex = fileIndex + 1
        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        end
      end
    
    processFilesInDirectory(getTuningDirectory())
    
    if guid == nil then
      guid = reaper.genGuid("")
      local defaultEDOData = generateDefaultEDOData(equaveCents, divisions)
      local ratioNumber = getFraction(2^(equaveCents/1200))
      ratioNumber = string.gsub(ratioNumber, "/", "-") 
      local dir = getAutogeneratedTuningsDirectory() .. "ED(" .. ratioNumber .. ")" .. "\\"
      reaper.RecursiveCreateDirectory(dir, 0)
      local fileName = divisions .. "-ED(" .. ratioNumber .. ")"
      local filePath = dir .. fileName .. ".txt"
      saveTuningFile(filePath, guid .. "\n" .. defaultEDOData)
      end
      
    return guid
    end
    
  function getTuningFilePath(isSnap)
    local fileNameToCheck = reaper.guidToString(mediaItemGUID, "") .. "_" .. math.floor(boolToNumber(isSnap)) .. ".txt"
    
    local dir = getTempDirectory()
    local filePath = dir .. fileNameToCheck
    
    --check if temp file exists
    reaper.EnumerateFiles(dir, -1)
    local foundFile
    local fileIndex = 0
    local testCount = 0
    while true do
      local fileName = reaper.EnumerateFiles(dir, fileIndex)
      if not fileName then
        break
        end
      if fileName == fileNameToCheck then
        foundFile = true
        break
        end
      fileIndex = fileIndex + 1
      
      testCount = testCount + 1
      if testCount > 100 then
        debug_printStack()
        end
      end
    
    -----
    
    --if not found, then generate temp file
    if not foundFile then
      local guid = getTuningGUID(isSnap)
      local fileText, fileName = getTuningFileFromGUID(guid)
      
      if fileText == nil then
        guid = DEFAULTGUID
        fileText, fileName = getTuningFileFromGUID(guid)
        if fileText == nil then
          fileText = generateDefaultTuningFileText()
          fileName = "Default 12-ED2.txt"
          local file = io.open(getTuningDirectory() .. fileName, "w+")
          file:write(fileText)
          file:close()
          end
        setTuningGUID(isSnap, guid)
        end
      
      local dotIndex = string.find(fileName, "%.")
      fileText = "NAME " .. string.sub(fileName, 1, dotIndex-1) .. "\n" .. fileText
      
      local file = io.open(filePath, "w+")
      file:write(fileText)
      file:close()
      end
    
    return filePath
    end
    
  function getTuningFile(isSnap) --returns fileText, name
    local filePath = getTuningFilePath(isSnap)
    
    local file = io.open(filePath, "r")
    local tuningName = getValue(file:read())
    file:close()
    
    local file = io.open(filePath, "r")
    local fileText = file:read("*all")
    file:close()
    
    return fileText, tuningName
    end
  
  function setTuningFile(isSnap, data)
    local filePath = getTuningFilePath(isSnap)
    local file = io.open(filePath, "w+")
    file:write(data)
    file:close()
    
    setTuningModified(isSnap, true)
    end
  
  function saveTuningFile(filePath, data) --TODO: filename parameter, sub-directories
    local file = io.open(filePath, "w+")
    file:write(data)
    file:close()
    end
  
  function getTuningData(isSnap) --(or fileText) returns name, colorScheme, pitchList, loopSize, absoluteCents, fileText
    local colorScheme
    local pitchList = {}
    local loopSize = 0
    local absoluteCents = {}
    
    local fileText, name
    if type(isSnap) == "boolean" then
      fileText, name = getTuningFile(isSnap)
      if fileText == nil then
        debug_printStack()
        end
    else
      fileText = isSnap
      end
  
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
        table.insert(pitchList, values)
        table.insert(absoluteCents, loopSize)
        loopSize = loopSize + values[1]
        end
      end
    
    loopSize = round(loopSize, 2)
  
    return name, colorScheme, pitchList, loopSize, absoluteCents, fileText
    end
  
  function setColorScheme(isSnap, colorID, rgb)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
      
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if label == "COLORSCHEME" then
        local value = getValue(line)
        colorScheme = separateString(value)
        colorScheme[colorID] = rgb
        table.insert(strTable, label .. " " .. table.concat(colorScheme, " "))
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function setPitchName(isSnap, pitchID, name)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    local pitchCount = 0
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if tonumber(label) then
        pitchCount = pitchCount + 1
        if pitchCount == pitchID then
          local values = separateString(line)
          values[2] = "\"" .. name .. "\""
          table.insert(strTable, table.concat(values, " "))
        else
          table.insert(strTable, line)
          end
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function setPitchSize(isSnap, pitchID, size)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    local pitchCount = 0
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if tonumber(label) then
        pitchCount = pitchCount + 1
        if pitchCount == pitchID then
          local values = separateString(line)
          values[1] = size
          table.insert(strTable, table.concat(values, " "))
        else
          table.insert(strTable, line)
          end
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function setPitchColorID(isSnap, pitchID, colorID)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    local pitchCount = 0
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if tonumber(label) then
        pitchCount = pitchCount + 1
        if pitchCount == pitchID then
          local values = separateString(line)
          values[3] = colorID
          table.insert(strTable, table.concat(values, " "))
        else
          table.insert(strTable, line)
          end
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function addPitch(isSnap)
    local fileText = getTuningFile(isSnap)
    local str = fileText .. "\n" .. "100 \"new\" 0"
    setTuningFile(isSnap, str)
    end
  
  function deletePitch(isSnap, pitchID)
    local guid = getTuningGUID(isSnap)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    local pitchCount = 0
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if tonumber(label) then
        pitchCount = pitchCount + 1
        if pitchCount ~= pitchID then
          table.insert(strTable, line)
          end
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function addColor(isSnap)
    local guid = getTuningGUID(isSnap)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      if label == "COLORSCHEME" then
        table.insert(strTable, line .. " 0")
      else
        table.insert(strTable, line)
        end
      end
    
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
  
  function deleteColor(isSnap, colorID)
    local fileText = getTuningFile(isSnap)
    
    local strTable = {}
    
    for line in fileText:gmatch("[^\r\n]+") do
      local label = getLabel(line)
      local value = getValue(line)
      if label == "COLORSCHEME" then
        local values = separateString(value)
        table.remove(values, colorID)
        table.insert(strTable, label .. " " .. table.concat(values, " "))
      elseif tonumber(label) then
        local values = separateString(line)
        values[3] = tonumber(values[3])
        if tonumber(values[3]) >= colorID-1 then
          values[3] = values[3] - 1
          end
        table.insert(strTable, table.concat(values, " "))
      else
        table.insert(strTable, line)
        end
      end
      
    setTuningFile(isSnap, table.concat(strTable, "\n"))
    end
    
  local snapEnabled = numberToBool(reaper.MIDIEditor_GetSetting_int(midiEditor, "snap_enabled"))
  local isCentered = numberToBool(getMIDIEditorSetting("CENTERED"))
  local blurPitchGrid = numberToBool(getMIDIEditorSetting("BLUR"))
  local showVelocity = numberToBool(getMIDIEditorSetting("SHOWVELOCITY"))
  
  local showVelocityBars
  local showVelocityCircles
  
  local pitchIDToDelete
  local pitchIDToDeleteIsSnap
  local colorIDToDelete
  local colorIDToDeleteIsSnap
  local tuningGUIDToSet
  local tuningGUIDToSetIsSnap
  
  function setTextEvent(label, val)
    reaper.PreventUIRefresh(1)
    
    if val == 0 then
      --debug_printStack()
      end
      
    local msgLabel = tag .. label .. " "
    local len = string.len(msgLabel)
    local x = 0
    local testCount = 0
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
      
      testCount = testCount + 1
      if testCount > 100 then
        debug_printStack()
        end
      end
    
    reaper.PreventUIRefresh(-1)
    end
    
  function getTextEvent(label, default)
    local msgLabel = tag .. label .. " "
    local len = string.len(msgLabel)
    local x = 0
    local testCount = 0
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
        if ppqpos ~= reaper.MIDI_GetPPQPosFromProjTime(take, 0) then
          reaper.MIDI_SetTextSysexEvt(take, x, nil, nil, reaper.MIDI_GetPPQPosFromProjTime(take, 0))
          end
        return val
        end
      x = x + 1
      
      testCount = testCount + 1
      if testCount > 100 then
        debug_printStack()
        end
      end
    end
  
  debug_funcTime("misc")
      
  local programPitchBendDown = getTextEvent("pitchbend0", 0)
  local programPitchBendUp = getTextEvent("pitchbend1", 0)
  
  local cc_NOTEH = getTextEvent("cc_noteH", 0)
  local cc_NOTES = getTextEvent("cc_noteS", 0)
  local cc_NOTEV = getTextEvent("cc_noteV", 0)
  local cc_NOTESIZE = getTextEvent("cc_noteSize", 0)
  local cc_NOTEALPHA = getTextEvent("cc_noteAlpha", 0)
  
  local cc_NOTEHMIN = getTextEvent("cc_noteHMIN", 0)
  local cc_NOTEHMAX = getTextEvent("cc_noteHMAX", 127)
  local cc_NOTESMIN = getTextEvent("cc_noteSMIN", 0)
  local cc_NOTESMAX = getTextEvent("cc_noteSMAX", 127)
  local cc_NOTEVMIN = getTextEvent("cc_noteVMIN", 0)
  local cc_NOTEVMAX = getTextEvent("cc_noteVMAX", 127)
  local cc_NOTENOTESIZEMIN = getTextEvent("cc_noteSizeMIN", 0)
  local cc_NOTENOTESIZEMAX = getTextEvent("cc_noteSizeMAX", 127)
  local cc_NOTEALPHAMIN = getTextEvent("cc_noteAlphaMIN", 0)
  local cc_NOTEALPHAMAX = getTextEvent("cc_noteAlphaMAX", 127)
  
  local currentPointCC = getTextEvent("currentpointcc", "pitchbend")
  if currentPointCC == "pitchbend" then
    currentPointCC = nil
    end
    
  debug_funcTime("get text events")
  
  function getCurrentMsg2Point()
    if currentPointCC then
      return getTextEvent("cc_" .. currentPointCC, 0)
      end
    end
    
  function getTuningSettingsVisibility()
    return getTextEvent("tuningsvisibility", 0)
    end
    
  function toggleTuningSettingsVisibility()
    setTextEvent("tuningsvisibility", flip(getTuningSettingsVisibility()))
    end
  
  function isTuningModified(isSnap)
    if isSnap then
      return snapModified
    else
      return backgroundModified
      end
    end
  
  function setTuningModified(isSnap, val) --true or false
    if isSnap then
      snapModified = val
    else
      backgroundModified = val
      end
    end
    
  function convertHzCents(text)
    local i = string.find(text, "Hz")
    if i ~= nil then
      text = string.sub(text, 1, i-1)
      end
    local i = string.find(text, "c")
    if i ~= nil then
      text = string.sub(text, 1, i-1)
      end
    
    if tonumber(text) then
      text = tonumber(text)
      if getTextEvent("basecentsview", 0) == 0 then
        text = hzToCents(text)
        end
      return text
      end
    end
    
  function getPitchList(isSnap) --pitchPosMin, pitchPosMax, name, color, isOctave\
    if isSnap then
      return global_snapPitchList
    else
      return global_backgroundPitchList
      end
    end
  
  function getPitchNames(isSnap)
    local list = {}
    
    local _, _, pitchList = getTuningData(isSnap)
    
    for x=1, getTableLen(pitchList) do
      local name = pitchList[x][2]
      table.insert(list, name)
      end
      
    return list
    end
  
  function getBasePitchID(isSnap)
    local label = "basepitch" .. math.floor(boolToNumber(isSnap))
    return getTextEvent(label, 1)
    end
  
  function setBasePitchID(isSnap, val)
    local label = "basepitch" .. math.floor(boolToNumber(isSnap))
    setTextEvent(label, math.floor(val))
    end
    
  function getBasePitchName(isSnap)
    local basePitchID = getBasePitchID(isSnap)
    return getPitchNames(isSnap)[basePitchID]
    end
  
  function getOctavePitchID(isSnap)
    local label = "octavepitch" .. math.floor(boolToNumber(isSnap))
    return getTextEvent(label, 1)
    end
  
  function setOctavePitchID(isSnap, val)
    local label = "octavepitch" .. math.floor(boolToNumber(isSnap))
    setTextEvent(label, math.floor(val))
    end
    
  function getOctave(isSnap)
    local label = "octave" .. math.floor(boolToNumber(isSnap))
    return getTextEvent(label, 0)
    end
  
  function setOctave(isSnap, val)
    local label = "octave" .. math.floor(boolToNumber(isSnap))
    setTextEvent(label, math.floor(val))
    end
    
  function getOctavePitchName(isSnap)
    local octavePitchID = getOctavePitchID(isSnap)
    return getPitchNames(isSnap)[octavePitchID]
    end
    
  function getBackgroundPitchList() --pitchPosMin, pitchPosMax, name, color
    return getPitchList(false)
    end
    
  function getSnapPitchList() --pitchPosMin, pitchPosMax, name, color
    return getPitchList(true)
    end
    
  function getProgramPitchBendDown()
    return programPitchBendDown
    end
  
  function setProgramPitchBendDown(semitones)
    setTextEvent("pitchbend0", semitones)
    end
  
  function getProgramPitchBendUp()
    return programPitchBendUp
    end
  
  function setProgramPitchBendUp(semitones)
    setTextEvent("pitchbend1", semitones)
    end
  
  function definePitchLists()
    local function run(isSnap)
      if isSnap then
        baseCents = getSnapBaseCents()
      else
        baseCents = getBackgroundBaseCents()
        end
      local guid = getTuningGUID(isSnap)
      local basePitchID = getBasePitchID(isSnap)
      local octavePitchID = getOctavePitchID(isSnap)
      local currentOctave = getOctave(isSnap)
      
      local name, colorScheme, pitchList, loopSize = getTuningData(isSnap)
      local numPitches = getTableLen(pitchList) 
      
      if basePitchID > numPitches then
        basePitchID = 1
        setBasePitchID(isSnap, basePitchID)
        end
      if octavePitchID > numPitches then
        octavePitchID = 1
        setOctavePitchID(isSnap, octavePitchID)
        end
        
      local centsAtLoopPoint = baseCents
      local testCount = 0
      while centsAtLoopPoint > MINCENTS do
        centsAtLoopPoint = centsAtLoopPoint - loopSize
        end
      
      local centsMin = centsAtLoopPoint
      
      while centsAtLoopPoint < MAXCENTS do
        for x=0, numPitches-1 do
          local pitchID = basePitchID+x
          if isSnap then
            --reaper.ShowConsoleMsg("PITCHID: " .. pitchID .. " " .. numPitches .. "\n")
            end
          if pitchID > numPitches then
            pitchID = pitchID - numPitches
            end
          local isOctave = (pitchID == octavePitchID)
          if isOctave then
            currentOctave = currentOctave + 1
            end
          
          local data = pitchList[pitchID]
          
          local centsSize = data[1]
          centsMax = centsMin + centsSize
          
          local noteName = data[2] .. currentOctave
          
          local colorID = data[3]
          local color = colorScheme[colorID+1] --include full alpha
          
          local pitchPosMin = centsToWindowPos(centsMin)
          local pitchPosMax = centsToWindowPos(centsMax)
          
          local data = {pitchPosMin, pitchPosMax, noteName, color, isOctave}
          
          if isSnap then
            table.insert(global_snapPitchList, data)
          else
            table.insert(global_backgroundPitchList, data)
            end
            
          centsMin = centsMax
          end
        
        centsAtLoopPoint = centsAtLoopPoint + loopSize
        end
      end
    
    run(false)
    run(true)
    end
  
  function unselectAll()
    reaper.MIDIEditor_OnCommand(midiEditor, 40214)
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
  local noModifiersHeldDown = (not ctrlDown and not shiftDown and not altDown)
  local currentMouseX, currentMouseY = reaper.ImGui_GetMousePos(ctx)

  if math.abs(currentMouseX) < 10000 then --prevent invalid mouse positions
    mouseX = math.floor(currentMouseX)
    mouseY = math.floor(currentMouseY)
    end

  --REAPER states
  local playing = (reaper.GetPlayState()&1 == 1)
  
  local visibleStartCents, visibleEndCents
  
  local centsRangeStart, centsRangeEnd, timeRangeStart, timeRangeEnd
  local visibleStartTime, visibleEndTime, visibleStartPPQPOS, visibleEndPPQPOS
  
  local executeMotion
  
  local programPitchBendDown = getProgramPitchBendDown()
  local programPitchBendUp = getProgramPitchBendUp()
  local isValidProgramPitchBend = (programPitchBendDown > 0 and programPitchBendUp > 0)
  
  local toSort = false
  local editedNotes = false
  local pointsToDelete = {}
  local selectedNoteCount = 0
  local clickedAnyNote = false
  
  debug_funcTime("define various variables")
      
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
  
  debug_funcTime("process chunk")
      
  if midiEditor_xMin > midiEditor_xMax or midiEditor_yMin > midiEditor_yMax then
    --some seemingly random crashes when resizing?
  else
    --define dimensions of entire window
    local window_xMin, window_yMin, window_xMax, window_yMax
    local windowSizeX, windowSizeY
    
    window_xMin = midiEditor_xMin
    window_yMin = midiEditor_yMin
    window_xMax = midiEditor_xMax
    window_yMax = midiEditor_yMax-envelopeHeight - 20
    
    windowSizeX = window_xMax-window_xMin
    windowSizeY = window_yMax-window_yMin
    
    if global_windowXMin ~= window_xMin or global_windowYMin ~= window_yMin or global_windowXMax ~= window_xMax or global_windowYMax ~= window_yMax then
      global_windowXMin = window_xMin
      global_windowYMin = window_yMin
      global_windowXMax = window_xMax
      global_windowYMax = window_yMax
      end
    
    local toolbar_xMin, toolbar_yMin, toolbar_xMax, toolbar_yMax
    toolbar_xMin = window_xMin
    toolbar_yMin = window_yMin
    toolbar_xMax = window_xMax
    toolbar_yMax = toolbar_yMin + toolbarHeight
    
    local globalSettings_xMin, globalSettings_yMin, globalSettings_xMax, globalSettings_yMax
    globalSettings_xMin = window_xMin
    globalSettings_yMin = toolbar_yMax
    globalSettings_xMax = window_xMax - 19
    globalSettings_yMax = globalSettings_yMin + globalSettingsHeight
    
    local tuningSettingsVisibility = getTuningSettingsVisibility()
    if tuningSettingsVisibility == 1 then
      tuningSettingsHeight = 140
    else
      tuningSettingsHeight = 0
      end
      
    local tuningSettings_xMin, tuningSettings_yMin, tuningSettings_xMax, tuningSettings_yMax
    tuningSettings_xMin = globalSettings_xMin
    tuningSettings_yMin = globalSettings_yMax
    tuningSettings_xMax = globalSettings_xMax
    tuningSettings_yMax = tuningSettings_yMin + tuningSettingsHeight
    
    local tuningSettingsWidth = (tuningSettings_xMax-tuningSettings_xMin)/2
    
    --define dimensions of just the editable note window
    local noteEditor_xMin, noteEditor_yMin, noteEditor_xMax, noteEditor_yMax
    
    if viewMode == HORIZONTAL then
      noteEditor_xMin = window_xMin+60
      noteEditor_yMin = tuningSettings_yMax + measureHeight
      noteEditor_xMax = window_xMax - scrollbarHeight
      if isValidProgramPitchBend then
        noteEditor_yMax = window_yMax - 16
      else
        --noteEditor_yMax = noteEditor_yMin
        noteEditor_yMax = window_yMax - 16 --FIX
        end
    else
      noteEditor_xMin = window_xMin+60
      noteEditor_yMin = tuningSettings_yMax
      if isValidProgramPitchBend then
        noteEditor_xMax = window_xMax - 17
      else
        --noteEditor_xMax = noteEditor_xMin
        noteEditor_xMax = window_xMax - 17 --FIX
        end
      noteEditor_yMax = window_yMax-40 
      end
    
    debug_funcTime("calculate window sizes")
        
    function drawTuningSettings(isSnap)
      local side = boolToNumber(isSnap)
      local sideLabel = "ISSNAP" .. side .. "..." .. windowID
      
      local baseCentsView = getTextEvent("basecentsview", 0)
      local label
      if baseCentsView == 0 then
        label = "Hz"
      else
        label = "c"
        end
        
      local comboLen = 100
      
      local fileName, colorScheme, pitchList, loopSize, absoluteCents, fileText = getTuningData(isSnap)
      local pitchNames = getPitchNames(isSnap)
        
      --EDO sliders
      local currentEquaveCents, currentDivisions = getEDOValue(fileText)
      local currentEDORatio
      local edoText
      if currentEquaveCents == 0 or currentEquaveCents == nil then
        edoText = " (No EDO)"
      else
        currentEDORatio = getFraction(2^(currentEquaveCents/1200))
        edoText = "-ED" .. currentEDORatio
        if string.sub(edoText, string.len(edoText)-1, string.len(edoText)) == "/1" then
          edoText = string.sub(edoText, 1, string.len(edoText)-2)
          end
        end
      local textFieldWidth = 40
      if currentEquaveCents ~= nil then
        local width = math.floor(tuningSettingsWidth/1.15 - textFieldWidth)
        reaper.ImGui_SetNextItemWidth(ctx, width)
        local min = 5
        local max = math.floor(width/3)
        local retval, newDivisions = reaper.ImGui_SliderInt(ctx, "##EDOSLIDER"  .. boolToNumber(isSnap) .. "..." .. windowID, currentDivisions, min, max, currentDivisions .. edoText)
        
        if retval and newDivisions ~= currentDivisions then
          local guid = getTuningEDOGUID(currentEquaveCents, newDivisions)
          tuningGUIDToSet = guid
          tuningGUIDToSetIsSnap = isSnap
          end
        
        reaper.ImGui_SameLine(ctx)
        end
        
      --EDO ratio
      reaper.ImGui_SetNextItemWidth(ctx, textFieldWidth)
      local display = currentEquaveCents
      if currentEquaveCents == 0 then
        display = ""
      else
        display = currentEDORatio
        end
      local retval, text = reaper.ImGui_InputText(ctx, "Equal Division Ratio##EDOINPUTTEXT" .. sideLabel, display, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
      if retval then
        local equaveCents
        local isFraction
        if tonumber(text) then
          equaveCents = tonumber(text)
        elseif fractionToDecimal(text) then
          equaveCents = fractionToDecimal(text)
          isFraction = true
          end
        if equaveCents ~= nil then
          equaveCents = math.max(equaveCents, 0)
          if equaveCents < 20 or isFraction then
            equaveCents = 1200*(math.log(equaveCents)/math.log(2))
            end
          equaveCents = round(equaveCents, 3)
          local divisions
          if currentDivisions == nil then
            divisions = 12
          else
            divisions = currentDivisions
            end
          --reaper.ShowConsoleMsg(equaveCents .. "\n")
          local guid = getTuningEDOGUID(equaveCents, divisions)
          tuningGUIDToSet = guid
          tuningGUIDToSetIsSnap = isSnap
          end
        end
      
      --load button
      if reaper.ImGui_Button(ctx, "Load...##" .. sideLabel, 57, 20) then
        local dir = getTuningDirectory()
        local extList = "Text Files (*.txt)\0*.txt\0\0"
        local retval, filePath = reaper.JS_Dialog_BrowseForOpenFiles("Load Tuning", dir, "", extList, false)
        if retval == 1 then
          local file = io.open(filePath, "r")
          local guid = file:read()
          file:close()
          tuningGUIDToSet = guid
          tuningGUIDToSetIsSnap = isSnap
          end
        end
      
      --save as button
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Save as...##" .. sideLabel, 78, 20) then
        local dir = getTuningDirectory()
        local extList = "Text Files (*.txt)\0*.txt\0\0"
        local retval, filePath = reaper.JS_Dialog_BrowseForSaveFile("Save Tuning", dir, "", extList)
        if retval == 1 then
          --need a new guid
          if string.sub(filePath, string.len(filePath)-3, string.len(filePath)) ~= ".txt" then
            filePath = filePath .. ".txt"
            end
            
          local newGUID = reaper.genGuid("")
          local _, i = string.find(fileText, "\n") --cut "NAME" line
          local _, i = string.find(fileText, "\n", i+1) --cut "GUID" line, replace with new guid
          local data = newGUID .. "\n" .. string.sub(fileText, i+1, string.len(fileText))
          saveTuningFile(filePath, data)
          tuningGUIDToSet = newGUID
          tuningGUIDToSetIsSnap = isSnap
          end
        end
        
      --overwrite button
      if isTuningModified(isSnap) then  
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Overwrite...##" .. sideLabel, 95, 20) then
          local _, i = string.find(fileText, "\n") --cut "NAME" line
          local data = string.sub(fileText, i+1, string.len(fileText))
          local _, _, filePath = getTuningFileFromGUID(getTuningGUID(isSnap))
          saveTuningFile(filePath, data)
          setTuningModified(isSnap, false)
          end
        end
        
      --base pitch
      reaper.ImGui_SetNextItemWidth(ctx, 70)
      local display
      if isSnap then
        display = getSnapBaseCents()
      else
        display = getBackgroundBaseCents()
        end
      if baseCentsView == 0 then
        display = centsToHz(display)
        end
      display = display .. label
      local retval, text = reaper.ImGui_InputText(ctx, "##BASEPITCH" .. sideLabel, display)
      if retval then
        text = convertHzCents(text)
        if tonumber(text) then
          if isSnap then
            setSnapBaseCents(text)
          else
            setBackgroundBaseCents(text)
            end
          end
        end
      
      --pitch name
      reaper.ImGui_SameLine(ctx)
      local display = getBasePitchName(isSnap)
      reaper.ImGui_SetNextItemWidth(ctx, 50)
      if reaper.ImGui_BeginCombo(ctx, "Base Pitch##PITCHNAME" .. sideLabel, display) then
        for x=1, getTableLen(pitchNames) do
          local name = pitchNames[x]
          if reaper.ImGui_Selectable(ctx, name, false, reaper.ImGui_SelectableFlags_None(), comboLen, 0) then
            setBasePitchID(isSnap, x)
            end
          end
        reaper.ImGui_EndCombo(ctx)
        end
      
      --octave split
      local display = getOctavePitchName(isSnap)
      reaper.ImGui_SetNextItemWidth(ctx, 50)
      if reaper.ImGui_BeginCombo(ctx, "##OCTAVESPLIT" .. sideLabel, display) then
        for x=1, getTableLen(pitchNames) do
          local name = pitchNames[x]
          if reaper.ImGui_Selectable(ctx, name, false, reaper.ImGui_SelectableFlags_None(), comboLen, 0) then
            setOctavePitchID(isSnap, x)
            end
          end
        reaper.ImGui_EndCombo(ctx)
        end
      
      --octave base
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "<##OCTAVE" .. sideLabel, 15, 20) then
        setOctave(isSnap, getOctave(isSnap)-1)
        end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, ">##OCTAVE" .. sideLabel, 15, 20) then
        setOctave(isSnap, getOctave(isSnap)+1)
        end
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_Text(ctx, "Octave Split")
      reaper.ImGui_Dummy(ctx, 0, 15)
      
      --pitch colors
      local pitchWidth = 40
      
      local h = 11
      for pitchID=1, getTableLen(pitchList) do
        if pitchID > 1 then
          reaper.ImGui_SameLine(ctx)
          end
        local colorID = pitchList[pitchID][3]
        local color = colorScheme[colorID+1]
        if reaper.ImGui_ColorButton(ctx, "##COLOR" .. pitchID .. sideLabel, color, reaper.ImGui_ColorEditFlags_NoTooltip()+reaper.ImGui_ColorEditFlags_NoAlpha(), pitchWidth, h) then
          colorID = colorID + 1
          if colorID == getTableLen(colorScheme) then
            colorID = 0
            end
          setPitchColorID(isSnap, pitchID, colorID)
          end
        end
        
      --pitch names
      for pitchID=1, getTableLen(pitchList) do
        if pitchID > 1 then
          reaper.ImGui_SameLine(ctx)
          end
        reaper.ImGui_SetNextItemWidth(ctx, pitchWidth)
        local display = pitchList[pitchID][2]
        local retval, text = reaper.ImGui_InputText(ctx, "##PITCHNAME" .. pitchID .. sideLabel, display)
        if retval and noQuotes(text) then
          setPitchName(isSnap, pitchID, text)
          end
        end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "...##NEWPITCH", 30, 20) then
        addPitch(isSnap)
        end
        
      --pitch sizes
      local currentPitchUnit = getPitchUnit(isSnap)
      local pitchUnitText = convertPitchUnitToText(currentPitchUnit)
      for pitchID=1, getTableLen(pitchList) do
        if pitchID > 1 then
          reaper.ImGui_SameLine(ctx)
          end
        reaper.ImGui_SetNextItemWidth(ctx, pitchWidth)
        
        local display
        
        if pitchUnitText == "Consecutive view" then
          display = pitchList[pitchID][1]
          display = removeExtraDecimalZeroes(display)
          end
        if pitchUnitText == "Scale view" then
          display = absoluteCents[pitchID]
          display = removeExtraDecimalZeroes(display)
          end
        if pitchUnitText == "Fraction" then
          local scaleViewCents
          if pitchID == 1 then
            scaleViewCents = 1
          else
            scaleViewCents = 2^(absoluteCents[pitchID]/1200)
            end
          display = getFraction(scaleViewCents)
          end
        
        local isLastPitch = (pitchID == getTableLen(pitchList))
        
        local function setScaleView(cents)
          if pitchID > 1 and 
          not (not isLastPitch and cents > absoluteCents[pitchID+1]) and
          not (cents < absoluteCents[pitchID-1]) then
            local diff = cents - absoluteCents[pitchID]
            setPitchSize(isSnap, pitchID-1, pitchList[pitchID-1][1] + diff)
            if not isLastPitch then
              setPitchSize(isSnap, pitchID, pitchList[pitchID][1] - diff)
              end
            end
          end
          
        local retval, text = reaper.ImGui_InputText(ctx, "##PITCHSIZE" .. pitchID .. sideLabel, display, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
        if retval then
          local backslashIndex = string.find(text, "\\")
          local forwardSlashIndex = string.find(text, "/")
                        
           --equal divisions format
          if backslashIndex ~= nil then
            --a\b<c>
            local j = string.find(text, "<")
            local k = string.find(text, ">")
            local equave
            local divisions
            if j ~= nil then
              if k ~= nil then
                equave = string.sub(text, j+1, string.len(text)-1)
              else
                equave = string.sub(text, j+1, string.len(text))
                end
              divisions = string.sub(text, backslashIndex+1, j-1)
            else
              equave = 2
              divisions = string.sub(text, backslashIndex+1, string.len(text))
              end
            local step = string.sub(text, 1, backslashIndex-1)
            equave = fractionToDecimal(equave)
            local cents = equave^(step/divisions)
            local result = 1200*(math.log(cents)/math.log(2))
            setScaleView(result) 
          
          --fractions
          elseif forwardSlashIndex ~= nil then
            local decimal = fractionToDecimal(text)
            local result = 1200*(math.log(decimal)/math.log(2))
            setScaleView(result)

          --cents
          elseif tonumber(text) then
            if pitchUnitText == "Consecutive view" then
              text = tonumber(text)
              if text > 0 then
                setPitchSize(isSnap, pitchID, text)
                end
            else
              text = tonumber(text)
              setScaleView(text)
              end
            end
          end
        end
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 90)
      if reaper.ImGui_BeginCombo(ctx, "##DELETEPITCH", "Delete...") then
        for pitchID=1, getTableLen(pitchList) do
          local name = pitchNames[pitchID]
          if reaper.ImGui_Selectable(ctx, name, false, reaper.ImGui_SelectableFlags_None(), comboLen, 0) then
            pitchIDToDelete = pitchID
            pitchToDeleteIsSnap = isSnap
            end
          end
        reaper.ImGui_EndCombo(ctx)
        end
      
      --units
      reaper.ImGui_SetNextItemWidth(ctx, 100)
      local display = pitchUnitText
      if reaper.ImGui_BeginCombo(ctx, "Pitch Units##" .. sideLabel, display) then
        for pitchUnit=0, 2 do
          local name = convertPitchUnitToText(pitchUnit)
          if reaper.ImGui_Selectable(ctx, name .. "##SELECTPITCHUNIT..." .. windowID, false, reaper.ImGui_SelectableFlags_None(), comboLen, 0) then
            setPitchUnit(isSnap, pitchUnit)
            end
          end
        reaper.ImGui_EndCombo(ctx)
        end
        
      reaper.ImGui_Dummy(ctx, 0, 15)
      
      --color scheme
      if not isSnap then
        for x=1, getTableLen(colorScheme) do
          local color = colorScheme[x]
          if x > 1 then
            reaper.ImGui_SameLine(ctx)
            end
          if reaper.ImGui_ColorButton(ctx, "##COLORSCHEME" .. x .. sideLabel, color, reaper.ImGui_ColorEditFlags_NoAlpha()) then
            if selectedColorID == x then
              selectedColorID = nil
            else
              selectedColorID = x
              end
            end
          end
        end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "...##NEWCOLOR", 30, 20) then
        addColor(isSnap)
        end
      if selectedColorID ~= nil then
        local color = colorScheme[selectedColorID]
        reaper.ImGui_SetNextItemWidth(ctx, 100)
        local retval, rgb = reaper.ImGui_ColorPicker3(ctx, "##COLORPICKER", color, reaper.ImGui_ColorEditFlags_NoSmallPreview()+reaper.ImGui_ColorEditFlags_DisplayHex()+reaper.ImGui_ColorEditFlags_NoSidePreview()+reaper.ImGui_ColorEditFlags_NoDragDrop())
        if retval then
          setColorScheme(isSnap, selectedColorID, rgb)
          editedTuningFile = true
          end
        if reaper.ImGui_Button(ctx, "Delete...##DELETECOLORSCHEME", 70, 20) then
          colorIDToDelete = selectedColorID
          colorIDToDeleteIsSnap = isSnap
          end
        end
      end
      
    function getClosestMIDINote(cents)
      return math.floor(cents/100+0.5)
      end
      
    function convertCentsToMIDIValues(cents, midiNoteNum) --(optional force midiNoteNum); midiNoteNum, pitchBendVal
      if midiNoteNum == nil then
        midiNoteNum = getClosestMIDINote(cents)
        end
      local pitchBendVal = convertCentsToPitchBendEnvelopeValue(cents - midiNoteNum*100)
      return midiNoteNum, pitchBendVal
      end
    
    function getCentsFromNote(noteID, time, startCCID) --optional time, isPoint (optimal performance when isPoint)
      local _, _, _, noteStartPPQPOS, noteEndPPQPOS, chan, midiNoteNum, _ = reaper.MIDI_GetNote(take, noteID)
      if time == nil then
        time = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
        end
      local pitchBendOffset, startCCID = getPitchBendCents(time, chan, startCCID)
      local val = midiNoteNum*100 + pitchBendOffset
      return val, startCCID
      end
    
    function getPitchBendLSBMSB(envVal)
      envVal = math.floor(envVal)
      return envVal & 0x7F, (envVal >> 7) & 0x7F
      end
      
    function insertPitchBend(selected, muted, ppqpos, chan, val)
      local lsb, msb = getPitchBendLSBMSB(val)
      reaper.MIDI_InsertCC(take, selected, muted, ppqpos, PITCHBENDCC, chan, lsb, msb)
      end
    
    function getPointIDs(noteID, forcePitchBend)
      local msg1, msg2
      if forcePitchBend or not currentPointCC then
        msg1 = PITCHBENDCC
      else
        if currentPointCC == "noteH" then
          msg1 = 176
          msg2 = cc_NOTEH
          end
        if currentPointCC == "noteS" then
          msg1 = 176
          msg2 = cc_NOTES
          end
        if currentPointCC == "noteV" then
          msg1 = 176
          msg2 = cc_NOTEV
          end
        if currentPointCC == "noteSize" then
          msg1 = 176
          msg2 = cc_NOTESIZE
          end
        if currentPointCC == "noteAlpha" then
          msg1 = 176
          msg2 = cc_ALPHA
          end
        end
      if not msg1 then
        reaper.ShowConsoleMsg(aaa)
        end
      
      -----
      
      local list = {}
      
      local _, _, _, startppqpos, endppqpos, chan = reaper.MIDI_GetNote(take, noteID)
      
      local ccID = 0
      while true do
        local retval, selected, muted, testPPQPOS, chanMsg, testChan, testMsg2, msg3 = reaper.MIDI_GetCC(take, ccID)
        if not retval then
          break
          end
        if testPPQPOS > endppqpos then
          break
          end
        if testPPQPOS >= startppqpos and chanMsg == msg1 and testChan == chan and (msg2 == nil or testMsg2 == msg2) then
          local time = reaper.MIDI_GetProjTimeFromPPQPos(take, testPPQPOS)
          local cents = getCentsFromNote(noteID, time)
          table.insert(list, {ccID, testPPQPOS, testMsg2, msg3, selected, time})
          end
        ccID = ccID + 1
        end
      
      return list
      end
    
    function getPitchBendPointIDs(noteID) --ccID, testPPQPOS, msg2, msg3
      return getPointIDs(noteID, true)
      end
    
    function getClosestPitchBendPointID(noteID, time)
      local pointIDs = getPitchBendPointIDs(noteID)
      for x=1, getTableLen(pointIDs) do
        local data = pointIDs[x]
        
        local ccID = data[1]
        local ccTime = data[6]
        
        if ccTime > time then
          return ccID - 1
          end
        if ccTime == time then
          return ccID
          end
        end
      end
      
    function checkNotes()
      --check noteStart pitch bend points, check monophonic collisions
      local noteTable = {}
      local ccTable = {}
      
      local noteID = 0
      while true do
        local deletedNote = false
        
        local noteExists, _, _, noteStartPPQPOS, noteEndPPQPOS, chan = reaper.MIDI_GetNote(take, noteID)
        local nextNoteExists, _, _, nextNoteStartPPQPOS, nextNoteEndPPQPOS, nextChan = reaper.MIDI_GetNote(take, noteID+1)
        
        if not noteExists then
          break
          end
        
        table.insert(noteTable, {noteStartPPQPOS, chan})

        --check monophonic collisions
        if nextNoteExists then
          if noteEndPPQPOS > nextNoteStartPPQPOS then
            noteEndPPQPOS = nextNoteStartPPQPOS
            setNote(noteID, nil, nil, nil, noteEndPPQPOS+1, nil, nil, nil, 1)
            end
            
          if math.abs(noteEndPPQPOS-noteStartPPQPOS) == 1 then
            deleteNote(noteID)
            deletedNote = true
            end
          end
        
        if not deletedNote then
          noteID = noteID + 1
          end
        end
      
      local ccID = 0
      while true do
        local retval, _, _, ppqpos, chanMsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, ccID)
        if not retval then
          break
          end

        if chanMsg == PITCHBENDCC then
          table.insert(ccTable, {ppqpos, chan})
          end
         
        ccID = ccID + 1
        end
      
      --check noteStart pitch bend points
      for x=1, getTableLen(noteTable) do
        local data = noteTable[x]
        local noteStartPPQPOS = data[1]
        local noteChan = data[2]
        local foundStartPoint = false
        for x=1, getTableLen(ccTable) do
          local data = ccTable[x]
          local ccPPQPOS = data[1]
          local ccChan = data[2]
          if ccPPQPOS == noteStartPPQPOS and noteChan == ccChan then
            foundStartPoint = true
            break
            end
          if ccPPQPOS >= noteStartPPQPOS then
            break
            end
          end
        if not foundStartPoint then
          local time = reaper.MIDI_GetProjTimeFromPPQPos(take, noteStartPPQPOS)
          local val = getNotePitchBendEnvelopeValue(time, noteChan)
          insertPitchBend(false, false, noteStartPPQPOS, noteChan, val) --selected TODO
          end
        end
      end
      
    function insertNote(selected, muted, startppqpos, endppqpos, chan, cents, vel)
      local midiNoteNum, pitchBendVal = convertCentsToMIDIValues(cents)
      reaper.MIDI_InsertNote(take, selected, muted, startppqpos, endppqpos, chan, midiNoteNum, vel)
      insertPitchBend(false, false, startppqpos, chan, pitchBendVal)
      
      if not editedNotes then
        editedNotes = true
        end
      end

    function setNote(noteID, selected, muted, noteStartPPQPOS, noteEndPPQPOS, chan, cents, vel, stretchSide)
      local _, _, _, originalNoteStartPPQPOS, originalNoteEndPPQPOS, originalChan, originalMidiNoteNum = reaper.MIDI_GetNote(take, noteID)
      local ccIDs = getPitchBendPointIDs(noteID)
      local originalCents = getCentsFromNote(noteID)
      
      local ppqposStartDiff, ppqposEndDiff
      if noteStartPPQPOS ~= nil then
        ppqposStartDiff = noteStartPPQPOS - originalNoteStartPPQPOS
      else
        ppqposStartDiff = 0
        end
      if noteEndPPQPOS ~= nil then
        ppqposEndDiff = noteEndPPQPOS - originalNoteEndPPQPOS
      else
        ppqposEndDiff = 0
        end
      
      local midiNoteNum, centsDiff, envDiff
      if cents == nil then
        centsDiff = 0
      else
        midiNoteNum = getClosestMIDINote(cents)
        local midiNoteNumDiff = midiNoteNum - originalMidiNoteNum
        centsDiff = cents - originalCents
        centsDiff = centsDiff - (midiNoteNumDiff*100)
        end

      reaper.MIDI_SetNote(take, noteID, selected, muted, originalNoteStartPPQPOS+ppqposStartDiff, originalNoteEndPPQPOS+ppqposEndDiff, chan, midiNoteNum, vel, true)
      
      local truncatedErrorMsg
      
      local envDiff
      for x=1, getTableLen(ccIDs) do
        local data = ccIDs[x]
        local ccID = data[1]
        local ccPPQPOS = data[2]
        local originalMsg2 = data[3]
        local originalMsg3 = data[4]
        
        local lsb, msb
        if centsDiff ~= 0 then
          local originalEnvVal = originalMsg2 + (originalMsg3*128)
          
          --get envDiff for first point, then apply to rest of points
          if x == 1 then --assumes point attached to start of note (TO FIX)
            local originalFirstEnvPointVal = originalEnvVal
            local newFirstEnvPointVal = convertCentsToPitchBendEnvelopeValue(cents - midiNoteNum*100)
            envDiff = newFirstEnvPointVal - originalFirstEnvPointVal
            end
          
          local newEnvVal = originalEnvVal + envDiff
          if newEnvVal < 0 then
            newEnvVal = 0
            truncatedErrorMsg = true
            end
          if newEnvVal > 16383 then
            newEnvVal = 16383
            truncatedErrorMsg = true
            end
          
          lsb, msb = getPitchBendLSBMSB(newEnvVal)
          end
        
        if stretchSide == nil or stretchSide == 2 or (stretchSide == 0 and x == 1) or (stretchSide == 1 and x == getTableLen(ccIDs)) then
          reaper.MIDI_SetCC(take, ccID, selected, muted, ccPPQPOS+ppqposStartDiff, PITCHBENDCC, chan, lsb, msb, true)
          end
        
        if stretchSide == 0 and ccPPQPOS < noteStartPPQPOS then
          table.insert(pointsToDelete, ccID)
          end
        if stretchSide == 1 and ccPPQPOS > noteEndPPQPOS then
          table.insert(pointsToDelete, ccID)
          end
        end
      
      if truncatedErrorMsg then
        reaper.ShowConsoleMsg("Truncated pitch bends. Please increase your program pitch bend range!\n")
        end
        
      if not toSort then
        toSort = true
        end
      if not editedNotes then
        editedNotes = true
        end
      end
    
    function deleteNote(noteID)
      local _, _, _, noteStartPPQPOS, noteEndPPQPOS, chan = reaper.MIDI_GetNote(take, noteID)
      local ccIDs = getPitchBendPointIDs(noteID)
      reaper.MIDI_DeleteNote(take, noteID)
      for x=getTableLen(ccIDs), 1, -1 do
        local data = ccIDs[x]
        local ccID = data[1]
        reaper.MIDI_DeleteCC(take, ccID)
        end
        
      if not editedNotes then
        editedNotes = true
        end
      end
      
    function getNotePitchBendEnvelopeValue(time, chan, startCCID)
      local val, startCCID = getCCValueAtTime(take, PITCHBENDCC, 0, time, startCCID)
      return val, startCCID
      end
    
    function setNotePitchBend(noteID, val)
      local _, _, _, noteStartPPQPOS, noteEndPPQPOS, chan, pitch, _ = reaper.MIDI_GetNote(take, noteID)
      reaper.MIDI_InsertCC(take, false, false, noteStartPPQPOS, PITCHBENDCC, chan, val, 0) 
      end
    
    function convertCentsToPitchBendEnvelopeValue(centsFromPitch)
      local semitones = centsFromPitch/100
      local envVal
      if semitones < 0 then
        envVal = math.max(0, convertRange(semitones, getProgramPitchBendDown()*(-1), 0, 0, 8192))
      else
        envVal = math.min(16383, convertRange(semitones, 0, getProgramPitchBendUp(), 8192, 16383))
        end
      return math.floor(envVal+0.5)
      end
    
    function convertPitchBendEnvelopeValueToCents(envVal)
      local semitones
      if envVal < 8192 then
        semitones = convertRange(envVal, 0, 8192, getProgramPitchBendDown()*(-1), 0)
      else
        semitones = convertRange(envVal, 8192, 16383, 0, getProgramPitchBendUp())
        end
      return semitones*100
      end
      
    function getPitchBendCents(time, chan, startCCID)
      local envVal, startCCID = getNotePitchBendEnvelopeValue(time, chan, startCCID)
      return convertPitchBendEnvelopeValueToCents(envVal), startCCID
      end
    
    function setNotePitchBendCents(noteID, cents)
      local envVal = convertCentsToPitchBendEnvelopeValue(cents)
      local _, _, _, noteStartPPQPOS, noteEndPPQPOS, chan, pitch, _ = reaper.MIDI_GetNote(take, noteID)
      reaper.MIDI_InsertCC(take, false, false, noteStartPPQPOS, PITCHBENDCC, chan, envVal, 0) 
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
    
    function mousePositionInCircle(xPos, yPos, radius)
      local squaredDistance = (mouseX - xPos)^2 + (mouseY - yPos)^2
      local squaredRadius = radius^2
      return (squaredDistance < squaredRadius)
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
    
    --reaper.ShowConsoleMsg("TEST: " .. noteEditor_yMin .. " " .. noteEditor_yMax .. "\n")
      
    function setTuningGUID(isSnap, guid)
      local basePitchName = getBasePitchName(isSnap)
      
      setTextEvent("tuning" .. math.floor(boolToNumber(isSnap)), guid)
      
      setTuningModified(isSnap, false)
      
      --set temp file
      local fileText, fileName = getTuningFileFromGUID(guid)
      local dotIndex = string.find(fileName, "%.")
      fileText = "NAME " .. string.sub(fileName, 1, dotIndex-1) .. "\n" .. fileText
      
      local fileName = reaper.guidToString(mediaItemGUID, "") .. "_" .. math.floor(boolToNumber(isSnap)) .. ".txt"
      
      local file = io.open(getTempDirectory() .. fileName, "w+")
      file:write(fileText)
      file:close()
      
      local pitchNames = getPitchNames(isSnap)
      for pitchID=1, getTableLen(pitchNames) do
        if pitchNames[pitchID] == basePitchName then
          setBasePitchID(isSnap, pitchID)
          break
          end
        end
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
    
    function getCentsRangeMin()
      return getTextEvent("centsmin", MINCENTS)
      end
    
    function getCentsRangeMax()
      return getTextEvent("centsmax", MAXCENTS)
      end
    
    function setCentsRangeMin(val)
      if val < MINCENTS then
        val = MINCENTS
        end
      val = math.min(val, getCentsRangeMax()-100)
      setTextEvent("centsmin", val)
      end
      
    function setCentsRangeMax(val)
      if val > MAXCENTS then
        val = MAXCENTS
        end
      val = math.max(val, getCentsRangeMin()+100)
      setTextEvent("centsmax", val)
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
    
    function getVelocityView()
      return getTextEvent("velocityview", 0)
      end
    
    function setVelocityView(val)
      setTextEvent("velocityview", val)
      end
    
    function getPitchUnit(isSnap)
      return getTextEvent("pitchunit" .. math.floor(boolToNumber(isSnap)), 0)
      end
    
    function setPitchUnit(isSnap, val)
      setTextEvent("pitchunit" .. math.floor(boolToNumber(isSnap)), val)
      end
      
    function convertVelocityViewToText(velocityView)
      local list = {"Bar", "Circle"}
      return list[velocityView+1]
      end
    
    function convertPitchUnitToText(pitchUnit)
      local list = {"Consecutive view", "Scale view", "Fraction", "Equal Divisions"}
      return list[pitchUnit+1]
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
      local val = convertRange(windowPos, min, max, visibleStartCents, visibleEndCents)
      if val < 0 then
        val = 0
        end
      
      val = round(val, 2) --floating point error
      return val
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
    
    function getCents(pitchID, isSnap)
      local pitchList
      
      if isSnap then
        pitchList = getSnapPitchList()
      else
        pitchList = getBackgroundPitchList()
        end
      
      local data = snapPitchList[pitchID]
      local pitchPosMin = data[1]
      return windowPosToCents(pitchPosMin)
      end
    
    function getPitchIDFromWindowPos(windowPos)
      local snapPitchList = getSnapPitchList()
      
      for pitchID=1, getTableLen(snapPitchList) do
        local data = snapPitchList[pitchID]
        
        local pitchPosMin = data[1]
        local pitchPosMax = data[2]
        
        --reaper.ShowConsoleMsg(pitchPosMin .. " " .. pitchPosMax .. "\n")
        
        local condition
        if viewMode == HORIZONTAL then
          condition = (windowPos > pitchPosMax and windowPos <= pitchPosMin)
        else
          condition = (windowPos >= pitchPosMin and windowPos < pitchPosMax)
          end
        if condition then
          return pitchID
          end
        end
      end
      
    function getPitchID(cents)
      local windowPos = centsToWindowPos(cents)
      return getPitchIDFromWindowPos(windowPos)
      end
      
    function snapCents(cents)
      local snapPitchList = getSnapPitchList()
      
      local pitchID = getPitchID(cents)
      if pitchID == nil then
        reaper.ShowConsoleMsg(getTableLen(snapPitchList) .. " " .. cents .. "\n")
        debug_printStack()
        end
      local data = snapPitchList[pitchID]
      local pitchPosMin = data[1]
      local pitchPosMax = data[2]

      return windowPosToCents(pitchPosMin)
      end
      
    function getHoveredPitchID() --1-based
      if hoveringNoteEditor then
        local snapPitchList = getSnapPitchList()
        local windowPos
        if viewMode == HORIZONTAL then
          windowPos = mouseY
        else
          windowPos = mouseX
          end
        return getPitchIDFromWindowPos(windowPos)
        end
      end
    
    function getHoveredCents(snap)
      if hoveringNoteEditor then
        local val
        if viewMode == HORIZONTAL then
          val = windowPosToCents(mouseY)
        else
          val = windowPosToCents(mouseX)
          end
        
        if snap then
          val = snapCents(val)
          end
        
        val = round(val, 2) --floating point error
        return val
        end
      end
      
    function getHoveredTime()
      if hoveringNoteEditor then
        if viewMode == HORIZONTAL then
          return windowPosToTime(mouseX)
          end
        return windowPosToTime(mouseY)
        end
      end
    
    function isStartOfPitchEnvelopeBlank()
      local ccID = 0
      local testCount = 0
      while true do
        local retval, _, _, ppqpos, chanMsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, ccID)
        if not retval then
          return true
          end
      
        if ppqpos > 1 then
          return true
          end
        
        if chanMsg == PITCHBENDCC then
          return false
          end
          
        ccID = ccID + 1
        
        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        end
      return true
      end
            
    function addSizeButton()
      local pitchScrollbarPos = getPitchScrollbarPos()
      local timeScrollbarPos = getTimeScrollbarPos()
      
      local width, height
      if viewMode == HORIZONTAL then
        width = timeWindowSize
        height = pitchWindowSize
      else
        width = pitchWindowSize
        height = timeWindowSize
        end
      
      --[[
      reaper.ImGui_PushID(ctx, 1)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), BLACK)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), BLACK)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), BLACK)
      reaper.ImGui_Button(ctx, "##size button", width, height)
      reaper.ImGui_PopStyleColor(ctx, 3)
      reaper.ImGui_PopID(ctx)
      ]]--
      
      reaper.ImGui_Dummy(ctx, width, height)
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
      local function getScrollMax(isVertical)
        if isVertical then
          return reaper.ImGui_GetScrollMaxY(ctx)
        else
          return reaper.ImGui_GetScrollMaxX(ctx)
          end
        end
      local function getModifierKey(isVertical)
        if isVertical then
          return reaper.ImGui_Key_LeftCtrl()
        else
          return reaper.ImGui_Key_LeftAlt()
          end
        end
      local function getWindowSize(isVertical)
        if isVertical then
          return windowSizeY
        else
          return windowSizeX
          end
        end
        
      local function pitchScrollbar(isVertical)
        local scrollbarSize = getPitchScrollbarSize()
        local scrollbarPos = getPitchScrollbarPos()
        
        local windowSize = getWindowSize(isVertical)
        
        centsRangeStart = getCentsRangeMin()
        centsRangeEnd = getCentsRangeMax()
        
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
        
        if openedMidiEditor == 1 then
          local wheel = reaper.ImGui_GetMouseWheel(ctx)
          local key = getModifierKey(isVertical)
          if reaper.ImGui_IsKeyDown(ctx, key) then
            if wheel ~= 0 then
              if isVertical then
                scrollbarSize = scrollbarSize - wheel/100
              else
                scrollbarSize = scrollbarSize - wheel/100
                end
              setPitchScrollbarSize(scrollbarSize)
              local newScrollStored = math.floor((windowSize/scrollbarSize)*scrollbarPos+0.5)
              setScroll(isVertical, newScrollStored)
              end
          elseif noModifiersHeldDown and wheel ~= 0 and isVertical and hoveringNoteEditor then
            scrollbarPos = scrollbarPos - wheel/100
            setPitchScrollbarPos(scrollbarPos)
            local scrollStored = math.floor(pitchWindowSize*scrollbarPos+0.5)
            setScroll(isVertical, scrollStored)
          elseif not reaper.ImGui_IsKeyReleased(ctx, key) then
            if scroll ~= scrollStored then
              setPitchScrollbarPos(scroll/pitchWindowSize)
              end
            end
          
          pitchWindowSize = windowSize/scrollbarSize
          end
        end
        
      local function timeScrollbar(isVertical)
        local scrollbarSize = getTimeScrollbarSize()
        local scrollbarPos = getTimeScrollbarPos()
        
        local windowSize = getWindowSize(isVertical)
        
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
          local wheel = reaper.ImGui_GetMouseWheel(ctx)
          local key = getModifierKey(isVertical)
          if reaper.ImGui_IsKeyDown(ctx, key) then
            if wheel ~= 0 then
              if isVertical then
                scrollbarSize = scrollbarSize - wheel/100
              else
                scrollbarSize = scrollbarSize - wheel/100
                end
              setTimeScrollbarSize(scrollbarSize)
              local newScrollStored = math.floor((windowSize/scrollbarSize)*scrollbarPos+0.5)
              setScroll(isVertical, newScrollStored)
              end
          elseif noModifiersHeldDown and wheel ~= 0 and isVertical and hoveringNoteEditor then
            scrollbarPos = scrollbarPos - wheel/100
            setTimeScrollbarPos(scrollbarPos)
            local scrollStored = math.floor(timeWindowSize*scrollbarPos+0.5)
            setScroll(isVertical, scrollStored)
          else
            if scroll ~= scrollStored and not (playing and autoscrollSetting) then
              setTimeScrollbarPos(scroll/timeWindowSize)
              end
            end
          
          timeWindowSize = windowSize/scrollbarSize
          end
        end
      
      pitchScrollbar(viewMode==0)
      timeScrollbar(viewMode==1)
      end
      
    function drawToolbar()
      drawBackground(toolbar_xMin, toolbar_yMin, toolbar_xMax, globalSettings_yMax, BLACK)
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
        if imgName == "centered" then
          isImageOn = isCentered
          end
        if imgName == "blur" then
          isImageOn = blurPitchGrid
          end
        if imgName == "showVelocity" then
          isImageOn = showVelocity
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
      
      local backgroundPitchList = getBackgroundPitchList()
      
      debug_funcTime("get background pitch list")
            
      local nativePrevColor
      
      for x=1, getTableLen(backgroundPitchList) do
        debug_funcTime("stuff")
              
        local data = backgroundPitchList[x]
        
        local pitchPosMin = data[1]
        local pitchPosMax = data[2]
        local name = data[3]
        local color = data[4]
        local isOctave = data[5]
        
        local xMin, yMin, xMax, yMax
        if viewMode == HORIZONTAL then
          xMin = windowPos_timeMin 
          yMin = pitchPosMax
          xMax = windowPos_timeMax
          yMax = pitchPosMin
          if isCentered then
            yMin = yMin + (math.abs(pitchPosMax-pitchPosMin)/2)
            yMax = yMax + (math.abs(pitchPosMax-pitchPosMin)/2)
            end
        else
          xMin = pitchPosMin
          yMin = windowPos_timeMin
          xMax = pitchPosMax
          yMax = windowPos_timeMax
          if isCentered then
            xMin = xMin - (math.abs(pitchPosMax-pitchPosMin)/2)
            xMax = xMax - (math.abs(pitchPosMax-pitchPosMin)/2)
            end
          end
        
        debug_funcTime("get pitch grid lines coor")
          
        local b, g, r = reaper.ColorFromNative(color)
        
        local nativeColor = hexColor(r, g, b)
        if nativePrevColor ~= nil and blurPitchGrid then
          --blur
          local rectXMin = xMin
          local rectXMax = xMax
          local rectYMin = yMin
          local rectYMax = yMax
          
          local col_topL, col_topR, col_botL, col_botR
          if viewMode == HORIZONTAL then
            col_topL = nativeColor
            col_topR = nativeColor
            col_botL = nativePrevColor
            col_botR = nativePrevColor
            rectYMin = rectYMin + (math.abs(pitchPosMax-pitchPosMin)/2)
            rectYMax = rectYMax + (math.abs(pitchPosMax-pitchPosMin)/2)
          else
            col_topL = nativePrevColor
            col_topR = nativeColor
            col_botL = nativeColor
            col_botR = nativePrevColor
            rectXMin = rectXMin - (math.abs(pitchPosMax-pitchPosMin)/2)
            rectXMax = rectXMax - (math.abs(pitchPosMax-pitchPosMin)/2)
            end
          reaper.ImGui_DrawList_AddRectFilledMultiColor(drawList, rectXMin, rectYMin, rectXMax, rectYMax, col_topL, col_topR, col_botL, col_botR) 
        else
          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, nativeColor)
          end
        
        debug_funcTime("get pitch grid lines rect color")
        
        if mousePositionInRect(xMin, yMin, xMax, yMax) then
          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, hexColor(255, 0, 0, 45))
          end
        
        debug_funcTime("get pitch grid lines highlight color")
        
        local lineColor
        if isOctave then
          lineColor = BLACK
        else
          lineColor = hexColor(230, 230, 230)
          end
        
        if viewMode == HORIZONTAL then
          reaper.ImGui_DrawList_AddLine(drawList, xMin, pitchPosMin, xMax, pitchPosMin, lineColor)
        else
          reaper.ImGui_DrawList_AddLine(drawList, pitchPosMin, yMin, pitchPosMin, yMax, lineColor)
          end
        
        nativePrevColor = nativeColor
        
        debug_funcTime("get pitch grid lines line color")
        end
      end
      
    function drawTimeGridLines()
      local measureNumbersTable = {}
      
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
      
      return measureNumbersTable
      end
    
    function drawMeasureNumbers(measureNumbersTable)
      local xMin, yMin, xMax, yMax
      local top
      if viewMode == HORIZONTAL then
        xMin = noteEditor_xMin
        yMin = tuningSettings_yMax
        xMax = noteEditor_xMax
        yMax = noteEditor_yMin
        top = yMin
      else
        xMin = window_xMin
        yMin = tuningSettings_yMax
        xMax = noteEditor_xMin
        yMax = window_yMax
        top = xMin
        end
      
      drawBackground(xMin, yMin, xMax, yMax, hexColor(210, 210, 210))

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
    
    function getNoteName(isSnap, pitchID)
      local noteName = getPitchList(isSnap)[pitchID][3]
      return noteName
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
      
      local backgroundPitchList = getBackgroundPitchList()
      
      for pitchID=1, getTableLen(backgroundPitchList) do
        local data = backgroundPitchList[pitchID]
        
        local pitchPosMin = data[1]
        local pitchPosMax = data[2]
        local noteName = data[3]
        
        local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, noteName, 0, 0)
        
        local rectSizePitch = pitchPosMax-pitchPosMin
        local xPos, yPos
        if viewMode == HORIZONTAL then
          xPos = noteEditor_xMin-textSizeX-8
          yPos = pitchPosMin+(rectSizePitch - textSizeY)/2
          if isCentered then
            yPos = yPos + (math.abs(pitchPosMax-pitchPosMin)/2)
            end
          currentPos = yPos
        else
          xPos = pitchPosMin+(rectSizePitch - textSizeX)/2
          yPos = windowPos_timeMax + 5
          if isCentered then
            xPos = xPos - (math.abs(pitchPosMax-pitchPosMin)/2)
            end
          currentPos = xPos
          end
        
        local function add()
          reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, WHITE, noteName)
          
          local xMin, yMin, xMax, yMax
          if viewMode == HORIZONTAL then
            xMin = window_xMin
            yMin = pitchPosMax
            xMax = noteEditor_xMin
            yMax = pitchPosMin
          else
            xMin = pitchPosMin
            yMin = noteEditor_yMax
            xMax = pitchPosMax
            yMax = window_yMax
            end
          
          if mousePositionInRect(xMin, yMin, xMax, yMax) then
            if rightMouseDown then
              --pitch properties (TODO)
              --[[
              reaper.ImGui_OpenPopup(ctx, "Color Picker") -- Open ImGui popup for color picker
              if reaper.ImGui_BeginPopupModal(ctx, "Color Picker") then -- Begin a modal popup for color picker
                -- Implement your color picker logic here, using ImGui's built-in widgets
                -- Update myColor with the selected color
                -- Close the color picker popup when done
                if reaper.ImGui_Button(ctx, "OK") then
                  colorPickerVisible = false
                  reaper.ImGui_CloseCurrentPopup(ctx)
                  end
                reaper.ImGui_EndPopup(ctx) -- End the color picker popup
                end
              --]]
              end
            end
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
      
    function handleNotes()
      local notesToSet = {}
      
      --calculate drag
      if hoveringNoteEditor then
        if mouseLeftClicked then
          if viewMode == HORIZONTAL then
            originalMouseTime = windowPosToTime(mouseX)
            originalMouseCents = windowPosToCents(mouseY)
          else
            originalMouseCents = windowPosToCents(mouseX)
            originalMouseTime = windowPosToTime(mouseY)
            end
          --reaper.ShowConsoleMsg(originalMouseCents - snapCents(originalMouseCents) .. "\n")
          originalMouseCentsSnapped = snapCents(originalMouseCents)
          end
        end
      if originalMouseCents ~= nil then
        if viewMode == HORIZONTAL then
          currentMouseWindowCentsDrag = mouseY - centsToWindowPos(originalMouseCents)
          currentMouseWindowTimeDrag = mouseX - timeToWindowPos(originalMouseTime)
          currentMouseCentsDrag = windowPosToCents(mouseY) - originalMouseCents
          currentMouseCentsDragSnapped = windowPosToCents(mouseY) - originalMouseCentsSnapped
          currentMouseTimeDrag = windowPosToTime(mouseX) - originalMouseTime
          currentMousePPQPOSDrag = reaper.MIDI_GetPPQPosFromProjTime(take, windowPosToTime(mouseX)) - reaper.MIDI_GetPPQPosFromProjTime(take, originalMouseTime)
        else
          currentMouseWindowCentsDrag = mouseX - centsToWindowPos(originalMouseCents)
          currentMouseWindowTimeDrag = mouseY - timeToWindowPos(originalMouseTime)
          currentMouseCentsDrag = windowPosToCents(mouseX) - originalMouseCents
          currentMouseCentsDragSnapped = windowPosToCents(mouseX) - originalMouseCentsSnapped
          currentMouseTimeDrag = windowPosToTime(mouseY) - originalMouseTime
          currentMousePPQPOSDrag = reaper.MIDI_GetPPQPosFromProjTime(take, windowPosToTime(mouseY)) - reaper.MIDI_GetPPQPosFromProjTime(take, originalMouseTime)
          end
        end
      
      debug_funcTime("calculate drag")
      
      local noteTable = {}
      local noteIDToDelete
      local foundEdge = false  
      
      executeMotion = (noteMovement ~= nil and mouseLeftReleased)
        
      --check if pitch envelope starts with a point; if not, add 0-point
      if isStartOfPitchEnvelopeBlank() then
        --insertPitchBend(false, false, 1, 0, 8192)
        end
        
      local noteID = 0
      local testCount = 0
      while true do
        debug_funcTime("handle notes stuff")
        
        local retval, selected, muted, noteStartPPQPOS, noteEndPPQPOS, chan, midiNoteNum, vel = reaper.MIDI_GetNote(take, noteID)
        if not retval then
          break
          end
        local originalNoteStartPPQPOS = noteStartPPQPOS
        local originalNoteEndPPQPOS = noteEndPPQPOS
        local originalNoteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, originalNoteStartPPQPOS)
        local originalNoteEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, originalNoteEndPPQPOS)
        local originalNoteStartTimePos, originalNoteEndTimePos
        if viewMode == HORIZONTAL then
          originalNoteStartTimePos = timeToWindowPos(originalNoteStartTime)
          originalNoteEndTimePos = timeToWindowPos(originalNoteEndTime)
        else
          originalNoteStartTimePos = timeToWindowPos(originalNoteEndTime)
          originalNoteEndTimePos = timeToWindowPos(originalNoteStartTime)
          end
        local originalCents = getCentsFromNote(noteID)
        local originalVel = vel
        
        local drawnNoteStartPPQPOS = noteStartPPQPOS
        local drawnNoteEndPPQPOS = noteEndPPQPOS
        local drawnCents = originalCents
        
        local stretchSide
        
        debug_funcTime("handle notes original values")
        
        --animate/execute dragging
        if noteMovement ~= nil and noModifiersHeldDown then
          if noteMovement == STRETCHSTARTOFNOTES and (selected or hoveringStartEdgeNoteID == noteID) then
            stretchSide = 0
            drawnNoteStartPPQPOS = drawnNoteStartPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              drawnNoteStartPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteStartPPQPOS)))
              end
            end
          if noteMovement == STRETCHENDOFNOTES and (selected or hoveringEndEdgeNoteID == noteID) then
            stretchSide = 1
            drawnNoteEndPPQPOS = drawnNoteEndPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              drawnNoteEndPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteEndPPQPOS)))
              end
            end
          if noteMovement == DRAGNOTES and selected then
            stretchSide = 2
            drawnNoteStartPPQPOS = drawnNoteStartPPQPOS + currentMousePPQPOSDrag
            drawnNoteEndPPQPOS = drawnNoteEndPPQPOS + currentMousePPQPOSDrag
            if snapEnabled then
              local time = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteStartPPQPOS)
              local originalPPQPOS = drawnNoteStartPPQPOS
              drawnNoteStartPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, time))
              drawnNoteEndPPQPOS = drawnNoteEndPPQPOS + (drawnNoteStartPPQPOS - originalPPQPOS)
              end
            drawnCents = drawnCents + currentMouseCentsDragSnapped
            drawnCents = snapCents(drawnCents)
            end
          
          if noteMovement == ADJUSTVELOCITY and (selected or hoveringTopEdgeNoteID == noteID or hoveringBottomEdgeNoteID == noteID) then
            local velocityChange = math.floor(currentMouseWindowCentsDrag+0.49)
            if viewMode == HORIZONTAL then
              vel = vel - velocityChange
            else
              vel = vel + velocityChange
              end
            if vel > 127 then
              vel = 127
              end
            if vel < 1 then
              vel = 1
              end
            end
              
          if executeMotion then
            table.insert(notesToSet, {noteID, selected, muted, drawnNoteStartPPQPOS, drawnNoteEndPPQPOS, chan, drawnCents, vel, stretchSide})
            end
          end
        
        debug_funcTime("handle notes animate dragging")
        
        local absoluteCentsDiff = drawnCents - originalCents
        
        local drawnNoteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteStartPPQPOS)
        local drawnNoteEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteEndPPQPOS)
        
        local drawnNoteStartTimePos, drawnNoteEndTimePos
        if viewMode == HORIZONTAL then
          drawnNoteStartTimePos = timeToWindowPos(drawnNoteStartTime)
          drawnNoteEndTimePos = timeToWindowPos(drawnNoteEndTime)
        else
          drawnNoteStartTimePos = timeToWindowPos(drawnNoteEndTime)
          drawnNoteEndTimePos = timeToWindowPos(drawnNoteStartTime)
          end
        
        local snapPitchList = getSnapPitchList()
        local pitchID = getPitchID(drawnCents)
        local data = snapPitchList[pitchID]
        local drawnCentsPosMin = data[1]
        local drawnCentsPosMax = data[2]
        
        local color
        local alpha = 215
        if selected then
          color = hexColor(255, 40, 255, alpha)
          local h, s, v = reaper.ImGui_ColorConvertRGBtoHSV(1, 40/255, 1)
        else
          color = hexColor(255, 40, 60, alpha)
          local h, s, v = reaper.ImGui_ColorConvertRGBtoHSV(1, 40/255, 60/255)
          end
        
        local hoveringNote
        
        local timeDiff = drawnNoteStartTime - originalNoteStartTime
        
        debug_funcTime("handle notes drawn values")
        
        local function getNotePixels(noteID)
          debug_funcTime("handle notes stuff")
          
          local pitchID = getPitchID(drawnCents)
          local data = snapPitchList[pitchID]
          local drawnCentsPosMin = data[1]
          local drawnCentsPosMax = data[2]
          
          ---
          
          local pixelPosTable = {}
          local velocityCircleValues
          local noteNameValues
          local velocityBarValues
          
          local visibleWindowPosStart = timeToWindowPos(visibleStartTime)
          local visibleWindowPosEnd = timeToWindowPos(visibleEndTime)
          
          debug_funcTime("handle notes timetowindowpos")
          
          local pixelPosStart, pixelPosEnd
          local minVisibleTimePos, maxVisibleTimePos
          local numPixels
          if viewMode == HORIZONTAL then
            pixelPosStart = math.max(drawnNoteStartTimePos, visibleWindowPosStart)
            pixelPosEnd = math.min(drawnNoteEndTimePos, visibleWindowPosEnd)
            minVisibleTimePos = pixelPosStart
            maxVisibleTimePos = pixelPosEnd
            numPixels = math.floor(maxVisibleTimePos-minVisibleTimePos + 0.5)
          else
            pixelPosStart = math.min(drawnNoteStartTimePos, visibleWindowPosStart)
            pixelPosEnd = math.max(drawnNoteEndTimePos, visibleWindowPosEnd)
            minVisibleTimePos = pixelPosEnd
            maxVisibleTimePos = pixelPosStart
            numPixels = math.floor(minVisibleTimePos-maxVisibleTimePos + 0.5)
            end
          
          debug_funcTime("handle notes start of pixel loop")
          
          local startCCID = 0
          local startCCID_H = 0
          local startCCID_S = 0
          local startCCID_V = 0
          local startCCID_NOTESIZE = 0
          local startCCID_ALPHA = 0
          
          for pixelID=0, numPixels-1 do
            debug_funcTime("handle notes stuff")
            
            local timePos
            if viewMode == HORIZONTAL then
              timePos = minVisibleTimePos + pixelID
            else
              timePos = minVisibleTimePos - pixelID
              end
            local time = windowPosToTime(timePos)
            
            debug_funcTime("handle notes window pos to time")
            
            local cents
            if stretchSide == 0 and timePos < drawnNoteStartTimePos then
              cents, startCCID = getCentsFromNote(noteID, originalNoteStartTime, startCCID)
            elseif stretchSide == 1 and timePos > drawnNoteEndTimePos then
              cents, startCCID = getCentsFromNote(noteID, originalNoteEndTime, startCCID)
            else
              cents, startCCID = getCentsFromNote(noteID, time - timeDiff, startCCID)
              cents = cents + absoluteCentsDiff       
              end

            debug_funcTime("handle notes get cents from note")
            
            local drawnCentsPos = centsToWindowPos(cents)
            
            debug_funcTime("handle notes centstowindowpos")
            
            local function processCC(ccNum, startCCID, defaultNormal, defaultSelected)
              local val
              if ccNum > 0 then
                val, startCCID = getCCValueAtTime(take, 176, chan, time, startCCID, ccNum)
                val = val/127
              else
                if selected and defaultSelected then
                  val = defaultSelected
                else
                  val = defaultNormal
                  end
                end
              return val, startCCID
              end
            
            local fullPitchSize = math.abs(drawnCentsPosMin-drawnCentsPosMax)
            
            local noteH, noteS, noteV, pitchSize, noteAlpha
            noteH, startCCID_H = processCC(cc_NOTEH, startCCID_H, 0.98449611663818, 0.83333331346512)
            noteS, startCCID_S = processCC(cc_NOTES, startCCID_S, 0.84313726425171)
            noteV, startCCID_V = processCC(cc_NOTEV, startCCID_V, 1)
            pitchSize, startCCID_NOTESIZE = processCC(cc_NOTESIZE, startCCID_NOTESIZE, 1)
            noteAlpha, startCCID_ALPHA = processCC(cc_NOTEALPHA, startCCID_ALPHA, 1)
            
            pitchSize = fullPitchSize * pitchSize
            
            debug_funcTime("handle notes calculate note colors")
            
            local xMin, yMin, xMax, yMax
            if viewMode == HORIZONTAL then
              xMin = timePos
              yMin = drawnCentsPos - pitchSize
              xMax = timePos + 1
              yMax = drawnCentsPos
              if isCentered then
                yMin = yMin + pitchSize/2
                yMax = yMax + pitchSize/2
                end
            else
              xMin = drawnCentsPos
              yMin = timePos - 1
              xMax = drawnCentsPos + pitchSize
              yMax = timePos
              if isCentered then
                xMin = xMin - pitchSize/2
                xMax = xMax - pitchSize/2
                end
              end
              
            table.insert(pixelPosTable, {xMin, yMin, xMax, yMax, noteH, noteS, noteV, noteAlpha})
            
            debug_funcTime("handle notes insert pixel pos table data")
            
            if not hoveringNote and mousePositionInRect(xMin, yMin, xMax, yMax) then
              hoveringNote = true
              end
            
            if hoveringNoteEditor and noModifiersHeldDown then
              local err = 4
              
              --start edge
              local condition
              if viewMode == HORIZONTAL then
                condition = (pixelID == 0 and mousePositionInRect(xMin-err, yMin, xMin+err, yMax))
              else
                condition = (pixelID == 0 and mousePositionInRect(xMin, yMax-err, xMax, yMax+err))
                end
              if condition then
                hoveringStartEdgeNoteID = noteID
                hoveringEndEdgeNoteID = nil
                foundEdge = true
                end
                
              --end edge
              local condition
              if viewMode == HORIZONTAL then
                condition = (pixelID == numPixels-1 and mousePositionInRect(xMax-err, yMin, xMax+err, yMax))
              else
                condition = (pixelID == numPixels-1 and mousePositionInRect(xMin, yMin-err, xMax, yMin+err))
                end
              if condition then
                hoveringStartEdgeNoteID = nil
                hoveringEndEdgeNoteID = noteID
                foundEdge = true
                end
                
              --top edge
              local condition
              if viewMode == HORIZONTAL then
                condition = mousePositionInRect(xMin, yMin-err, xMax, yMin+err)
              else
                condition = mousePositionInRect(xMin-err, yMin, xMin+err, yMax)
                end
              if condition then
                hoveringTopEdgeNoteID = noteID
                hoveringBottomEdgeNoteID = nil
                foundEdge = true
                end
                
              --bottom edge
              local condition
              if viewMode == HORIZONTAL then
                condition = mousePositionInRect(xMin, yMin-err, xMax, yMin+err)
              else
                condition = mousePositionInRect(xMax-err, yMin, xMax+err, yMax)
                end
              if condition then
                hoveringTopEdgeNoteID = nil
                hoveringBottomEdgeNoteID = noteID
                foundEdge = true
                end
              end
            
            if pixelID == 0 then
              --draw velocity circle
              local radius = pitchSize/2
              local barSize = 7
              local r = 0
              local g = 0
              local b = 0
              local alpha = 200
              
              if showVelocityCircles then
                if viewMode == HORIZONTAL then
                  velocityCircleValues = {xMin, yMin+(yMax-yMin)/2, radius, r, g, b, alpha}
                else
                  velocityCircleValues = {xMin+(xMax-xMin)/2, yMax, radius, r, g, b, alpha}
                  end
                end
              
              if showVelocityBars then
                if viewMode == HORIZONTAL then
                  local rectCenter = yMin+(yMax-yMin)/2
                  local rectYMin = convertRange(vel, 1, 127, rectCenter, yMin)
                  local distance = rectCenter - rectYMin   
                  local rectYMinFlipped = rectCenter + distance
                  velocityBarValues = {xMin, rectYMin, xMin+barSize, rectYMinFlipped}
                else
                  local rectCenter = xMin+(xMax-xMin)/2
                  local rectXMin = convertRange(vel, 1, 127, rectCenter, xMin)
                  local distance = rectCenter - rectXMin
                  local rectXMinFlipped = rectCenter + distance
                  velocityBarValues = {rectXMin, yMax-barSize, rectXMinFlipped, yMax}
                  end
                end
                
              --get text values
              local noteName = getNoteName(true, pitchID)
              if noteMovement == ADJUSTVELOCITY and (selected or hoveringTopEdgeNoteID == noteID or hoveringBottomEdgeNoteID == noteID) then
                noteName = noteName .. " (" .. vel .. ")"
                end
              local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, noteName, 0, 0)
              local rectSizeX = xMax-xMin
              local rectSizeY = yMax-yMin
              local xPos, yPos
              if viewMode == HORIZONTAL then
                xPos = xMin+3
                yPos = yMin+(rectSizeY - textSizeY)/2
                if showVelocityCircles then
                  xPos = xPos + radius - 1
                  end
                if showVelocityBars then
                  xPos = xPos + barSize
                  end
              else
                xPos = xMin+(rectSizeX - textSizeX)/2 + 1 --extra 1 seems to help center the text
                yPos = yMax+(rectSizeY - textSizeY)/2 - 10
                if showVelocityCircles then
                  yPos = yPos - radius
                  end
                if showVelocityBars then
                  yPos = yPos - barSize
                  end
                end
              local color
              if selected then
                color = BLACK
              else
                color = WHITE
                end
              
              noteNameValues = {xPos, yPos, color, noteName}
              end
              
            debug_funcTime("handle notes end of pixelID")
            end
          
          return pixelPosTable, velocityCircleValues, noteNameValues, velocityBarValues
          end

        local pixelPosTable, velocityCircleValues, noteNameValues, velocityBarValues = getNotePixels(noteID)

        if mouseLeftClicked then
          if hoveringStartEdgeNoteID then
            noteMovement = STRETCHSTARTOFNOTES
            end
          if hoveringEndEdgeNoteID then
            noteMovement = STRETCHENDOFNOTES
            end
          if hoveringTopEdgeNoteID or hoveringBottomEdgeNoteID then
            noteMovement = ADJUSTVELOCITY
            end
          if hoveringNote and noteMovement == nil then
            noteMovement = DRAGNOTES
            mouseCursor = 0
            end
          end
        
        if noteMovement == DRAGNOTES then
          mouseCursor = 0
        else
          if hoveringStartEdgeNoteID or hoveringEndEdgeNoteID or noteMovement == STRETCHSTARTOFNOTES or noteMovement == STRETCHENDOFNOTES then
            if viewMode == HORIZONTAL then
              mouseCursor = reaper.ImGui_MouseCursor_ResizeEW()
            else
              mouseCursor = reaper.ImGui_MouseCursor_ResizeNS()
              end
          elseif hoveringTopEdgeNoteID or hoveringBottomEdgeNoteID or noteMovement == ADJUSTVELOCITY or noteMovement == ADJUSTBEZIER then
            if viewMode == HORIZONTAL then
              mouseCursor = reaper.ImGui_MouseCursor_ResizeNS()
            else
              mouseCursor = reaper.ImGui_MouseCursor_ResizeEW()
              end
          else
            mouseCursor = 0
            end
          end
          
        if mouseLeftReleased and reaper.ImGui_GetMouseCursor(ctx) ~= 0 then
          mouseCursor = 0
          end
          
        table.insert(noteTable, {
        drawnNoteStartPPQPOS,
        drawnNoteEndPPQPOS,
        drawnNoteStartTime,
        drawnNoteEndTime,
        midiNoteNum,
        selected,
        hoveringNote,
        drawnCents,
        pitchID,
        pixelPosTable,
        velocityCircleValues,
        noteNameValues,
        vel,
        velocityBarValues,
        chan,
        timeDiff
        })
        
        if selected then
          selectedNoteCount = selectedNoteCount + 1
          end
          
        noteID = noteID + 1

        testCount = testCount + 1
        if testCount > 100 then
          debug_printStack()
          end
        
        debug_funcTime("handle notes end of func")
        end
      
      --[[
      if executeMotion or mouseLeftReleased then
        noteMovement = nil
        
        originalMouseCents = nil
        originalMouseCentsSnapped = nil
        originalMouseTime = nil
        currentMouseWindowCentsDrag = 0
        currentMouseWindowTimeDrag = 0
        currentMouseCentsDrag = 0
        currentMouseCentsDragSnapped = 0
        currentMouseTimeDrag = 0
        end
      ]]--
      
      if not foundEdge and noteMovement == nil then
        hoveringStartEdgeNoteID = nil
        hoveringEndEdgeNoteID = nil
        hoveringTopEdgeNoteID = nil
        hoveringBottomEdgeNoteID = nil
        end
      
      
      if noteMovement == ADJUSTBEZIER and adjustBezierNoteID ~= nil then
        local ccID = getClosestPitchBendPointID(adjustBezierNoteID, adjustBezierTime, adjustBezierCents)
        local _, _, bez = reaper.MIDI_GetCCShape(take, ccID)
        local bezierChange = (getHoveredCents() - adjustBezierCents)/100
        if viewMode == HORIZONTAL then
          bez = bez + bezierChange
        else
          bez = bez - bezierChange
          end
        if bez > 1 then
          bez = 1
          end
        if bez < -1 then
          bez = -1
          end
        
        reaper.MIDI_SetCCShape(take, ccID, 5, bez, true)
        adjustBezierCents = getHoveredCents()
        if not altDown or mouseLeftReleased then
          noteMovement = nil
          adjustBezierNoteID = nil
          adjustBezierNoteTime = nil
          end
        end
        
      return noteTable, notesToSet
      end
    
    local function drawNotes(noteTable)
      local ccPointsList = {}
      local pointErr = 4
      local pointToEnter

      if not (leftMouseDown and ctrlDown) then
        noteIDToDrawPoints = nil
        end
        
      for noteID=0, getTableLen(noteTable)-1 do
        debug_funcTime("draw notes stuff")
        
        local data = noteTable[noteID+1]

        --define values
        local drawnNoteStartPPQPOS = data[1]
        local drawnNoteEndPPQPOS = data[2]
        local drawnNoteStartTime = data[3]
        local drawnNoteEndTime = data[4]
        local midiNoteNum = data[5]
        local selected = data[6]
        local hoveringNote = data[7]
        local cents = data[8]
        local pitchID = data[9]
        local pixelPosTable = data[10]
        local velocityCircleValues = data[11]
        local noteNameValues = data[12]
        local velocity = data[13]
        local velocityBarValues = data[14]
        local chan = data[15]
        local timeDiff = data[16]
        
        local pointIDs = getPointIDs(noteID)
        local ccIDToStart = 0
        local currentMsg2 = getCurrentMsg2Point()
        
        debug_funcTime("draw notes get pitch bend point IDs")
        
        local pointLineList = {}
        local topBorderList = {}
        local bottomBorderList = {}
        
        local len = getTableLen(pixelPosTable)
        for pixelID=0, len-1 do
          debug_funcTime("draw notes pixel loop start")
          
          local data = pixelPosTable[pixelID+1]
          local xMin = data[1]
          local yMin = data[2]
          local xMax = data[3]
          local yMax = data[4]
          local noteH = data[5]
          local noteS = data[6]
          local noteV = data[7]
          local noteAlpha = data[8]
          
          local timeAtPixel
          if viewMode == HORIZONTAL then
            timeAtPixel = windowPosToTime(xMin)
          else
            timeAtPixel = windowPosToTime(yMax)
            end
            
          local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(noteH, noteS, noteV)
          local color = hexColor(r*255, g*255, b*255, noteAlpha*255)
          
          --fill pixels
          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, color)
          
          --point line in note
          local lineColor = BLACK
          local radius = 1
          local thickness = 2
          local ccVal
          if currentPointCC then
            ccVal, ccIDToStart = getCCValueAtTime(take, 176, chan, timeAtPixel, ccIDToStart, currentMsg2)
            end
          local lineXMin, lineYMin, lineXMax, lineYMax
          if viewMode == HORIZONTAL then
            local yPos
            if currentPointCC then
              yPos = convertRange(ccVal, 0, 127, yMax, yMin)
            else
              yPos = yMin + (yMax-yMin)/2
              end
            lineXMin = xMin
            lineYMin = yPos
            lineXMax = xMax
            lineYMax = yPos
          else
            local xPos
            if currentPointCC then
              xPos = convertRange(ccVal, 0, 127, xMin, xMax)
            else
              xPos = xMin + (xMax-xMin)/2
              end
            lineXMin = xPos
            lineYMin = yMin
            lineXMax = xPos
            lineYMax = yMax
            end
          
          table.insert(pointLineList, {lineXMin, lineYMin, lineXMax, lineYMax, lineColor, thickness})
          
          --draw border around note
          local thickness = 3
          if viewMode == HORIZONTAL then
            table.insert(topBorderList, {xMin, yMin, xMax, yMin, BLACK, thickness})
            table.insert(bottomBorderList, {xMin, yMax, xMax, yMax, BLACK, thickness})
            if pixelID == 0 then
              reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMin, yMax, BLACK, thickness)
              end
            if pixelID == len-1 then
              reaper.ImGui_DrawList_AddLine(drawList, xMax, yMin, xMax, yMax, BLACK, thickness)
              end
          else
            table.insert(topBorderList, {xMin, yMin, xMin, yMax, BLACK, thickness})
            table.insert(bottomBorderList, {xMax, yMin, xMax, yMax, BLACK, thickness})
            if pixelID == 0 then
              reaper.ImGui_DrawList_AddLine(drawList, xMin, yMax, xMax, yMax, BLACK, thickness)
              end
            if pixelID == len-1 then
              reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMin, BLACK, thickness)
              end
            end
          
          debug_funcTime("draw notes draw note")
          
          --draw cc point
          local xPos
          local yPos
          if viewMode == HORIZONTAL then
            xPos = xMin
          else
            yPos = yMax
            end
          
          local foundPoint
          local radius = 4
          
          debug_funcTime("draw notes start pitch point loop")
          
          for x=1, getTableLen(pointIDs) do
            
            local data = pointIDs[x]
            
            local ccID = data[1]
            local originalCCPPQPOS = data[2]
            local originalMsg2 = data[3]
            local originalMsg3 = data[4]
            local selected = data[5]
            local drawnCCPPQPOS = originalCCPPQPOS
            local originalCCTime = reaper.MIDI_GetProjTimeFromPPQPos(take, originalCCPPQPOS)
            local drawnCCTime = originalCCTime
            
            if currentPointCC then
              if viewMode == HORIZONTAL then
                yPos = yMax - (yMax-yMin)*(originalMsg3/127)
              else
                xPos = xMin + (xMax-xMin)*(originalMsg3/127)
                end
            else
              if viewMode == HORIZONTAL then
                yPos = yMin + (yMax-yMin)/2
              else
                xPos = xMin + (xMax-xMin)/2
                end
              end
              
            local originalCCCents = midiNoteNum*100 + convertPitchBendEnvelopeValueToCents(originalMsg2+originalMsg3*128)

            local centsDiff = 0

            if noteMovement == DRAGNOTES then
              drawnCCTime = originalCCTime + timeDiff
              drawnCCPPQPOS = originalCCPPQPOS + currentMousePPQPOSDrag
              
              --animate/execute pitch bend points
              if selected and selectedNoteCount == 0 then
                local msg2, msg3
                if snapEnabled then
                  local time = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnCCPPQPOS)
                  drawnCCPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.SnapToGrid(0, time))
                  end
                drawnCCTime = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnCCPPQPOS)
                
                local drawnCCCents = originalCCCents + currentMouseCentsDrag
                if viewMode == HORIZONTAL then
                  yPos = centsToWindowPos(drawnCCCents)
                else
                  xPos = centsToWindowPos(drawnCCCents)
                  end
                  
                if currentPointCC then
                  --TODO: FIX RANGE
                  msg3 = math.floor(originalMsg3 + currentMouseCentsDrag)
                  msg3 = math.max(msg3, 0)
                  msg3 = math.min(msg3, 127)
                else
                  local _, envVal = convertCentsToMIDIValues(drawnCCCents, midiNoteNum)
                  msg2, msg3 = getPitchBendLSBMSB(envVal)
                  end
                if executeMotion then
                  reaper.MIDI_SetCC(take, ccID, nil, nil, drawnCCPPQPOS, nil, nil, msg2, msg3, true)
                  toSort = true
                  end
                end
              end
            
            if math.abs(drawnCCTime - timeAtPixel) < 0.01 then
              local color
              if selected then
                color = hexColor(200, 255, 45)
              else
                color = BLACK
                end
              
              table.insert(ccPointsList, {xPos, yPos, radius, color})
              
              if mousePositionInCircle(xPos, yPos, radius+pointErr) then
                hoveringPoint = true
                if mouseLeftClicked then
                  if ctrlDown then
                    reaper.MIDI_SetCC(take, ccID, flip(selected))
                  else
                    unselectAll()
                    reaper.MIDI_SetCC(take, ccID, true)
                    end
                  end
                if mouseLeftDoubleClicked then
                  table.insert(pointsToDelete, ccID)
                  toSort = true
                  end
                end
              
              table.remove(pointIDs, x)
              foundPoint = true
              break
              end
            
            end

          debug_funcTime("draw notes handle cc point")
          
          --insert cc point
          if not foundPoint then
            if (ctrlDown and mouseLeftClicked) or noteIDToDrawPoints == noteID then
              if mousePositionInRect(xMin, yMin, xMax, yMax) and not hoveringPoint then
                noteIDToDrawPoints = noteID
                end
              end
            if noteIDToDrawPoints == noteID and mousePositionInRect(xMin, yMin, xMax, yMax) then
              local time = getHoveredTime()
              if time ~= nil then
                local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, time)
                local hoveredCents = getHoveredCents()  
                local centsWindowPos = centsToWindowPos(hoveredCents)
                if currentPointCC then
                  local msg2 = getCurrentMsg2Point()
                  if msg2 > 0 then
                    local msg3
                    if viewMode == HORIZONTAL then
                      msg3 = convertRange(centsWindowPos, yMax, yMin, 0, 127)
                    else
                      msg3 = convertRange(centsWindowPos, xMin, xMax, 0, 127)
                      end
                    msg3 = math.floor(msg3)
                    msg3 = math.max(msg3, 0)
                    msg3 = math.min(msg3, 127)
                    pointToEnter = {ppqpos, chan, 176, msg2, msg3, noteID}
                    end
                else
                  local envVal = convertCentsToPitchBendEnvelopeValue(hoveredCents - midiNoteNum*100)
                  local lsb, msb = getPitchBendLSBMSB(envVal)
                  pointToEnter = {ppqpos, chan, PITCHBENDCC, lsb, msb, noteID}
                  end
                end
              end
            end
          
          debug_funcTime("draw notes insert cc point")
          end
        
        --draw top border
        for x=1, getTableLen(topBorderList) do
          local data = topBorderList[x]
          
          local xMin = data[1]
          local yMin = data[2]
          local xMax = data[3]
          local yMax = data[4]
          local color = data[5]
          local thickness = data[6]
          
          reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMax, color, thickness)
          end
        
        --draw bottom border
        for x=1, getTableLen(bottomBorderList) do
          local data = bottomBorderList[x]
          
          local xMin = data[1]
          local yMin = data[2]
          local xMax = data[3]
          local yMax = data[4]
          local color = data[5]
          local thickness = data[6]
          
          reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMax, color, thickness)
          end
          
        --draw point line
        for x=1, getTableLen(pointLineList) do
          local data = pointLineList[x]
          
          local xMin = data[1]
          local yMin = data[2]
          local xMax = data[3]
          local yMax = data[4]
          local color = data[5]
          local thickness = data[6]
          
          reaper.ImGui_DrawList_AddLine(drawList, xMin, yMin, xMax, yMax, color, thickness)
          
          local err = 3
          if altDown and mousePositionInRect(xMin-err, yMin-err, xMax+err, yMax+err) then
            noteMovement = ADJUSTBEZIER
            if mouseLeftClicked then
              adjustBezierNoteID = noteID
              adjustBezierTime = getHoveredTime()
              adjustBezierCents = getHoveredCents()
              end
            end
          end
          
        --draw velocity circle
        if velocityCircleValues ~= nil then
          local xPos = velocityCircleValues[1]
          local yPos = velocityCircleValues[2]
          local radius = velocityCircleValues[3]
          local r = velocityCircleValues[4]
          local g = velocityCircleValues[5]
          local b = velocityCircleValues[6]
          local alpha = velocityCircleValues[7]
          
          local emptyColor = hexColor(255, 255, 255, 64)
          local fillColor = hexColor(r, g, b, alpha)
          
          --empty fill
          reaper.ImGui_DrawList_AddCircleFilled(drawList, xPos, yPos, radius, emptyColor)
          --border
          reaper.ImGui_DrawList_AddCircle(drawList, xPos, yPos, radius, BLACK)
          --velocity fill
          local startAngle = math.pi*1.5
          local endAngle = math.pi*2 * velocity/127 + startAngle
          reaper.ImGui_DrawList_PathLineTo(drawList, xPos, yPos)
          reaper.ImGui_DrawList_PathArcTo(drawList, xPos, yPos, radius, startAngle, endAngle)
          reaper.ImGui_DrawList_PathFillConvex(drawList, fillColor)
          end
        
        --draw velocity bar
        if velocityBarValues ~= nil then
          local xMin = velocityBarValues[1]
          local yMin = velocityBarValues[2]
          local xMax = velocityBarValues[3]
          local yMax = velocityBarValues[4]
          local color = YELLOW
          
          reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, color)
          end
        
        debug_funcTime("draw notes draw velocity")
                
        --draw text inside note name
        if noteNameValues ~= nil then
          local xPos = noteNameValues[1]
          local yPos = noteNameValues[2]
          local color = noteNameValues[3]
          local noteName = noteNameValues[4]
          reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, color, noteName)
          end
        
        --handle clicking inside note editor
        if mouseLeftClicked and hoveringNoteEditor and noModifiersHeldDown and not hoveringPoint then
          if hoveringNote then
            if mouseLeftDoubleClicked then
              noteIDToDelete = noteID
            else
              selected = true
              setNote(noteID, selected)
              clickedAnyNote = true
              end
          else
            if not ctrlDown and selected and selectedNoteCount > 0 then
              setNote(noteID, false)
              end
            end
          end
          
        --handle releasing inside note editor
        if mouseLeftReleased and hoveringNoteEditor and not hoveringPoint then
          if selectedNoteCount > 0 then
            --[[
            selected = true
            setNote(noteID, selected)
            clickedAnyNote = true
            end
            --]]
            if hoveringNote then
              setNote(noteID, true)
            elseif not ctrlDown and selectedNoteCount > 0 then
              setNote(noteID, false)
              end
            end
          end
        end
        
      --handle double clicking inside note editor
      if mouseLeftDoubleClicked and hoveringNoteEditor and not hoveringPoint then
        if noteIDToDelete == nil then
          local startTime = getTime()
          if snapEnabled then
            time = reaper.SnapToGrid(0, startTime)
            end
          local grid, swing = reaper.MIDI_GetGrid(take)
          local endTime = startTime + reaper.TimeMap_QNToTime(grid)
          insertNote(true, false, reaper.MIDI_GetPPQPosFromProjTime(take, startTime), reaper.MIDI_GetPPQPosFromProjTime(take, endTime), 0, getHoveredCents(true), 127)
        else
          deleteNote(noteIDToDelete)
          end
        end
      
      --set edit cursor position
      if mouseLeftClicked and not clickedAnyNote and hoveringNoteEditor and not hoveringPoint then
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
        unselectAll()
        end
      
      debug_funcTime("draw notes handle clicking")
              
      if pointToEnter ~= nil then
        local pixelThreshold = 1
        local linearPixelThreshold = 15
        
        local ppqpos = pointToEnter[1]
        local chan = pointToEnter[2]
        local msg1 = pointToEnter[3]
        local msg2 = pointToEnter[4]
        local msg3 = pointToEnter[5]
        local noteID = pointToEnter[6]

        local pointIDs = getPointIDs(noteID)
        local len = getTableLen(pointIDs)
        for x=1, getTableLen(pointIDs) do
          local data = pointIDs[x]
          
          local ccID = data[1]
          local prevPPQPOS = data[2]
          local nextPPQPOS
          if x < len then
            local nextData = pointIDs[x+1]
            nextPPQPOS = nextData[2]
            end
          --reaper.ShowConsoleMsg(ppqpos .. " >= " .. prevPPQPOS .. " // " .. msg1 .. " " .. msg2 .. " " .. msg3 .. "\n")
          if ppqpos >= prevPPQPOS and (nextPPQPOS == nil or ppqpos <= nextPPQPOS) then
            local currentWindowPos = timeToWindowPos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)) 
            local prevWindowPos = timeToWindowPos(reaper.MIDI_GetProjTimeFromPPQPos(take, prevPPQPOS)) 
            local nextWindowPos
            if nextPPQPOS ~= nil then
              nextWindowPos = timeToWindowPos(reaper.MIDI_GetProjTimeFromPPQPos(take, nextPPQPOS)) 
              end
            local startDiff = currentWindowPos - prevWindowPos
            if startDiff > pixelThreshold and (nextWindowPos == nil or nextWindowPos - currentWindowPos > pixelThreshold) then
              reaper.MIDI_InsertCC(take, false, false, ppqpos, msg1, chan, msg2, msg3)
              reaper.MIDI_SetCCShape(take, ccID, 1, 0)
              toSort = true
              end
            break
            end
          end
        end
      
      debug_funcTime("draw notes point to enter")
              
      if executeMotion or mouseLeftReleased then
        noteMovement = nil
        
        originalMouseCents = nil
        originalMouseCentsSnapped = nil
        originalMouseTime = nil
        currentMouseWindowCentsDrag = 0
        currentMouseWindowTimeDrag = 0
        currentMouseCentsDrag = 0
        currentMouseCentsDragSnapped = 0
        currentMouseTimeDrag = 0
        end
        
      return ccPointsList
      end
    
    local function drawCCPoints(ccPointsList)
      for x=1, getTableLen(ccPointsList) do
        local data = ccPointsList[x]
        
        local xPos = data[1]
        local yPos = data[2]
        local radius = data[3]
        local color = data[4]
        
        reaper.ImGui_DrawList_AddCircleFilled(drawList, xPos, yPos, radius, color)
        end
      end
      
    function drawRegion()
      if mouseRightClicked and hoveringNoteEditor then
        regionCentsStart = getHoveredCents()
        regionTimeStart = getHoveredTime()
        regionCentsEnd = nil
        regionTimeEnd = nil
        end
      
      local hoveredCents = getHoveredCents()
      local hoveredTime = getHoveredTime()
      if hoveredCents ~= nil then
        regionCentsEnd = hoveredCents
        regionTimeEnd = hoveredTime
        end
        
      if regionCentsStart ~= nil and regionCentsEnd ~= nil then
        local window_pitch1 = centsToWindowPos(regionCentsStart)
        local window_pitch2 = centsToWindowPos(regionCentsEnd)
        local window_time1 = timeToWindowPos(regionTimeStart)
        local window_time2 = timeToWindowPos(regionTimeEnd)
        
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
          local centsMin = math.min(regionCentsStart, regionCentsEnd)
          local centsMax = math.max(regionCentsStart, regionCentsEnd)
          local timeMin = math.min(regionTimeStart, regionTimeEnd)
          local timeMax = math.max(regionTimeStart, regionTimeEnd)
          
          if ctrlDown then
            local msg1
            local msg2
            if currentPointCC then
              msg1 = 176
              msg2 = getCurrentMsg2Point()
            else
              msg1 = PITCHBENDCC
              end
            local ccID = 0
            while true do
              local retval, selected, muted, testPPQPOS, chanMsg, testChan, testMsg2, msg3 = reaper.MIDI_GetCC(take, ccID)
              if not retval then
                break
                end
              if chanMsg == msg1 and (msg2 == nil or testMsg2 == msg2) then
                local time = reaper.MIDI_GetProjTimeFromPPQPos(take, testPPQPOS)
                --local envVal = getNotePitchBendEnvelopeValue(time, chan)
                local condition = (time >= timeMin and time <= timeMax)
                local selected = condition
                reaper.MIDI_SetCC(take, ccID, selected)
                end
              ccID = ccID + 1
              end
          else
            local noteID = 0
            local testCount = 0
            while true do
              local retval, selected, muted, drawnNoteStartPPQPOS, drawnNoteEndPPQPOS, chan, pitch, vel = reaper.MIDI_GetNote(take, noteID)
              if not retval then
                break
                end
              
              local cents = getCentsFromNote(noteID)
              
              local drawnNoteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteStartPPQPOS)
              local drawnNoteEndTime = reaper.MIDI_GetProjTimeFromPPQPos(take, drawnNoteEndPPQPOS)
              
              local condition
              if drawnNoteEndTime < drawnNoteStartTime then
                condition = (drawnNoteStartTime <= timeMax and drawnNoteEndTime >= timeMin and cents >= centsMin and cents <= centsMax)
              else
                condition = (drawnNoteStartTime >= timeMin and drawnNoteStartTime <= timeMax and drawnNoteEndTime >= timeMin and drawnNoteEndTime <= timeMax and cents >= centsMin and cents <= centsMax)
                end
              local selected = condition
              setNote(noteID, selected)
              
              noteID = noteID + 1
              
              testCount = testCount + 1
              if testCount > 100 then
                debug_printStack()
                end
              end
            end
            
          regionCentsStart = nil
          regionTimeStart = nil
          end
        end
      end
    
    showTuningSettings = numberToBool(getTuningSettingsVisibility())
    showVelocityBars = showVelocity and convertVelocityViewToText(getVelocityView()) == "Bar"
    showVelocityCircles = showVelocity and convertVelocityViewToText(getVelocityView()) == "Circle"
    debug_funcTime("convert velocity view")
    
    processHotkeys()
    debug_funcTime("process hotkeys")
    
    reaper.ImGui_SetNextWindowSize(ctx, windowSizeX, windowSizeY)
    reaper.ImGui_SetNextWindowPos(ctx, window_xMin, window_yMin)
    
    local windowTitle = "MIDI Editor"
    local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, reaper.ImGui_WindowFlags_NoScrollWithMouse()+reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()+reaper.ImGui_WindowFlags_AlwaysVerticalScrollbar()+reaper.ImGui_WindowFlags_NoDecoration())
    if visible then
      local imgui_hwnd = reaper.JS_Window_Find(windowTitle, true)
      refreshZOrder(imgui_hwnd)
      debug_funcTime("refresh z order")
      
      addScrollbars(ctx)
      debug_funcTime("add scrollbars")
            
      addSizeButton()
      debug_funcTime("add size button")
      
      definePitchLists()
      debug_funcTime("define pitch lists")
      
      drawBackground(window_xMin, window_yMin, window_xMax, window_yMax, hexColor(210, 210, 210))
      
      drawPitchGridLines()
      debug_funcTime("draw pitch grid lines")
      
      local measureNumbersTable = drawTimeGridLines()
      debug_funcTime("draw time grid lines")
      
      local noteTable, notesToSet = handleNotes()
      debug_funcTime("handle notes")
      
      local ccPointsList = drawNotes(noteTable)
      debug_funcTime("draw notes")
      
      drawCCPoints(ccPointsList)
      debug_funcTime("draw cc points")
      
      drawPlayCursor()
      
      drawTimeSelection()
      
      drawMeasureNumbers(measureNumbersTable)
      debug_funcTime("draw measure numbers")
      
      drawNoteNames()
      debug_funcTime("draw note names")
      
      drawRegion()
      debug_funcTime("draw region")
      
      drawToolbar()
      debug_funcTime("draw toolbar")
      
      if not hoveringPoint then
        for x=1, getTableLen(notesToSet) do
          local data = notesToSet[x]
          setNote(data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9])
          end
        end
      debug_funcTime("set notes")
      
      reaper.ImGui_End(ctx)
      end
    
    local settingsWindowFlags = reaper.ImGui_WindowFlags_NoBackground()+reaper.ImGui_WindowFlags_TopMost()+reaper.ImGui_WindowFlags_NoFocusOnAppearing()+reaper.ImGui_WindowFlags_NoScrollWithMouse()+reaper.ImGui_WindowFlags_NoDecoration()
    
    if showTuningSettings then
      local xMin = globalSettings_xMin
      local yMin = globalSettings_yMin
      local xMax = globalSettings_xMax+5
      local yMax = tuningSettings_yMax+3
      reaper.ImGui_SetNextWindowSize(ctx, xMax-xMin, yMax-yMin)
      reaper.ImGui_SetNextWindowPos(ctx, xMin, yMin)
      
      local windowTitle = "Black Background"
      local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, settingsWindowFlags)
      if visible then
        drawBackground(xMin, yMin, xMax, yMax, BLACK)
        reaper.ImGui_End(ctx)
        end
      end
    
    reaper.ImGui_SetNextWindowSize(ctx, globalSettings_xMax-globalSettings_xMin, globalSettings_yMax-globalSettings_yMin)
    reaper.ImGui_SetNextWindowPos(ctx, globalSettings_xMin, globalSettings_yMin)
    
    local windowTitle = "Global Settings"
    local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, settingsWindowFlags)
    if visible then
      --toggle cents/Hz view
      local baseCentsView = getTextEvent("basecentsview", 0)
      local label
      if baseCentsView == 0 then
        label = "Hz"
      else
        label = "c"
        end
        
      if reaper.ImGui_Checkbox(ctx, "Cents?##TOGGLE" .. windowID, numberToBool(baseCentsView)) then
        setTextEvent("basecentsview", flip(baseCentsView))
        end
      
      --program pitch bend
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 30)
      local display
      if programPitchBendDown == 0 then
        display = ""
      else
        display = "-" .. programPitchBendDown
        end
      local retval, text = reaper.ImGui_InputText(ctx, "PB##PITCHBENDDOWN" .. windowID, display)
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
      local retval, text = reaper.ImGui_InputText(ctx, "##PITCHBENDUP" .. windowID, display)
      if retval then
        local semitones
        if tonumber(text) then
          semitones = math.floor(math.abs(tonumber(text)))
        else
          semitones = 0
          end
        setProgramPitchBendUp(semitones)
        end
      
      --cents range
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 70)
      local display = getCentsRangeMin()
      if baseCentsView == 0 then
        display = centsToHz(display)
        end
      display = display .. label
      local retval, text = reaper.ImGui_InputText(ctx, "Range##CENTSRANGEMIN" .. windowID, display)
      if retval then
        text = convertHzCents(text)
        if tonumber(text) then
          setCentsRangeMin(text)
          end
        end
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 70)
      local display = getCentsRangeMax()
      if baseCentsView == 0 then
        display = centsToHz(display)
        end
      display = display .. label
      local retval, text = reaper.ImGui_InputText(ctx, "##CENTSRANGEMAX" .. windowID, display)
      if retval then
        text = convertHzCents(text)
        if tonumber(text) then
          setCentsRangeMax(text)
          end
        end
      
      --velocity view
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 100)
      local display = convertVelocityViewToText(getVelocityView())
      if reaper.ImGui_BeginCombo(ctx, "Velocity View##" .. windowID, display) then
        for velocityView=0, 1 do
          local name = convertVelocityViewToText(velocityView)
          if reaper.ImGui_Selectable(ctx, name .. "##SELECTVELOCITYVIEW..." .. windowID, false, reaper.ImGui_SelectableFlags_None(), comboLen, 0) then
            setVelocityView(velocityView)
            end
          end
        reaper.ImGui_EndCombo(ctx)
        end
      
      --note CCs
      local function noteCCWidget(label, textEventLabel)
        local val = getTextEvent(textEventLabel, 0)
        local display
        if val == 0 then
          display = ""
        else
          display = val
          end
        reaper.ImGui_SetNextItemWidth(ctx, 30)
        local retval, text = reaper.ImGui_InputText(ctx, "##" .. label .. windowID, display, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
        if retval then
          if tonumber(text) then
            text = math.floor(tonumber(text))
            text = math.max(text, 0)
            text = math.min(text, 119)
          else
            text = 0
            end
          setTextEvent(textEventLabel, text)
          end
        reaper.ImGui_SameLine(ctx)
        local textColor
        if currentPointCC and textEventLabel == "cc_" .. currentPointCC then
          textColor = hexColor(255, 100, 255)
        else
          textColor = WHITE
          end
        reaper.ImGui_TextColored(ctx, textColor, label)
        end
      
      --change ccID
      local currentPointCCListID
      local len = getTableLen(global_pointCCTypes)
      for x=1, len do
        local display = global_pointCCTypes[x][1]
        local textEvent = global_pointCCTypes[x][2]
        if x > 1 then
          noteCCWidget(display, "cc_" .. textEvent)
          reaper.ImGui_SameLine(ctx)
          end
        if textEvent == currentPointCC then
          currentPointCCListID = x
          end
        end
      
      --change cc point view
      if reaper.ImGui_Button(ctx, global_pointCCTypes[currentPointCCListID][1] .. "##CURRENTPOINTCCDISPLAY" .. windowID, 90, 20) then
        if currentPointCCListID == len then
          currentPointCCListID = 1
        else
          currentPointCCListID = currentPointCCListID + 1
          end
        local textEvent = global_pointCCTypes[currentPointCCListID][2]
        if not textEvent then
          textEvent = "pitchbend"
          end
        setTextEvent("currentpointcc", textEvent)
        end
        
      --tuning name displays
      local bgTuningName = "Background: " .. getTuningData(false)
      if isTuningModified(false) then
        bgTuningName = "*" .. bgTuningName
        end
      local snapTuningName = "Notes: " .. getTuningData(true)
      if isTuningModified(true) then
        snapTuningName = "*" .. snapTuningName
        end
      local bgTuningColor = YELLOW
      local snapTuningColor = hexColor(255, 180, 46)
      
      local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, bgTuningName, 0, 0)
      local xPos = (tuningSettings_xMin+(tuningSettings_xMin+tuningSettingsWidth))/2-(textSizeX/2)
      local yPos = globalSettings_yMax-textSizeY-3
      reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, bgTuningColor, bgTuningName)
      
      local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, snapTuningName, 0, 0)
      local xPos = (tuningSettings_xMax+(tuningSettings_xMin+tuningSettingsWidth))/2-(textSizeX/2)
      local yPos = globalSettings_yMax-textSizeY-3
      reaper.ImGui_DrawList_AddText(drawList, xPos, yPos, snapTuningColor, snapTuningName)
      
      --show/hide tunings button
      local middleButtonText
      local middleButtonTextColor
      if showTuningSettings then
        middleButtonTextColor = hexColor(255, 0, 0)
        middleButtonText = "-"
      else
        middleButtonTextColor = hexColor(0, 255, 0)
        middleButtonText = "+"
        end
      local buttonSize = 14
      local xMin = tuningSettings_xMin+tuningSettingsWidth - buttonSize/2
      local yMin = globalSettings_yMax - buttonSize
      local xMax = tuningSettings_xMin+tuningSettingsWidth + buttonSize/2
      local yMax = globalSettings_yMax
      local middleButtonColor
      if mousePositionInRect(xMin, yMin, xMax, yMax) then
        middleButtonColor = hexColor(70, 70, 70)
      else
        middleButtonColor = hexColor(40, 40, 40)
        end
      reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, middleButtonColor, 8)
      if mouseLeftClicked and mousePositionInRect(xMin, yMin, xMax, yMax) then
        toggleTuningSettingsVisibility()
        end
        
      local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, middleButtonText, 0, 0)
      local xPos = (tuningSettings_xMin+tuningSettingsWidth)-(textSizeX/2)
      local yPos = globalSettings_yMax-textSizeY-3
      reaper.ImGui_DrawList_AddText(drawList, xPos+1, yPos+2, middleButtonTextColor, middleButtonText)
      
      reaper.ImGui_End(ctx)
      end
    
    if showTuningSettings then
      local tuningWindowFlags = reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()+reaper.ImGui_WindowFlags_AlwaysVerticalScrollbar()+reaper.ImGui_WindowFlags_TopMost()+reaper.ImGui_WindowFlags_NoFocusOnAppearing()+reaper.ImGui_WindowFlags_NoDecoration()
          
      reaper.ImGui_SetNextWindowSize(ctx, tuningSettingsWidth, tuningSettingsHeight+1)
      reaper.ImGui_SetNextWindowPos(ctx, tuningSettings_xMin, tuningSettings_yMin)
      
      local windowTitle = "Background Tuning Settings"
      local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, tuningWindowFlags)
      if visible then
        local xMin = tuningSettings_xMin
        local yMin = tuningSettings_yMin
        local xMax = tuningSettings_xMin+tuningSettingsWidth
        local yMax = tuningSettings_yMax
        drawBackground(xMin, yMin, xMax, yMax, BLACK)
        drawTuningSettings(false)
        reaper.ImGui_End(ctx)
        end
      
      reaper.ImGui_SetNextWindowSize(ctx, tuningSettingsWidth, tuningSettingsHeight+1)
      reaper.ImGui_SetNextWindowPos(ctx, tuningSettings_xMin+tuningSettingsWidth, tuningSettings_yMin)
      
      local windowTitle = "Snap Tuning Settings"
      local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, tuningWindowFlags)
      if visible then
        local xMin = tuningSettings_xMin+tuningSettingsWidth
        local yMin = tuningSettings_yMin
        local xMax = tuningSettings_xMax
        local yMax = tuningSettings_yMax
        drawBackground(xMin, yMin, xMax, yMax, BLACK)
        drawTuningSettings(true)
        reaper.ImGui_End(ctx)
        end
      end
    
    -----
    
    --[[
    reaper.ImGui_SetNextWindowSize(ctx, noteEditor_xMax-noteEditor_xMin, noteEditor_yMax-noteEditor_yMin)
    reaper.ImGui_SetNextWindowPos(ctx, noteEditor_xMin, noteEditor_yMin)
    
    local windowTitle = "Dummy for mouse release"
    local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, reaper.ImGui_WindowFlags_NoBackground()+reaper.ImGui_WindowFlags_NoScrollWithMouse()+reaper.ImGui_WindowFlags_NoDecoration())
    if visible then
      reaper.ImGui_End(ctx)
      end
    --]]
    
    -----
    
    if toSort then
      reaper.MIDI_Sort(take)
      toSort = false
      table.sort(pointsToDelete)
      for x=getTableLen(pointsToDelete), 1, -1 do
        reaper.MIDI_DeleteCC(take, pointsToDelete[x])
        end
      end
    if editedNotes then
      checkNotes()
      editedNotes = false
      if toSort then
        reaper.MIDI_Sort(take)
        toSort = false
        end
      end
    end
  
  if pitchIDToDelete then
    deletePitch(pitchIDToDeleteIsSnap, pitchIDToDelete)
    end
  if colorIDToDelete then
    deleteColor(colorIDToDeleteIsSnap, colorIDToDelete)
    end
  if tuningGUIDToSet then
    setTuningGUID(tuningGUIDToSetIsSnap, tuningGUIDToSet)
    end
    
  if openedMidiEditor == 0 then
    openedMidiEditor = 1
    end
  end

----------------

clearTempDirectory()

local ctx = reaper.ImGui_CreateContext("MIDI Editor")

function loop()
  debug_funcTime()
  
  midiEditor = reaper.MIDIEditor_GetActive()
  if midiEditor ~= nil and reaper.MIDIEditor_GetSetting_int(midiEditor, "list_cnt") == 0 then

    runGUI(ctx, 0)
    end
  
  debug_funcTime("end")
  reaper.defer(loop)
  end

loop()
