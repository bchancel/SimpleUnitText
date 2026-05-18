-- SimpleUnitText_Options.lua (WoW 12.0+ Settings panel with tabs)
-- Uses a simple custom tab bar (no PanelTemplates) to avoid template regressions.

SimpleUnitTextDB = SimpleUnitTextDB or {}
local ADDON_NAME = "SimpleUnitText"
local DEFAULT_PROFILE_NAME = "Default"

-------------------------------------------------
-- Utilities
-------------------------------------------------
local function Clamp(v, minV, maxV)
  if v < minV then return minV end
  if v > maxV then return maxV end
  return v
end

local function EnsureProfiles()
  if type(SimpleUnitTextDB.profiles) ~= "table" then
    SimpleUnitTextDB.profiles = {}
  end
  if not SimpleUnitTextDB.profiles[DEFAULT_PROFILE_NAME] then
    SimpleUnitTextDB.profiles[DEFAULT_PROFILE_NAME] = {}
  end
  if type(SimpleUnitTextDB.activeProfile) ~= "string"
    or not SimpleUnitTextDB.profiles[SimpleUnitTextDB.activeProfile] then
    SimpleUnitTextDB.activeProfile = DEFAULT_PROFILE_NAME
  end
end

local function DB()
  EnsureProfiles()
  return SimpleUnitTextDB.profiles[SimpleUnitTextDB.activeProfile]
end

local function ApplyNow()
  if SimpleUnitText_ApplySettings then
    SimpleUnitText_ApplySettings()
  elseif SimpleUnitText and SimpleUnitText.ApplySettings then
    pcall(SimpleUnitText.ApplySettings, SimpleUnitText)
  end
end

local function UpdateColorsNow()
  if SimpleUnitText and SimpleUnitText.UpdateColors then
    pcall(SimpleUnitText.UpdateColors, SimpleUnitText)
  end
end

-------------------------------------------------
-- Panel
-------------------------------------------------
local panel = CreateFrame("Frame", "SimpleUnitTextOptionsPanel", UIParent)
panel.name = "SimpleUnitText"

-- Top title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("SimpleUnitText")

local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetText("Text HUD for player/target HP% and mana% (secret-safe).")

-------------------------------------------------
-- Simple tab bar
-------------------------------------------------
local tabBar = CreateFrame("Frame", nil, panel)
tabBar:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
tabBar:SetSize(600, 28)

local tabs = {}
local pages = {}

local function CreateTabButton(text)
  local b = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
  b:SetText(text)
  b:SetHeight(22)
  b:SetWidth(math.max(80, b:GetTextWidth() + 20))
  return b
end

local function SetTabEnabled(btn, enabled)
  btn:SetEnabled(enabled)
  btn:SetAlpha(enabled and 1 or 0.4)
end

local activeTab = 1
local function SelectTab(idx)
  activeTab = idx
  for i, page in ipairs(pages) do
    page:SetShown(i == idx)
  end
  for i, btn in ipairs(tabs) do
    if i == idx then
      btn:LockHighlight()
    else
      btn:UnlockHighlight()
    end
  end
end

-------------------------------------------------
-- Common UI helpers
-------------------------------------------------
local function SectionHeader(parent, text, anchor, dy)
  local h = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy)
  h:SetText(text)
  return h
end

local function MakeCheckbox(parent, label, anchor, dy, onClick)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy)
  cb.Text:SetText(label)
  cb:SetScript("OnClick", onClick)
  return cb
end

local function MakeSliderWithEdit(parent, label, minV, maxV, step, anchor, dy, onChanged)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)
  s:SetWidth(320)
  s:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy)
  s.Text:SetText(label)
  s.Low:SetText(tostring(minV))
  s.High:SetText(tostring(maxV))

  local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  edit:SetSize(54, 20)
  edit:SetPoint("LEFT", s, "RIGHT", 12, 0)
  edit:SetAutoFocus(false)
  -- allow negative values; do not force numeric-only
  edit:SetNumeric(false)

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -6)
  val:SetText("")

  local function SetBoth(v)
    v = Clamp(v, minV, maxV)
    s:SetValue(v)
    edit:SetNumber(v)
    onChanged(v, val)
  end

  s:SetScript("OnValueChanged", function(_, v)
    v = math.floor((v or minV) + 0.5)
    edit:SetNumber(v)
    onChanged(v, val)
  end)

  edit:SetScript("OnEnterPressed", function(self)
    local v = tonumber(self:GetText())
    if v then
      SetBoth(v)
    end
    self:ClearFocus()
  end)

  return s, edit, val, SetBoth
end
-- Minimal dropdown using UIDropDownMenu (single-select, reliable)
local function MakeDropdown(parent, label, items, anchor, dy, onSelect)
  local lab = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  lab:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy)
  lab:SetText(label)

  local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -6)
  UIDropDownMenu_SetWidth(dd, 180)

  local function ValueText(val)
    for _, it in ipairs(items) do
      if it.value == val then return it.text end
    end
    return nil
  end

  local function Init()
    local selected = UIDropDownMenu_GetSelectedValue(dd)
    for _, it in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = it.text
      info.value = it.value
      info.isNotRadio = false
      info.notCheckable = false
      info.checked = (selected == it.value)
      info.func = function()
        UIDropDownMenu_SetSelectedValue(dd, it.value)
        local t = ValueText(it.value)
        if t then UIDropDownMenu_SetText(dd, t) end
        CloseDropDownMenus()
        onSelect(it.value)
      end
      UIDropDownMenu_AddButton(info)
    end
  end

  UIDropDownMenu_Initialize(dd, Init)
  UIDropDownMenu_SetWidth(dd, 180)

  -- selection/text is set during RefreshUI based on DB
  return dd, lab, ValueText
end

local FONT_CHOICES = {
  { text = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
  { text = "Arial Narrow",  value = "Fonts\\ARIALN.TTF" },
  { text = "Morpheus",      value = "Fonts\\MORPHEUS.TTF" },
}

local JUSTIFY_CHOICES = {
  { text = "Left",  value = "LEFT" },
  { text = "Right", value = "RIGHT" },
}

-------------------------------------------------
-- Pages container (kept below tabs)
-------------------------------------------------
local pageAnchor = CreateFrame("Frame", nil, panel)
pageAnchor:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
pageAnchor:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 12)

local function CreatePage()
  local f = CreateFrame("Frame", nil, pageAnchor)
  f:SetAllPoints(pageAnchor)

  local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 0)

  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(1, 1)
  sf:SetScrollChild(content)

  f.scroll = sf
  f.content = content
  return f
end

-------------------------------------------------
-- Tab 1: General Config
-------------------------------------------------
local generalPage = CreatePage()
pages[1] = generalPage
local g = generalPage.content

local gTop = g:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
gTop:SetPoint("TOPLEFT", 16, -10)
gTop:SetText("General Config")

-- Lock HUD
local cbLock = MakeCheckbox(g, "Lock HUD (disable dragging + click-through)", gTop, -10, function(self)
  DB().lockFrame = self:GetChecked() and true or false
  ApplyNow()
end)

-- Background alpha
local bgHeader = SectionHeader(g, "Background", cbLock, -18)
local alphaSlider, alphaEdit, alphaVal = nil, nil, nil
alphaSlider, alphaEdit, alphaVal =
  MakeSliderWithEdit(g, "Background Transparency (%)", 0, 100, 1, bgHeader, -16, function(v, valFS)
    DB().bgAlpha = v / 100
    valFS:SetText(string.format("Current: %d%%", v))
    ApplyNow()
  end)

-- Show/hide elements
local visHeader = SectionHeader(g, "Visibility", alphaSlider, -22)
local cbShowPHp = MakeCheckbox(g, "Show Player Health", visHeader, -10, function(self)
  DB().showPlayerHP = self:GetChecked() and true or false
  ApplyNow()
end)
local cbShowPPow = MakeCheckbox(g, "Show Player Power", cbShowPHp, -6, function(self)
  DB().showPlayerPower = self:GetChecked() and true or false
  ApplyNow()
end)
local cbShowTHp = MakeCheckbox(g, "Show Target Health", cbShowPPow, -6, function(self)
  DB().showTargetHP = self:GetChecked() and true or false
  ApplyNow()
end)
local cbShowTPow = MakeCheckbox(g, "Show Target Power", cbShowTHp, -6, function(self)
  DB().showTargetPower = self:GetChecked() and true or false
  ApplyNow()
end)

-- Profiles
local profHeader = SectionHeader(g, "Profiles", cbShowTPow, -18)

local profLabel = g:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
profLabel:SetPoint("TOPLEFT", profHeader, "BOTTOMLEFT", 0, -10)
profLabel:SetText("Active Profile")

local profDD = CreateFrame("Frame", nil, g, "UIDropDownMenuTemplate")
profDD:SetPoint("TOPLEFT", profLabel, "BOTTOMLEFT", -16, -6)
UIDropDownMenu_SetWidth(profDD, 180)

local profNameBox = CreateFrame("EditBox", nil, g, "InputBoxTemplate")
profNameBox:SetSize(160, 20)
profNameBox:SetPoint("TOPLEFT", profDD, "BOTTOMLEFT", 16, -10)
profNameBox:SetAutoFocus(false)
profNameBox:SetText("")

local createBtn = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
createBtn:SetSize(70, 22)
createBtn:SetPoint("LEFT", profNameBox, "RIGHT", 10, 0)
createBtn:SetText("Create")

local copyBtn = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
copyBtn:SetSize(70, 22)
copyBtn:SetPoint("TOPLEFT", profNameBox, "BOTTOMLEFT", 0, -8)
copyBtn:SetText("Copy")

local deleteBtn = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
deleteBtn:SetSize(70, 22)
deleteBtn:SetPoint("LEFT", copyBtn, "RIGHT", 10, 0)
deleteBtn:SetText("Delete")

local function NormalizeProfileName(name)
  name = (name or ""):match("^%s*(.-)%s*$") or ""
  name = name:gsub("[\r\n\t]", "")
  return name
end

local function RefreshProfileDropdown()
  EnsureProfiles()
  UIDropDownMenu_Initialize(profDD, function()
    local info = UIDropDownMenu_CreateInfo()
    for profName, _ in pairs(SimpleUnitTextDB.profiles) do
      info.text = profName
      info.value = profName
      info.func = function()
        SimpleUnitTextDB.activeProfile = profName
        UIDropDownMenu_SetSelectedValue(profDD, profName)
        ApplyNow()
        panel:GetScript("OnShow")(panel) -- refresh controls
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetSelectedValue(profDD, SimpleUnitTextDB.activeProfile)
  UIDropDownMenu_SetText(profDD, SimpleUnitTextDB.activeProfile)
end

createBtn:SetScript("OnClick", function()
  EnsureProfiles()
  local name = NormalizeProfileName(profNameBox:GetText())
  if name == "" then return end
  if not SimpleUnitTextDB.profiles[name] then
    SimpleUnitTextDB.profiles[name] = {}
  end
  SimpleUnitTextDB.activeProfile = name
  RefreshProfileDropdown()
  ApplyNow()
end)

copyBtn:SetScript("OnClick", function()
  EnsureProfiles()
  local name = NormalizeProfileName(profNameBox:GetText())
  if name == "" then return end
  if not SimpleUnitTextDB.profiles[name] then
    local src = DB()
    local dst = {}
    for k, v in pairs(src) do
      if type(v) == "table" then
        local t2 = {}
        for k2, v2 in pairs(v) do t2[k2] = v2 end
        dst[k] = t2
      else
        dst[k] = v
      end
    end
    SimpleUnitTextDB.profiles[name] = dst
  end
  SimpleUnitTextDB.activeProfile = name
  RefreshProfileDropdown()
  ApplyNow()
end)

deleteBtn:SetScript("OnClick", function()
  EnsureProfiles()
  local cur = SimpleUnitTextDB.activeProfile
  if cur == DEFAULT_PROFILE_NAME then return end
  SimpleUnitTextDB.profiles[cur] = nil
  SimpleUnitTextDB.activeProfile = DEFAULT_PROFILE_NAME
  RefreshProfileDropdown()
  ApplyNow()
end)

g:SetHeight(900)

-------------------------------------------------
-- Tab 2: Player Text
-------------------------------------------------
local playerPage = CreatePage()
pages[2] = playerPage
local p = playerPage.content

local pTop = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
pTop:SetPoint("TOPLEFT", 16, -10)
pTop:SetText("Player Text")

-- Class color toggle + alt color
local colorHeader = SectionHeader(p, "Health Color", pTop, -10)

local cbClass = MakeCheckbox(p, "Use class color for HP", colorHeader, -10, function(self)
  DB().useClassColor = self:GetChecked() and true or false
  UpdateColorsNow()
  panel:GetScript("OnShow")(panel)
end)

local swatch = CreateFrame("Button", nil, p)
swatch:SetSize(18, 18)
swatch:SetPoint("TOPLEFT", cbClass, "BOTTOMLEFT", 4, -8)
swatch.bg = swatch:CreateTexture(nil, "BACKGROUND")
swatch.bg:SetAllPoints(true)
swatch.bg:SetColorTexture(1, 1, 1, 1)

local pickBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
pickBtn:SetSize(90, 22)
pickBtn:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
pickBtn:SetText("Pick Color")

local function ApplySwatch()
  local c = DB().playerHpColor or { r = 1, g = 1, b = 1 }
  swatch.bg:SetColorTexture(c.r or 1, c.g or 1, c.b or 1, 1)
end

local function OpenColorPicker()
  local c = DB().playerHpColor or { r = 1, g = 1, b = 1 }
  local function setColor()
    local r, g2, b = ColorPickerFrame:GetColorRGB()
    DB().playerHpColor = { r = r, g = g2, b = b }
    ApplySwatch()
    UpdateColorsNow()
  end
  local function cancelColor(prev)
    if prev then
      DB().playerHpColor = { r = prev.r, g = prev.g, b = prev.b }
      ApplySwatch()
      UpdateColorsNow()
    end
  end

  ColorPickerFrame.func = setColor
  ColorPickerFrame.cancelFunc = cancelColor
  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.previousValues = { r = c.r or 1, g = c.g or 1, b = c.b or 1 }
  ColorPickerFrame:SetColorRGB(c.r or 1, c.g or 1, c.b or 1)
  ColorPickerFrame:Show()
end

pickBtn:SetScript("OnClick", OpenColorPicker)
swatch:SetScript("OnClick", OpenColorPicker)

-- Fonts / sizes
local fontHeader = SectionHeader(p, "Fonts", swatch, -18)

local pHpFontDD = nil
pHpFontDD = MakeDropdown(p, "Player HP Font", FONT_CHOICES, fontHeader, -12, function(v)
  DB().fontPathPHp = v
  ApplyNow()
end)

local pHpSizeSlider, pHpSizeEdit, pHpSizeVal
pHpSizeSlider, pHpSizeEdit, pHpSizeVal =
  MakeSliderWithEdit(p, "Player HP Font Size", 10, 100, 1, pHpFontDD, -46, function(v, valFS)
    DB().fontPHp = v
    valFS:SetText(string.format("Current: %d", v))
    ApplyNow()
  end)

local pPowFontDD = nil
pPowFontDD = MakeDropdown(p, "Player Power Font", FONT_CHOICES, pHpSizeVal, -18, function(v)
  DB().fontPathPPow = v
  ApplyNow()
end)

local pPowSizeSlider, pPowSizeEdit, pPowSizeVal
pPowSizeSlider, pPowSizeEdit, pPowSizeVal =
  MakeSliderWithEdit(p, "Player Power Font Size", 10, 100, 1, pPowFontDD, -46, function(v, valFS)
    DB().fontPPow = v
    valFS:SetText(string.format("Current: %d", v))
    ApplyNow()
  end)

local gapHeader = SectionHeader(p, "Layout", pPowSizeVal, -18)

local pLineGapSlider, pLineGapEdit, pLineGapVal
pLineGapSlider, pLineGapEdit, pLineGapVal =
  MakeSliderWithEdit(p, "Gap: Player HP -> Power (px)", 0, 40, 1, gapHeader, -16, function(v, valFS)
    DB().pLineGap = v
    valFS:SetText(string.format("Current: %d px", v))
    ApplyNow()
  end)

local justifyDD = nil
justifyDD = MakeDropdown(p, "Player Power Justify", JUSTIFY_CHOICES, pLineGapVal, -14, function(v)
  DB().playerPowerJustify = v
  ApplyNow()
end)

p:SetHeight(900)

-------------------------------------------------
-- Tab 3: Target Text
-------------------------------------------------
local targetPage = CreatePage()
pages[3] = targetPage
local t = targetPage.content

local tTop = t:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tTop:SetPoint("TOPLEFT", 16, -10)
tTop:SetText("Target Text")

local tLayoutHeader = SectionHeader(t, "Layout", tTop, -10)

local gapSlider, gapEdit, gapVal
gapSlider, gapEdit, gapVal =
  MakeSliderWithEdit(t, "Gap: Player <-> Target Frames (px)", 0, 120, 1, tLayoutHeader, -16, function(v, valFS)
    DB().gap = v
    valFS:SetText(string.format("Current: %d px", v))
    ApplyNow()
  end)


-- Target frame offset relative to player (fine positioning)
local offHeader = SectionHeader(t, "Target Offset", gapVal, -18)

local offXSlider, offXEdit, offXVal
offXSlider, offXEdit, offXVal =
  MakeSliderWithEdit(t, "Target Offset X (px)", -200, 200, 1, offHeader, -16, function(v, valFS)
    DB().targetOffsetX = v
    valFS:SetText(string.format("Current: %d px", v))
    ApplyNow()
  end)

local offYSlider, offYEdit, offYVal
offYSlider, offYEdit, offYVal =
  MakeSliderWithEdit(t, "Target Offset Y (px)", -200, 200, 1, offXVal, -18, function(v, valFS)
    DB().targetOffsetY = v
    valFS:SetText(string.format("Current: %d px", v))
    ApplyNow()
  end)

local tGapHeader = SectionHeader(t, "Target Line Spacing", offYVal, -18)

local tLineGapSlider, tLineGapEdit, tLineGapVal
tLineGapSlider, tLineGapEdit, tLineGapVal =
  MakeSliderWithEdit(t, "Gap: Target HP -> Power (px)", 0, 40, 1, tGapHeader, -16, function(v, valFS)
    DB().tLineGap = v
    valFS:SetText(string.format("Current: %d px", v))
    ApplyNow()
  end)

local tFontsHeader = SectionHeader(t, "Fonts", tLineGapVal, -18)

local tHpFontDD = nil
tHpFontDD = MakeDropdown(t, "Target HP Font", FONT_CHOICES, tFontsHeader, -12, function(v)
  DB().fontPathTHp = v
  ApplyNow()
end)

local tHpSizeSlider, tHpSizeEdit, tHpSizeVal
tHpSizeSlider, tHpSizeEdit, tHpSizeVal =
  MakeSliderWithEdit(t, "Target HP Font Size", 8, 80, 1, tHpFontDD, -46, function(v, valFS)
    DB().fontTHp = v
    valFS:SetText(string.format("Current: %d", v))
    ApplyNow()
  end)

local tPowFontDD = nil
tPowFontDD = MakeDropdown(t, "Target Power Font", FONT_CHOICES, tHpSizeVal, -18, function(v)
  DB().fontPathTPow = v
  ApplyNow()
end)

local tPowSizeSlider, tPowSizeEdit, tPowSizeVal
tPowSizeSlider, tPowSizeEdit, tPowSizeVal =
  MakeSliderWithEdit(t, "Target Power Font Size", 8, 80, 1, tPowFontDD, -46, function(v, valFS)
    DB().fontTPow = v
    valFS:SetText(string.format("Current: %d", v))
    ApplyNow()
  end)

local tJustifyDD = nil
tJustifyDD = MakeDropdown(t, "Target Power Justify", JUSTIFY_CHOICES, tPowSizeVal, -14, function(v)
  DB().targetPowerJustify = v
  ApplyNow()
end)

t:SetHeight(900)

-------------------------------------------------
-- Build tab buttons + wiring
-------------------------------------------------
tabs[1] = CreateTabButton("General")
tabs[1]:SetPoint("LEFT", tabBar, "LEFT", 0, 0)

tabs[2] = CreateTabButton("Player Text")
tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", 8, 0)

tabs[3] = CreateTabButton("Target Text")
tabs[3]:SetPoint("LEFT", tabs[2], "RIGHT", 8, 0)

for i, btn in ipairs(tabs) do
  btn:SetScript("OnClick", function()
    if btn:IsEnabled() then SelectTab(i) end
  end)
end

-- initial selection
SelectTab(1)

-------------------------------------------------
-- Refresh controls when opened
-------------------------------------------------
panel:SetScript("OnShow", function()
  local function DDText(items, val)
    for _, it in ipairs(items) do
      if it.value == val then return it.text end
    end
    return nil
  end
  EnsureProfiles()
  RefreshProfileDropdown()

  -- General
  cbLock:SetChecked(DB().lockFrame and true or false)

  local a = DB().bgAlpha or 0
  local ap = math.floor(a * 100 + 0.5)
  alphaSlider:SetValue(ap)
  alphaVal:SetText(string.format("Current: %d%%", ap))
  alphaEdit:SetNumber(ap)

  cbShowPHp:SetChecked(DB().showPlayerHP ~= false)
  cbShowPPow:SetChecked(DB().showPlayerPower ~= false)
  cbShowTHp:SetChecked(DB().showTargetHP ~= false)
  cbShowTPow:SetChecked(DB().showTargetPower ~= false)

  -- Target tab enable state (grey out if both target elements disabled)
  local targetEnabled = (DB().showTargetHP ~= false) or (DB().showTargetPower ~= false)
  SetTabEnabled(tabs[3], targetEnabled)
  if not targetEnabled and activeTab == 3 then
    SelectTab(1)
  end

  -- Player colors
  cbClass:SetChecked(DB().useClassColor ~= false)
  ApplySwatch()
  local useClass = DB().useClassColor ~= false
  swatch:SetShown(not useClass)
  pickBtn:SetShown(not useClass)

  -- Dropdowns
  do local v = DB().fontPathPHp or FONT_CHOICES[1].value; UIDropDownMenu_SetSelectedValue(pHpFontDD, v); local t = DDText(FONT_CHOICES, v); if t then UIDropDownMenu_SetText(pHpFontDD, t) end end
  do local v = DB().fontPathPPow or FONT_CHOICES[1].value; UIDropDownMenu_SetSelectedValue(pPowFontDD, v); local t = DDText(FONT_CHOICES, v); if t then UIDropDownMenu_SetText(pPowFontDD, t) end end
  do local v = DB().fontPathTHp or FONT_CHOICES[1].value; UIDropDownMenu_SetSelectedValue(tHpFontDD, v); local t = DDText(FONT_CHOICES, v); if t then UIDropDownMenu_SetText(tHpFontDD, t) end end
  do local v = DB().fontPathTPow or FONT_CHOICES[1].value; UIDropDownMenu_SetSelectedValue(tPowFontDD, v); local t = DDText(FONT_CHOICES, v); if t then UIDropDownMenu_SetText(tPowFontDD, t) end end

  do local v = DB().playerPowerJustify or "RIGHT"; UIDropDownMenu_SetSelectedValue(justifyDD, v); local t = DDText(JUSTIFY_CHOICES, v); if t then UIDropDownMenu_SetText(justifyDD, t) end end
  do local v = DB().targetPowerJustify or "LEFT"; UIDropDownMenu_SetSelectedValue(tJustifyDD, v); local t = DDText(JUSTIFY_CHOICES, v); if t then UIDropDownMenu_SetText(tJustifyDD, t) end end

  -- Sliders + editboxes
  local ph = DB().fontPHp or 44
  pHpSizeSlider:SetValue(ph); pHpSizeEdit:SetNumber(ph); pHpSizeVal:SetText(string.format("Current: %d", ph))

  local pp = DB().fontPPow or 34
  pPowSizeSlider:SetValue(pp); pPowSizeEdit:SetNumber(pp); pPowSizeVal:SetText(string.format("Current: %d", pp))

  local plg = DB().pLineGap or 10
  pLineGapSlider:SetValue(plg); pLineGapEdit:SetNumber(plg); pLineGapVal:SetText(string.format("Current: %d px", plg))

  local gpx = DB().gap or 8
  gapSlider:SetValue(gpx); gapEdit:SetNumber(gpx); gapVal:SetText(string.format("Current: %d px", gpx))

    local ox = DB().targetOffsetX or 0
  offXSlider:SetValue(ox); offXEdit:SetNumber(ox); offXVal:SetText(string.format("Current: %d px", ox))

  local oy = DB().targetOffsetY or 0
  offYSlider:SetValue(oy); offYEdit:SetNumber(oy); offYVal:SetText(string.format("Current: %d px", oy))

local tlg = DB().tLineGap or 0
  tLineGapSlider:SetValue(tlg); tLineGapEdit:SetNumber(tlg); tLineGapVal:SetText(string.format("Current: %d px", tlg))

  local th = DB().fontTHp or 22
  tHpSizeSlider:SetValue(th); tHpSizeEdit:SetNumber(th); tHpSizeVal:SetText(string.format("Current: %d", th))

  local tp = DB().fontTPow or 16
  tPowSizeSlider:SetValue(tp); tPowSizeEdit:SetNumber(tp); tPowSizeVal:SetText(string.format("Current: %d", tp))
end)

-------------------------------------------------
-- Register (modern Settings API)
-------------------------------------------------
do
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    _G.SimpleUnitText_SettingsCategory = category
    if type(category.GetID) == "function" then _G.SimpleUnitText_SettingsCategoryID = category:GetID() end
  else
    -- Very old clients: nothing to register.
  end
end

