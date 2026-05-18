local _, ns = ...

local ConfigWindow = {}
ns.ui.ConfigWindow = ConfigWindow

local fontEntries = {
  { key = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", label = "Standard" },
  { key = "Fonts\\FRIZQT__.TTF", label = "Friz Quadrata" },
  { key = "Fonts\\ARIALN.TTF", label = "Arial Narrow" },
  { key = "Fonts\\MORPHEUS.TTF", label = "Morpheus" },
  { key = "Fonts\\skurri.ttf", label = "Skurri" },
}

local flagEntries = {
  { key = "", label = "None" },
  { key = "OUTLINE", label = "Outline" },
  { key = "THICKOUTLINE", label = "Thick Outline" },
  { key = "MONOCHROME", label = "Monochrome" },
  { key = "OUTLINE,MONOCHROME", label = "Outline + Mono" },
  { key = "THICKOUTLINE,MONOCHROME", label = "Thick + Mono" },
}

local justifyEntries = {
  { key = "LEFT", label = "Left" },
  { key = "RIGHT", label = "Right" },
}

local scopeEntries = {
  { key = ns.PROFILE_SCOPE_GLOBAL, label = "Global" },
  { key = ns.PROFILE_SCOPE_CHARACTER, label = "Character" },
}

local playerHpColorEntries = {
  { key = "CLASS", label = "Class Color" },
  { key = "FIXED", label = "Fixed Color" },
  { key = "CURVE", label = "Color Curve" },
}

local targetHpColorEntries = {
  { key = "REACTION", label = "Reaction / Class" },
  { key = "FIXED", label = "Fixed Color" },
  { key = "CURVE", label = "Color Curve" },
}

local powerColorEntries = {
  { key = "POWER", label = "Power Color" },
  { key = "FIXED", label = "Fixed Color" },
  { key = "CURVE", label = "Color Curve" },
}

local secondaryColorEntries = {
  { key = "POWER", label = "Power Color" },
  { key = "FIXED", label = "Fixed Color" },
  { key = "CURVE", label = "Color Curve" },
}

local secondaryColorConfigEntries = {
  { key = "DEFAULT", label = "Default (All Secondary Types)" },
  { key = "COMBO_POINTS", label = "Combo Points" },
  { key = "HOLY_POWER", label = "Holy Power" },
  { key = "CHI", label = "Chi" },
  { key = "SOUL_SHARDS", label = "Soul Shards" },
}

local playerPowerConfigEntries = {
  { key = "DEFAULT", label = "Default (All Power Types)" },
  { key = "MANA", label = "Mana" },
  { key = "RAGE", label = "Rage" },
  { key = "ENERGY", label = "Energy" },
  { key = "FOCUS", label = "Focus" },
  { key = "RUNIC_POWER", label = "Runic Power" },
  { key = "LUNAR_POWER", label = "Astral Power" },
  { key = "MAELSTROM", label = "Maelstrom" },
  { key = "INSANITY", label = "Insanity" },
  { key = "FURY", label = "Fury" },
  { key = "PAIN", label = "Pain" },
}

local pageDefinitions = {
  { key = "general", label = "General" },
  { key = "player", label = "Player" },
  { key = "target", label = "Target" },
  { key = "secondary", label = "Secondary" },
  { key = "profiles", label = "Profiles" },
  { key = "import_export", label = "Import / Export" },
}

local PAGE_SECTION_WIDTH = 724
local PAGE_CONTENT_WIDTH = 744
local CURVE_EDITOR_WIDTH = PAGE_SECTION_WIDTH - 24
local CURVE_PREVIEW_WIDTH = CURVE_EDITOR_WIDTH - 28
local IMPORT_BOX_WIDTH = PAGE_SECTION_WIDTH - 14
local IMPORT_EDIT_WIDTH = IMPORT_BOX_WIDTH - 50

local function GetEntryLabel(entries, key)
  for _, entry in ipairs(entries or {}) do
    if entry.key == key then
      return entry.label
    end
  end
  return tostring(key or "")
end

local function GetProfile()
  return ns.DB:GetActiveProfile()
end

local function GetCurveTypeHelpText(curveType, pointCount)
  local summary = "Linear: straight blend. Step: hard jumps. Cosine: softened blend. Cubic: smoothest blend."
  local details = {
    Linear = "Current type moves evenly between each stop.",
    Step = "Current type holds one color until the next stop, then snaps.",
    Cosine = "Current type eases between stops for a gentler handoff.",
    Cubic = "Current type uses cubic smoothing for the softest ramp.",
  }

  local detail = details[curveType] or details.Linear
  if curveType == "Cubic" and (tonumber(pointCount) or 0) < 4 then
    detail = detail .. " With fewer than 4 stops, Blizzard falls back to Cosine."
  end

  return summary .. "\n" .. detail
end

local function ColorToHex(color)
  local r = math.floor(((color and color.r) or 1) * 255 + 0.5)
  local g = math.floor(((color and color.g) or 1) * 255 + 0.5)
  local b = math.floor(((color and color.b) or 1) * 255 + 0.5)
  return string.format("#%02X%02X%02X", r, g, b)
end

local function ApplyAndRefresh()
  if ns.RefreshAddon then
    ns.RefreshAddon()
  end
  if ConfigWindow.Refresh then
    ConfigWindow:Refresh()
  end
end

local function CreateLabel(parent, text, template)
  local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
  label:SetJustifyH("LEFT")
  label:SetText(text or "")
  return label
end

local function CreateButton(parent, text, width, height, onClick, primary)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(width or 120, height or 22)
  button:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  if primary then
    button:SetBackdropColor(0.08, 0.42, 0.82, 0.96)
    button:SetBackdropBorderColor(0.18, 0.62, 1.0, 1)
  else
    button:SetBackdropColor(0.10, 0.13, 0.18, 0.95)
    button:SetBackdropBorderColor(0.24, 0.30, 0.40, 1)
  end

  button.Text = button:CreateFontString(nil, "OVERLAY")
  button.Text:SetPoint("CENTER")
  button.Text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", primary and 14 or 12, "OUTLINE")
  button.Text:SetTextColor(primary and 1 or 1, primary and 1 or 0.88, primary and 1 or 0.15)
  button.Text:SetText(text or "")

  button:SetScript("OnEnter", function(self)
    if primary then
      self:SetBackdropColor(0.10, 0.48, 0.92, 1)
    else
      self:SetBackdropColor(0.12, 0.16, 0.23, 0.98)
    end
  end)

  button:SetScript("OnLeave", function(self)
    if primary then
      self:SetBackdropColor(0.08, 0.42, 0.82, 0.96)
    else
      self:SetBackdropColor(0.10, 0.13, 0.18, 0.95)
    end
  end)

  if onClick then
    button:SetScript("OnClick", onClick)
  end
  return button
end

local function CreateInput(parent, width, height)
  local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  input:SetAutoFocus(false)
  input:SetSize(width or 80, height or 22)
  input:SetTextInsets(6, 6, 0, 0)
  input:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  return input
end

local function CreateCheckbox(parent, text, x, y, getter, setter)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetPoint("TOPLEFT", x, y)
  local textRegion = check.Text
  if not textRegion then
    local name = check:GetName()
    if name then
      textRegion = _G[name .. "Text"]
    end
  end
  if not textRegion then
    textRegion = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textRegion:SetPoint("LEFT", check, "RIGHT", 2, 1)
    check.Text = textRegion
  end
  textRegion:SetText(text or "")
  check.getter = getter
  check.setter = setter
  check:SetScript("OnClick", function(self)
    if self.setter then
      self.setter(self:GetChecked() == true)
      ApplyAndRefresh()
    end
  end)
  check.refresh = function(self)
    self:SetChecked(self.getter and self.getter() == true or false)
  end
  return check
end

local function CreateDropdown(parent, x, y, width, entries, getter, setter)
  local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dropdown:SetPoint("TOPLEFT", x, y)
  UIDropDownMenu_SetWidth(dropdown, width or 180)
  dropdown.entries = entries
  dropdown.getter = getter
  dropdown.setter = setter

  UIDropDownMenu_Initialize(dropdown, function(self, level)
    for _, entry in ipairs(dropdown.entries or {}) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = entry.label
      info.value = entry.key
      info.func = function()
        if dropdown.setter then
          dropdown.setter(entry.key)
        end
        ApplyAndRefresh()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  dropdown.refresh = function(self)
    local value = self.getter and self.getter() or nil
    UIDropDownMenu_SetSelectedValue(self, value)
    UIDropDownMenu_SetText(self, GetEntryLabel(self.entries, value))
  end
  return dropdown
end

local function CreateLabeledInput(parent, labelText, x, y, width, getter, setter)
  local label = CreateLabel(parent, labelText, "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", x, y)

  local input = CreateInput(parent, width or 72, 22)
  input:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
  input.getter = getter
  input.setter = setter
  input:SetScript("OnEnterPressed", function(self)
    if self.setter then
      self.setter(self:GetText())
      ApplyAndRefresh()
    end
    self:ClearFocus()
  end)
  input.refresh = function(self)
    local value = self.getter and self.getter() or ""
    self:SetText(tostring(value or ""))
  end

  return {
    label = label,
    input = input,
    SetShown = function(self, shown)
      label:SetShown(shown)
      input:SetShown(shown)
    end,
    refresh = function(self)
      input:refresh()
    end,
  }
end

local function CreateLabeledDropdown(parent, labelText, x, y, width, entries, getter, setter)
  local label = CreateLabel(parent, labelText, "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", x, y)

  local dropdown = CreateDropdown(parent, x - 16, y - 18, width or 180, entries, getter, setter)
  return {
    label = label,
    dropdown = dropdown,
    SetShown = function(self, shown)
      label:SetShown(shown)
      dropdown:SetShown(shown)
    end,
    refresh = function(self)
      dropdown:refresh()
    end,
  }
end

local function OpenColorPicker(initialColor, onChanged)
  local color = ns.CopyColor(initialColor)
  local frame = ColorPickerFrame
  local picker = frame and frame.Content and frame.Content.ColorPicker or nil

  if not frame then
    return
  end

  local function GetCurrentPickerRGB()
    if type(frame.GetColorRGB) == "function" then
      return frame:GetColorRGB()
    end

    if picker and type(picker.GetColorRGB) == "function" then
      return picker:GetColorRGB()
    end

    return color.r, color.g, color.b
  end

  local function SetCurrentPickerRGB(r, g, b)
    if picker and type(picker.SetColorRGB) == "function" then
      picker:SetColorRGB(r, g, b)
      return true
    end

    if type(frame.SetColorRGB) == "function" then
      frame:SetColorRGB(r, g, b)
      return true
    end

    return false
  end

  if type(frame.SetupColorPickerAndShow) == "function" then
    local info = {
      r = color.r,
      g = color.g,
      b = color.b,
      hasOpacity = false,
      swatchFunc = function()
        local r, g, b = GetCurrentPickerRGB()
        onChanged(ns.MakeColor(r, g, b, color.a))
      end,
      cancelFunc = function(previous)
        if previous then
          onChanged(ns.MakeColor(previous.r, previous.g, previous.b, previous.a or color.a))
        end
      end,
    }
    frame:SetupColorPickerAndShow(info)
    return
  end

  frame.hasOpacity = false
  frame.previousValues = { r = color.r, g = color.g, b = color.b, a = color.a }
  SetCurrentPickerRGB(color.r, color.g, color.b)
  frame.func = function()
    local r, g, b = GetCurrentPickerRGB()
    onChanged(ns.MakeColor(r, g, b, color.a))
  end
  frame.cancelFunc = function(previous)
    if previous then
      onChanged(ns.MakeColor(previous.r, previous.g, previous.b, previous.a or color.a))
    end
  end
  frame:Show()
end

local function CreateColorControl(parent, labelText, x, y, getter, setter)
  local label = CreateLabel(parent, labelText, "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", x, y)

  local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
  swatch:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
  swatch:SetSize(24, 24)
  swatch:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  swatch:SetBackdropBorderColor(0.32, 0.42, 0.56, 1)
  swatch.texture = swatch:CreateTexture(nil, "BACKGROUND")
  swatch.texture:SetAllPoints(true)

  local button = CreateButton(parent, "Pick", 64, 22, function()
    OpenColorPicker(getter and getter() or ns.MakeColor(1, 1, 1, 1), function(newColor)
      if setter then
        setter(newColor)
      end
      ApplyAndRefresh()
    end)
  end)
  button:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
  swatch:SetScript("OnClick", function()
    button:Click()
  end)

  return {
    label = label,
    swatch = swatch,
    button = button,
    SetShown = function(self, shown)
      label:SetShown(shown)
      swatch:SetShown(shown)
      button:SetShown(shown)
    end,
    refresh = function(self)
      local color = getter and getter() or ns.MakeColor(1, 1, 1, 1)
      swatch.texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
    end,
  }
end

local function CreateSectionBox(parent, title, x, y, width, height)
  local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  box:SetPoint("TOPLEFT", x, y)
  box:SetSize(width, height)
  box:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  box:SetBackdropColor(0.08, 0.10, 0.15, 0.96)
  box:SetBackdropBorderColor(0.22, 0.28, 0.38, 1)

  box.header = CreateFrame("Frame", nil, box, "BackdropTemplate")
  box.header:SetPoint("TOPLEFT", 1, -1)
  box.header:SetPoint("TOPRIGHT", -1, -1)
  box.header:SetHeight(28)
  box.header:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  box.header:SetBackdropColor(0.10, 0.14, 0.22, 1)
  box.header:SetBackdropBorderColor(0.18, 0.24, 0.34, 1)

  box.title = CreateLabel(box.header, title, "GameFontNormal")
  box.title:SetPoint("LEFT", 10, 0)
  return box
end

local function RefreshControls(controls)
  for _, control in ipairs(controls or {}) do
    if control and control.refresh then
      control:refresh()
    end
  end
end

local function SetTopLeft(frame, x, y)
  if not frame then
    return
  end
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", x, y)
end

local function CreateTextStyleEditor(parent, title, x, y, getStyle)
  local box = CreateSectionBox(parent, title, x, y, PAGE_SECTION_WIDTH, 150)
  box.controls = {}

  box.font = CreateLabeledDropdown(
    box,
    "Font",
    12,
    -36,
    190,
    fontEntries,
    function()
      return getStyle().fontFile
    end,
    function(value)
      getStyle().fontFile = value
    end
  )
  box.controls[#box.controls + 1] = box.font

  box.size = CreateLabeledInput(
    box,
    "Size",
    230,
    -36,
    64,
    function()
      return getStyle().size
    end,
    function(text)
      getStyle().size = math.max(6, tonumber(text) or getStyle().size or 12)
    end
  )
  box.controls[#box.controls + 1] = box.size

  box.flags = CreateLabeledDropdown(
    box,
    "Flags",
    330,
    -36,
    160,
    flagEntries,
    function()
      return getStyle().flags
    end,
    function(value)
      getStyle().flags = value
    end
  )
  box.controls[#box.controls + 1] = box.flags

  box.shadowToggle = CreateCheckbox(
    box,
    "Enable Shadow",
    12,
    -96,
    function()
      return getStyle().shadow.enabled
    end,
    function(checked)
      getStyle().shadow.enabled = checked
    end
  )
  box.controls[#box.controls + 1] = box.shadowToggle

  box.shadowColor = CreateColorControl(
    box,
    "Shadow Color",
    170,
    -96,
    function()
      return getStyle().shadow.color
    end,
    function(color)
      getStyle().shadow.color = ns.CopyColor(color)
    end
  )
  box.controls[#box.controls + 1] = box.shadowColor

  box.shadowX = CreateLabeledInput(
    box,
    "Shadow X",
    380,
    -96,
    64,
    function()
      return getStyle().shadow.offsetX
    end,
    function(text)
      getStyle().shadow.offsetX = math.floor(tonumber(text) or getStyle().shadow.offsetX or 0)
    end
  )
  box.controls[#box.controls + 1] = box.shadowX

  box.shadowY = CreateLabeledInput(
    box,
    "Shadow Y",
    480,
    -96,
    64,
    function()
      return getStyle().shadow.offsetY
    end,
    function(text)
      getStyle().shadow.offsetY = math.floor(tonumber(text) or getStyle().shadow.offsetY or 0)
    end
  )
  box.controls[#box.controls + 1] = box.shadowY

  box.refresh = function(self)
    RefreshControls(self.controls)
  end

  return box
end

local function CreateCurveEditor(parent, title, x, y, getDefinition)
  local box = CreateSectionBox(parent, title, x, y, CURVE_EDITOR_WIDTH, 244)
  box.controls = {}
  box.previewSegments = {}
  box.rows = {}

  box.curveType = CreateLabeledDropdown(
    box,
    "Curve Type",
    12,
    -36,
    160,
    ns.Curves.typeEntries,
    function()
      return getDefinition().curveType
    end,
    function(value)
      getDefinition().curveType = value
    end
  )
  box.controls[#box.controls + 1] = box.curveType

  box.helpText = CreateLabel(box, "", "GameFontHighlightSmall")
  box.helpText:SetPoint("TOPLEFT", 208, -40)
  box.helpText:SetWidth(372)
  box.helpText:SetJustifyH("LEFT")
  box.helpText:SetJustifyV("TOP")

  box.addButton = CreateButton(box, "Add Stop", 90, 22, function()
    local definition = getDefinition()
    definition.points = definition.points or {}
    if #definition.points >= 5 then
      return
    end

    local newPoint = {
      x = 1.0,
      color = ns.MakeColor(1, 1, 1, 1),
    }

    if #definition.points > 0 then
      local lastPoint = definition.points[#definition.points]
      newPoint.x = ns.Clamp((lastPoint.x or 0) + 0.1, 0, 1)
      newPoint.color = ns.CopyColor(lastPoint.color)
    end

    definition.points[#definition.points + 1] = newPoint
    ApplyAndRefresh()
  end)
  box.addButton:SetPoint("TOPRIGHT", -12, -40)

  box.preview = CreateFrame("Frame", nil, box, "BackdropTemplate")
  box.preview:SetPoint("TOPLEFT", 12, -80)
  box.preview:SetSize(CURVE_PREVIEW_WIDTH, 18)
  box.preview:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  box.preview:SetBackdropColor(0.04, 0.04, 0.06, 1)
  box.preview:SetBackdropBorderColor(0.28, 0.34, 0.44, 1)

  for index = 1, 24 do
    local tex = box.preview:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", (index - 1) * 28, 0)
    tex:SetSize(28, 18)
    box.previewSegments[index] = tex
  end

  local startY = -110
  for index = 1, 5 do
    local row = CreateFrame("Frame", nil, box)
    row:SetPoint("TOPLEFT", 12, startY - ((index - 1) * 24))
    row:SetSize(CURVE_PREVIEW_WIDTH, 22)

    row.label = CreateLabel(row, "Stop " .. index, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", 0, 0)

    row.percent = CreateInput(row, 54, 22)
    row.percent:SetPoint("LEFT", row.label, "RIGHT", 12, 0)
    row.percent:SetScript("OnEnterPressed", function(self)
      local definition = getDefinition()
      local point = definition.points[index]
      if point then
        point.x = ns.Clamp((tonumber(self:GetText()) or (point.x * 100)) / 100, 0, 1)
        table.sort(definition.points, function(left, right)
          return (left.x or 0) < (right.x or 0)
        end)
        ApplyAndRefresh()
      end
      self:ClearFocus()
    end)

    row.percentHint = CreateLabel(row, "%", "GameFontHighlightSmall")
    row.percentHint:SetPoint("LEFT", row.percent, "RIGHT", 4, 0)

    row.color = CreateButton(row, "Color", 70, 22, function()
      local definition = getDefinition()
      local point = definition.points[index]
      if not point then
        return
      end
      OpenColorPicker(point.color, function(color)
        local currentDefinition = getDefinition()
        local currentPoint = currentDefinition.points[index]
        if currentPoint then
          currentPoint.color = ns.CopyColor(color)
        end
        ApplyAndRefresh()
      end)
    end)
    row.color:SetPoint("LEFT", row.percentHint, "RIGHT", 18, 0)

    row.hex = CreateLabel(row, "", "GameFontHighlightSmall")
    row.hex:SetPoint("LEFT", row.color, "RIGHT", 14, 0)
    row.hex:SetWidth(74)
    row.hex:SetJustifyH("LEFT")

    row.remove = CreateButton(row, "X", 22, 22, function()
      local definition = getDefinition()
      if #definition.points <= 2 then
        return
      end
      table.remove(definition.points, index)
      ApplyAndRefresh()
    end)
    row.remove:SetPoint("LEFT", row.hex, "RIGHT", 8, 0)
    row.remove.Text:SetTextColor(1.0, 0.32, 0.32)
    row.remove:SetBackdropColor(0.22, 0.05, 0.05, 0.96)
    row.remove:SetBackdropBorderColor(0.58, 0.16, 0.16, 1)
    row.remove:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.30, 0.08, 0.08, 1)
    end)
    row.remove:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.22, 0.05, 0.05, 0.96)
    end)

    box.rows[index] = row
  end

  box.refresh = function(self)
    self.curveType:refresh()

    local definition = ns.Curves.NormalizeDefinition(getDefinition())
    getDefinition().curveType = definition.curveType
    getDefinition().points = definition.points
    self.helpText:SetText(GetCurveTypeHelpText(definition.curveType, #definition.points))

    for index, texture in ipairs(self.previewSegments) do
      local ratio = (index - 1) / math.max(1, (#self.previewSegments - 1))
      local color = ns.Curves.EvaluatePreview(definition, ratio)
      texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
    end

    for index, row in ipairs(self.rows) do
      local point = definition.points[index]
      if point then
        row:Show()
        row.percent:SetText(tostring(math.floor((point.x or 0) * 100 + 0.5)))
        row.color.Text:SetText("Color")
        row.color:SetBackdropColor(point.color.r or 1, point.color.g or 1, point.color.b or 1, 0.35)
        row.hex:SetText(ColorToHex(point.color))
        row.hex:SetTextColor(point.color.r or 1, point.color.g or 1, point.color.b or 1)
        row.remove:SetShown(#definition.points > 2)
      else
        row:Hide()
      end
    end

    self.addButton:SetEnabled(#definition.points < 5)
    self.addButton:SetAlpha(#definition.points < 5 and 1 or 0.45)
  end

  return box
end

local function CreateColorSection(parent, title, x, y, modeEntries, getSection, modeKey, colorKey, curveKey)
  local box = CreateSectionBox(parent, title, x, y, PAGE_SECTION_WIDTH, 344)
  box.controls = {}
  box.compactHeight = 104
  box.curveHeight = 344

  box.mode = CreateLabeledDropdown(
    box,
    "Color Mode",
    12,
    -36,
    180,
    modeEntries,
    function()
      return getSection()[modeKey]
    end,
    function(value)
      getSection()[modeKey] = value
    end
  )
  box.controls[#box.controls + 1] = box.mode

  box.fixedColor = CreateColorControl(
    box,
    "Fixed Color",
    240,
    -36,
    function()
      return getSection()[colorKey]
    end,
    function(color)
      getSection()[colorKey] = ns.CopyColor(color)
    end
  )
  box.controls[#box.controls + 1] = box.fixedColor

  box.curveEditor = CreateCurveEditor(
    box,
    "Curve Stops",
    12,
    -92,
    function()
      return getSection()[curveKey]
    end
  )

  box.refresh = function(self)
    RefreshControls(self.controls)
    local mode = getSection()[modeKey]
    local showFixed = mode == "FIXED"
    local showCurve = mode == "CURVE"

    if self.fixedColor.SetShown then
      self.fixedColor:SetShown(showFixed)
    end

    if showCurve then
      self.curveEditor:Show()
      self.curveEditor:refresh()
      self:SetHeight(self.curveHeight)
    else
      self.curveEditor:Hide()
      self:SetHeight(self.compactHeight)
    end
  end

  return box
end

local function CreatePageContainer(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints()

  local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", -40, 0)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(PAGE_CONTENT_WIDTH, 1000)
  scroll:SetScrollChild(content)

  frame.scroll = scroll
  frame.content = content
  return frame
end

function ConfigWindow:Create()
  if self.frame then
    return self.frame
  end

  local frame = CreateFrame("Frame", "SimpleUnitTextConfigWindow", UIParent, "BackdropTemplate")
  local windowState = ns.DB:GetConfigWindowState()
  frame:SetSize(windowState.width or 980, windowState.height or 680)
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(0.06, 0.08, 0.12, 0.98)
  frame:SetBackdropBorderColor(0.32, 0.08, 0.10, 0.95)
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(false)
  frame:SetScript("OnDragStart", function(selfFrame)
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    selfFrame:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(selfFrame)
    selfFrame:StopMovingOrSizing()
    ns.Anchors.SaveToScreenCenter(selfFrame, windowState)
  end)
  ns.Anchors.Apply(frame, windowState)
  frame:Hide()

  frame.header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.header:SetPoint("TOPLEFT", 1, -1)
  frame.header:SetPoint("TOPRIGHT", -1, -1)
  frame.header:SetHeight(40)
  frame.header:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame.header:SetBackdropColor(0.10, 0.14, 0.22, 1)
  frame.header:SetBackdropBorderColor(0.18, 0.25, 0.36, 1)

  frame.headerText = frame.header:CreateFontString(nil, "OVERLAY")
  frame.headerText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
  frame.headerText:SetPoint("LEFT", 14, 0)
  frame.headerText:SetText("SimpleUnitText")
  frame.headerText:SetTextColor(0.92, 0.95, 1)

  frame.subText = frame.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.subText:SetPoint("LEFT", frame.headerText, "RIGHT", 14, -1)
  frame.subText:SetText("Midnight-safe text HUD configuration")

  frame.closeButton = CreateFrame("Button", nil, frame.header, "UIPanelCloseButton")
  frame.closeButton:SetPoint("RIGHT", -2, 0)
  frame.closeButton:SetScript("OnClick", function()
    frame:Hide()
  end)

  frame.sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.sidebar:SetPoint("TOPLEFT", 12, -52)
  frame.sidebar:SetPoint("BOTTOMLEFT", 12, 12)
  frame.sidebar:SetWidth(164)
  frame.sidebar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame.sidebar:SetBackdropColor(0.09, 0.11, 0.16, 0.96)
  frame.sidebar:SetBackdropBorderColor(0.20, 0.26, 0.34, 1)

  frame.pageTitle = CreateLabel(frame, "General", "GameFontNormalLarge")
  frame.pageTitle:SetPoint("TOPLEFT", frame.sidebar, "TOPRIGHT", 18, -10)

  frame.pageHint = CreateLabel(frame, "Keep the current HUD feel, add modern controls, and stay secret-safe.", "GameFontHighlightSmall")
  frame.pageHint:SetPoint("TOPLEFT", frame.pageTitle, "BOTTOMLEFT", 0, -6)

  frame.content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.content:SetPoint("TOPLEFT", frame.sidebar, "TOPRIGHT", 12, 0)
  frame.content:SetPoint("BOTTOMRIGHT", -12, 12)
  frame.content:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame.content:SetBackdropColor(0.09, 0.11, 0.16, 0.96)
  frame.content:SetBackdropBorderColor(0.20, 0.26, 0.34, 1)

  frame.pageHost = CreateFrame("Frame", nil, frame.content)
  frame.pageHost:SetPoint("TOPLEFT", 10, -42)
  frame.pageHost:SetPoint("BOTTOMRIGHT", -10, 10)

  self.frame = frame
  self.pages = {}
  self.pageButtons = {}

  for index, pageDefinition in ipairs(pageDefinitions) do
    local button = CreateButton(frame.sidebar, pageDefinition.label, 140, 26, function()
      ConfigWindow:ShowPage(pageDefinition.key)
    end)
    button:SetPoint("TOPLEFT", 12, -14 - ((index - 1) * 34))
    self.pageButtons[pageDefinition.key] = button
  end

  self:CreateGeneralPage()
  self:CreatePlayerPage()
  self:CreateTargetPage()
  self:CreateSecondaryPage()
  self:CreateProfilesPage()
  self:CreateImportExportPage()

  self:ShowPage(ns.DB:GetCharacterRoot().ui.selectedPage or "general")
  return frame
end

function ConfigWindow:ShowPage(pageKey)
  self:Create()

  self.activePageKey = pageKey or self.activePageKey or "general"
  ns.DB:GetCharacterRoot().ui.selectedPage = self.activePageKey

  for key, page in pairs(self.pages) do
    page:SetShown(key == self.activePageKey)
  end

  for key, button in pairs(self.pageButtons) do
    local active = key == self.activePageKey
    button:SetBackdropColor(active and 0.08 or 0.10, active and 0.42 or 0.13, active and 0.82 or 0.18, 0.96)
    button:SetBackdropBorderColor(active and 0.18 or 0.24, active and 0.62 or 0.30, active and 1.0 or 0.40, 1)
  end

  self.frame.pageTitle:SetText(GetEntryLabel(pageDefinitions, self.activePageKey))
  self:Refresh()
end

function ConfigWindow:Refresh()
  if not self.frame then
    return
  end

  local activePage = self.pages[self.activePageKey]
  if activePage and activePage.refresh then
    activePage:refresh()
  end
end

function ConfigWindow:Open(pageKey)
  self:Create()
  ns.Anchors.Apply(self.frame, ns.DB:GetConfigWindowState())
  self.frame:Show()
  self:ShowPage(pageKey or self.activePageKey or "general")
end

function ConfigWindow:CreateGeneralPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content
  page.controls = {}

  local intro = CreateLabel(content, "The main HUD stays text-only, but the config is now a standalone editor like PopAuras.", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", 10, -8)

  page.visibilityBox = CreateSectionBox(content, "Visibility", 10, -36, PAGE_SECTION_WIDTH, 94)
  page.visibilityBox.playerHP = CreateCheckbox(
    page.visibilityBox,
    "Show Player Health",
    12,
    -38,
    function()
      return GetProfile().visibility.showPlayerHP
    end,
    function(checked)
      GetProfile().visibility.showPlayerHP = checked
    end
  )
  page.visibilityBox.playerPower = CreateCheckbox(
    page.visibilityBox,
    "Show Player Power",
    200,
    -38,
    function()
      return GetProfile().visibility.showPlayerPower
    end,
    function(checked)
      GetProfile().visibility.showPlayerPower = checked
    end
  )
  page.visibilityBox.targetHP = CreateCheckbox(
    page.visibilityBox,
    "Show Target Health",
    388,
    -38,
    function()
      return GetProfile().visibility.showTargetHP
    end,
    function(checked)
      GetProfile().visibility.showTargetHP = checked
    end
  )
  page.visibilityBox.targetPower = CreateCheckbox(
    page.visibilityBox,
    "Show Target Power",
    576,
    -38,
    function()
      return GetProfile().visibility.showTargetPower
    end,
    function(checked)
      GetProfile().visibility.showTargetPower = checked
    end
  )

  page.mainBox = CreateSectionBox(content, "Main HUD", 10, -142, PAGE_SECTION_WIDTH, 214)
  page.mainBox.controls = {}
  page.mainBox.locked = CreateCheckbox(
    page.mainBox,
    "Lock HUD",
    12,
    -38,
    function()
      return GetProfile().mainFrame.locked
    end,
    function(checked)
      GetProfile().mainFrame.locked = checked
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.locked

  page.mainBox.bgAlpha = CreateLabeledInput(
    page.mainBox,
    "Background %",
    140,
    -36,
    64,
    function()
      return math.floor((GetProfile().mainFrame.bgAlpha or 0) * 100 + 0.5)
    end,
    function(text)
      GetProfile().mainFrame.bgAlpha = ns.Clamp((tonumber(text) or 0) / 100, 0, 1)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.bgAlpha

  page.mainBox.point = CreateLabeledDropdown(
    page.mainBox,
    "Point",
    240,
    -36,
    140,
    ns.Anchors.GetPointList(),
    function()
      return GetProfile().mainFrame.point
    end,
    function(value)
      GetProfile().mainFrame.point = value
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.point

  page.mainBox.relativeTo = CreateLabeledDropdown(
    page.mainBox,
    "Relative To",
    410,
    -36,
    180,
    ns.Anchors.GetTargetList(),
    function()
      return GetProfile().mainFrame.relativeTo
    end,
    function(value)
      GetProfile().mainFrame.relativeTo = value
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.relativeTo

  page.mainBox.relativePoint = CreateLabeledDropdown(
    page.mainBox,
    "Relative Point",
    12,
    -106,
    140,
    ns.Anchors.GetPointList(),
    function()
      return GetProfile().mainFrame.relativePoint
    end,
    function(value)
      GetProfile().mainFrame.relativePoint = value
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.relativePoint

  page.mainBox.customRelativeTo = CreateLabeledInput(
    page.mainBox,
    "Custom Global",
    184,
    -106,
    160,
    function()
      return GetProfile().mainFrame.customRelativeTo or ""
    end,
    function(text)
      GetProfile().mainFrame.customRelativeTo = ns.TrimString(text)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.customRelativeTo

  page.mainBox.offsetX = CreateLabeledInput(
    page.mainBox,
    "Offset X",
    374,
    -106,
    72,
    function()
      return GetProfile().mainFrame.x
    end,
    function(text)
      GetProfile().mainFrame.x = math.floor(tonumber(text) or GetProfile().mainFrame.x or 0)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.offsetX

  page.mainBox.offsetY = CreateLabeledInput(
    page.mainBox,
    "Offset Y",
    472,
    -106,
    72,
    function()
      return GetProfile().mainFrame.y
    end,
    function(text)
      GetProfile().mainFrame.y = math.floor(tonumber(text) or GetProfile().mainFrame.y or 0)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.offsetY

  page.mainBox.width = CreateLabeledInput(
    page.mainBox,
    "Width",
    570,
    -106,
    64,
    function()
      return GetProfile().mainFrame.width
    end,
    function(text)
      GetProfile().mainFrame.width = math.max(280, tonumber(text) or GetProfile().mainFrame.width or 520)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.width

  page.mainBox.height = CreateLabeledInput(
    page.mainBox,
    "Height",
    650,
    -106,
    64,
    function()
      return GetProfile().mainFrame.height
    end,
    function(text)
      GetProfile().mainFrame.height = math.max(100, tonumber(text) or GetProfile().mainFrame.height or 160)
    end
  )
  page.mainBox.controls[#page.mainBox.controls + 1] = page.mainBox.height

  page.mainBox.resetButton = CreateButton(page.mainBox, "Reset Main Position", 148, 24, function()
    local defaults = ns.DB:NewDefaultProfile()
    GetProfile().mainFrame = ns.DeepCopy(defaults.mainFrame)
    ApplyAndRefresh()
  end, true)
  page.mainBox.resetButton:SetPoint("BOTTOMRIGHT", -12, 12)

  page.mainBox.refresh = function(self)
    RefreshControls(self.controls)
  end

  page.layoutBox = CreateSectionBox(content, "Layout", 10, -372, PAGE_SECTION_WIDTH, 188)
  page.layoutBox.controls = {}

  local function layoutValue(key)
    return GetProfile().layout[key]
  end

  page.layoutBox.gap = CreateLabeledInput(page.layoutBox, "Player / Target Gap", 12, -36, 72, function() return layoutValue("gap") end, function(text) GetProfile().layout.gap = math.max(0, tonumber(text) or layoutValue("gap") or 8) end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.gap
  page.layoutBox.pGap = CreateLabeledInput(page.layoutBox, "Player HP -> Power", 130, -36, 72, function() return layoutValue("pLineGap") end, function(text) GetProfile().layout.pLineGap = math.max(0, tonumber(text) or layoutValue("pLineGap") or 10) end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.pGap
  page.layoutBox.tGap = CreateLabeledInput(page.layoutBox, "Target HP -> Power", 260, -36, 72, function() return layoutValue("tLineGap") end, function(text) GetProfile().layout.tLineGap = math.max(0, tonumber(text) or layoutValue("tLineGap") or 0) end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.tGap
  page.layoutBox.offX = CreateLabeledInput(page.layoutBox, "Target Offset X", 392, -36, 72, function() return layoutValue("targetOffsetX") end, function(text) GetProfile().layout.targetOffsetX = math.floor(tonumber(text) or layoutValue("targetOffsetX") or 0) end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.offX
  page.layoutBox.offY = CreateLabeledInput(page.layoutBox, "Target Offset Y", 524, -36, 72, function() return layoutValue("targetOffsetY") end, function(text) GetProfile().layout.targetOffsetY = math.floor(tonumber(text) or layoutValue("targetOffsetY") or 0) end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.offY

  page.layoutBox.playerJustify = CreateLabeledDropdown(page.layoutBox, "Player Power Align", 12, -106, 150, justifyEntries, function() return layoutValue("playerPowerJustify") end, function(value) GetProfile().layout.playerPowerJustify = value end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.playerJustify
  page.layoutBox.targetJustify = CreateLabeledDropdown(page.layoutBox, "Target Power Align", 210, -106, 150, justifyEntries, function() return layoutValue("targetPowerJustify") end, function(value) GetProfile().layout.targetPowerJustify = value end)
  page.layoutBox.controls[#page.layoutBox.controls + 1] = page.layoutBox.targetJustify

  page.layoutBox.refresh = function(self)
    RefreshControls(self.controls)
  end

  page.refresh = function(self)
    page.mainBox:refresh()
    page.layoutBox:refresh()
    page.visibilityBox.playerHP:refresh()
    page.visibilityBox.playerPower:refresh()
    page.visibilityBox.targetHP:refresh()
    page.visibilityBox.targetPower:refresh()
  end

  content:SetHeight(600)
  self.pages.general = page
end

function ConfigWindow:CreatePlayerPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content
  page.selectedPowerConfigKey = "DEFAULT"

  page.hpStyle = CreateTextStyleEditor(content, "Player Health Text", 10, -10, function()
    return GetProfile().player.hpText
  end)
  page.hpColor = CreateColorSection(content, "Player Health Color", 10, -176, playerHpColorEntries, function()
    return GetProfile().player
  end, "hpColorMode", "hpFixedColor", "hpCurve")

  local function GetSelectedPlayerPowerOverride(createIfMissing)
    if page.selectedPowerConfigKey == "DEFAULT" then
      return nil
    end

    local player = GetProfile().player
    player.powerOverrides = player.powerOverrides or {}

    local override = player.powerOverrides[page.selectedPowerConfigKey]
    if type(override) ~= "table" and createIfMissing == true then
      override = ns.DB:NewPlayerPowerOverrideConfig()
      override.textStyle = ns.DeepCopy(player.powerText)
      override.colorMode = player.powerColorMode
      override.fixedColor = ns.CopyColor(player.powerFixedColor)
      override.colorCurve = ns.DeepCopy(player.powerCurve)
      player.powerOverrides[page.selectedPowerConfigKey] = override
    end

    return override
  end

  local playerPowerColorProxy = setmetatable({}, {
    __index = function(_, key)
      if page.selectedPowerConfigKey == "DEFAULT" then
        local player = GetProfile().player
        if key == "colorMode" then
          return player.powerColorMode
        elseif key == "fixedColor" then
          return player.powerFixedColor
        elseif key == "colorCurve" then
          return player.powerCurve
        end
      end

      local override = GetSelectedPlayerPowerOverride(true)
      if override then
        return override[key]
      end
      return nil
    end,
    __newindex = function(_, key, value)
      if page.selectedPowerConfigKey == "DEFAULT" then
        local player = GetProfile().player
        if key == "colorMode" then
          player.powerColorMode = value
        elseif key == "fixedColor" then
          player.powerFixedColor = value
        elseif key == "colorCurve" then
          player.powerCurve = value
        end
        return
      end

      local override = GetSelectedPlayerPowerOverride(true)
      if override then
        override[key] = value
      end
    end,
  })

  page.powerConfigBox = CreateSectionBox(content, "Player Power Profiles", 10, -478, PAGE_SECTION_WIDTH, 112)
  page.powerConfigBox.controls = {}
  page.powerConfigBox.profile = CreateLabeledDropdown(
    page.powerConfigBox,
    "Editing",
    12,
    -36,
    220,
    playerPowerConfigEntries,
    function()
      return page.selectedPowerConfigKey
    end,
    function(value)
      page.selectedPowerConfigKey = value or "DEFAULT"
    end
  )
  page.powerConfigBox.controls[#page.powerConfigBox.controls + 1] = page.powerConfigBox.profile

  page.powerConfigBox.overrideToggle = CreateCheckbox(
    page.powerConfigBox,
    "Enable Override For This Power",
    280,
    -42,
    function()
      local override = GetSelectedPlayerPowerOverride(false)
      return override and override.enabled == true or false
    end,
    function(checked)
      local override = GetSelectedPlayerPowerOverride(true)
      if override then
        override.enabled = checked
      end
    end
  )
  page.powerConfigBox.controls[#page.powerConfigBox.controls + 1] = page.powerConfigBox.overrideToggle

  page.powerConfigBox.note = CreateLabel(page.powerConfigBox, "", "GameFontHighlightSmall")
  page.powerConfigBox.note:SetPoint("TOPLEFT", 12, -78)
  page.powerConfigBox.note:SetWidth(PAGE_SECTION_WIDTH - 40)
  page.powerConfigBox.note:SetJustifyH("LEFT")
  page.powerConfigBox.note:SetJustifyV("TOP")

  page.powerConfigBox.refresh = function(self)
    RefreshControls(self.controls)

    local isDefault = page.selectedPowerConfigKey == "DEFAULT"
    self.overrideToggle:SetShown(not isDefault)

    if isDefault then
      self.note:SetText("Defaults apply to every player power type unless you enable a specific override.")
    else
      self.note:SetText("Edit an optional override for " .. GetEntryLabel(playerPowerConfigEntries, page.selectedPowerConfigKey) .. ". Disabled overrides fall back to the default player power settings.")
    end
  end

  page.powerStyle = CreateTextStyleEditor(content, "Player Power Text", 10, -606, function()
    if page.selectedPowerConfigKey == "DEFAULT" then
      return GetProfile().player.powerText
    end

    local override = GetSelectedPlayerPowerOverride(true)
    return override.textStyle
  end)
  page.powerColor = CreateColorSection(content, "Player Power Color", 10, -772, powerColorEntries, function()
    return playerPowerColorProxy
  end, "colorMode", "fixedColor", "colorCurve")

  page.Layout = function(self)
    local y = -10
    SetTopLeft(self.hpStyle, 10, y)
    y = y - self.hpStyle:GetHeight() - 16

    SetTopLeft(self.hpColor, 10, y)
    y = y - self.hpColor:GetHeight() - 16

    SetTopLeft(self.powerConfigBox, 10, y)
    y = y - self.powerConfigBox:GetHeight() - 16

    SetTopLeft(self.powerStyle, 10, y)
    y = y - self.powerStyle:GetHeight() - 16

    SetTopLeft(self.powerColor, 10, y)
    y = y - self.powerColor:GetHeight() - 24

    content:SetHeight(math.abs(y) + 20)
  end

  page.refresh = function(self)
    local titleSuffix = page.selectedPowerConfigKey == "DEFAULT" and "" or ": " .. GetEntryLabel(playerPowerConfigEntries, page.selectedPowerConfigKey)
    self.powerStyle.title:SetText("Player Power Text" .. titleSuffix)
    self.powerColor.title:SetText("Player Power Color" .. titleSuffix)

    self.hpStyle:refresh()
    self.hpColor:refresh()
    self.powerConfigBox:refresh()
    self.powerStyle:refresh()
    self.powerColor:refresh()
    self:Layout()
  end

  page:Layout()
  self.pages.player = page
end

function ConfigWindow:CreateTargetPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content

  page.hpStyle = CreateTextStyleEditor(content, "Target Health Text", 10, -10, function()
    return GetProfile().target.hpText
  end)
  page.hpColor = CreateColorSection(content, "Target Health Color", 10, -176, targetHpColorEntries, function()
    return GetProfile().target
  end, "hpColorMode", "hpFixedColor", "hpCurve")
  page.powerStyle = CreateTextStyleEditor(content, "Target Power Text", 10, -478, function()
    return GetProfile().target.powerText
  end)
  page.powerColor = CreateColorSection(content, "Target Power Color", 10, -644, powerColorEntries, function()
    return GetProfile().target
  end, "powerColorMode", "powerFixedColor", "powerCurve")

  page.Layout = function(self)
    local y = -10
    SetTopLeft(self.hpStyle, 10, y)
    y = y - self.hpStyle:GetHeight() - 16

    SetTopLeft(self.hpColor, 10, y)
    y = y - self.hpColor:GetHeight() - 16

    SetTopLeft(self.powerStyle, 10, y)
    y = y - self.powerStyle:GetHeight() - 16

    SetTopLeft(self.powerColor, 10, y)
    y = y - self.powerColor:GetHeight() - 24

    content:SetHeight(math.abs(y) + 20)
  end

  page.refresh = function(self)
    self.hpStyle:refresh()
    self.hpColor:refresh()
    self.powerStyle:refresh()
    self.powerColor:refresh()
    self:Layout()
  end

  page:Layout()
  self.pages.target = page
end

function ConfigWindow:CreateSecondaryPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content
  page.controls = {}
  page.selectedSecondaryColorKey = "DEFAULT"

  local function GetSelectedSecondaryColorOverride(createIfMissing)
    if page.selectedSecondaryColorKey == "DEFAULT" then
      return nil
    end

    local secondary = GetProfile().secondary
    secondary.colorOverrides = secondary.colorOverrides or {}

    local override = secondary.colorOverrides[page.selectedSecondaryColorKey]
    if type(override) ~= "table" and createIfMissing == true then
      override = ns.DB:NewSecondaryColorOverrideConfig()
      override.colorMode = secondary.colorMode
      override.fixedColor = ns.CopyColor(secondary.fixedColor)
      override.colorCurve = ns.DeepCopy(secondary.colorCurve)
      secondary.colorOverrides[page.selectedSecondaryColorKey] = override
    end

    return override
  end

  local secondaryColorProxy = setmetatable({}, {
    __index = function(_, key)
      if page.selectedSecondaryColorKey == "DEFAULT" then
        local secondary = GetProfile().secondary
        if key == "colorMode" then
          return secondary.colorMode
        elseif key == "fixedColor" then
          return secondary.fixedColor
        elseif key == "colorCurve" then
          return secondary.colorCurve
        end
      end

      local override = GetSelectedSecondaryColorOverride(true)
      if override then
        return override[key]
      end
      return nil
    end,
    __newindex = function(_, key, value)
      if page.selectedSecondaryColorKey == "DEFAULT" then
        local secondary = GetProfile().secondary
        if key == "colorMode" then
          secondary.colorMode = value
        elseif key == "fixedColor" then
          secondary.fixedColor = value
        elseif key == "colorCurve" then
          secondary.colorCurve = value
        end
        return
      end

      local override = GetSelectedSecondaryColorOverride(true)
      if override then
        override[key] = value
      end
    end,
  })

  page.settingsBox = CreateSectionBox(content, "Secondary Window", 10, -10, PAGE_SECTION_WIDTH, 148)
  page.settingsBox.controls = {}

  page.settingsBox.showToggle = CreateCheckbox(
    page.settingsBox,
    "Show Secondary Window",
    12,
    -38,
    function()
      return GetProfile().visibility.showSecondary
    end,
    function(checked)
      GetProfile().visibility.showSecondary = checked
      GetProfile().secondary.enabled = checked
    end
  )
  page.settingsBox.controls[#page.settingsBox.controls + 1] = page.settingsBox.showToggle

  page.settingsBox.hideWhenInactive = CreateCheckbox(
    page.settingsBox,
    "Hide When Inactive / Wrong Form",
    200,
    -38,
    function()
      return GetProfile().secondary.hideWhenInactive
    end,
    function(checked)
      GetProfile().secondary.hideWhenInactive = checked
    end
  )
  page.settingsBox.controls[#page.settingsBox.controls + 1] = page.settingsBox.hideWhenInactive

  page.settingsBox.mode = CreateLabeledDropdown(
    page.settingsBox,
    "Resource",
    12,
    -88,
    190,
    ns.secondaryResourceEntries,
    function()
      return GetProfile().secondary.resourceMode
    end,
    function(value)
      GetProfile().secondary.resourceMode = value
      local definitions = {
        COMBO_POINTS = 5,
        HOLY_POWER = 5,
        CHI = 6,
        SOUL_SHARDS = 5,
      }
      if definitions[value] then
        GetProfile().secondary.maxValue = definitions[value]
      end
    end
  )
  page.settingsBox.controls[#page.settingsBox.controls + 1] = page.settingsBox.mode

  page.settingsBox.maxValue = CreateLabeledInput(
    page.settingsBox,
    "Display Max",
    238,
    -88,
    64,
    function()
      return GetProfile().secondary.maxValue
    end,
    function(text)
      GetProfile().secondary.maxValue = math.max(1, tonumber(text) or GetProfile().secondary.maxValue or 5)
    end
  )
  page.settingsBox.controls[#page.settingsBox.controls + 1] = page.settingsBox.maxValue

  page.settingsBox.showLabel = CreateCheckbox(
    page.settingsBox,
    "Show Label",
    350,
    -94,
    function()
      return GetProfile().secondary.showLabel
    end,
    function(checked)
      GetProfile().secondary.showLabel = checked
    end
  )
  page.settingsBox.controls[#page.settingsBox.controls + 1] = page.settingsBox.showLabel

  page.settingsBox.refresh = function(self)
    RefreshControls(self.controls)
  end

  page.colorConfigBox = CreateSectionBox(content, "Secondary Color Profiles", 10, -174, PAGE_SECTION_WIDTH, 112)
  page.colorConfigBox.controls = {}
  page.colorConfigBox.profile = CreateLabeledDropdown(
    page.colorConfigBox,
    "Editing",
    12,
    -36,
    220,
    secondaryColorConfigEntries,
    function()
      return page.selectedSecondaryColorKey
    end,
    function(value)
      page.selectedSecondaryColorKey = value or "DEFAULT"
    end
  )
  page.colorConfigBox.controls[#page.colorConfigBox.controls + 1] = page.colorConfigBox.profile

  page.colorConfigBox.overrideToggle = CreateCheckbox(
    page.colorConfigBox,
    "Enable Override For This Secondary",
    280,
    -42,
    function()
      local override = GetSelectedSecondaryColorOverride(false)
      return override and override.enabled == true or false
    end,
    function(checked)
      local override = GetSelectedSecondaryColorOverride(true)
      if override then
        override.enabled = checked
      end
    end
  )
  page.colorConfigBox.controls[#page.colorConfigBox.controls + 1] = page.colorConfigBox.overrideToggle

  page.colorConfigBox.note = CreateLabel(page.colorConfigBox, "", "GameFontHighlightSmall")
  page.colorConfigBox.note:SetPoint("TOPLEFT", 12, -78)
  page.colorConfigBox.note:SetWidth(PAGE_SECTION_WIDTH - 40)
  page.colorConfigBox.note:SetJustifyH("LEFT")
  page.colorConfigBox.note:SetJustifyV("TOP")

  page.colorConfigBox.refresh = function(self)
    RefreshControls(self.controls)

    local isDefault = page.selectedSecondaryColorKey == "DEFAULT"
    self.overrideToggle:SetShown(not isDefault)

    if isDefault then
      self.note:SetText("Defaults apply to every secondary resource unless you enable a specific override.")
    else
      self.note:SetText("Edit an optional override for " .. GetEntryLabel(secondaryColorConfigEntries, page.selectedSecondaryColorKey) .. ". Disabled overrides fall back to the default secondary color settings.")
    end
  end

  page.colorBox = CreateColorSection(content, "Secondary Color", 10, -302, secondaryColorEntries, function()
    return secondaryColorProxy
  end, "colorMode", "fixedColor", "colorCurve")

  page.labelStyle = CreateTextStyleEditor(content, "Secondary Label Style", 10, -362, function()
    return GetProfile().secondary.labelStyle
  end)
  page.valueStyle = CreateTextStyleEditor(content, "Secondary Value Text", 10, -528, function()
    return GetProfile().secondary.valueStyle
  end)

  page.positionBox = CreateSectionBox(content, "Secondary Position", 10, -694, PAGE_SECTION_WIDTH, 226)
  page.positionBox.controls = {}
  page.positionBox.locked = CreateCheckbox(page.positionBox, "Lock Window", 12, -38, function() return GetProfile().secondary.locked end, function(checked) GetProfile().secondary.locked = checked end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.locked
  page.positionBox.bgAlpha = CreateLabeledInput(page.positionBox, "Background %", 140, -36, 64, function() return math.floor((GetProfile().secondary.bgAlpha or 0) * 100 + 0.5) end, function(text) GetProfile().secondary.bgAlpha = ns.Clamp((tonumber(text) or 0) / 100, 0, 1) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.bgAlpha
  page.positionBox.point = CreateLabeledDropdown(page.positionBox, "Point", 240, -36, 140, ns.Anchors.GetPointList(), function() return GetProfile().secondary.point end, function(value) GetProfile().secondary.point = value end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.point
  page.positionBox.relativeTo = CreateLabeledDropdown(page.positionBox, "Relative To", 410, -36, 180, ns.Anchors.GetTargetList(), function() return GetProfile().secondary.relativeTo end, function(value) GetProfile().secondary.relativeTo = value end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.relativeTo
  page.positionBox.relativePoint = CreateLabeledDropdown(page.positionBox, "Relative Point", 12, -106, 140, ns.Anchors.GetPointList(), function() return GetProfile().secondary.relativePoint end, function(value) GetProfile().secondary.relativePoint = value end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.relativePoint
  page.positionBox.customRelativeTo = CreateLabeledInput(page.positionBox, "Custom Global", 184, -106, 160, function() return GetProfile().secondary.customRelativeTo or "" end, function(text) GetProfile().secondary.customRelativeTo = ns.TrimString(text) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.customRelativeTo
  page.positionBox.offsetX = CreateLabeledInput(page.positionBox, "Offset X", 374, -106, 72, function() return GetProfile().secondary.x end, function(text) GetProfile().secondary.x = math.floor(tonumber(text) or GetProfile().secondary.x or 0) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.offsetX
  page.positionBox.offsetY = CreateLabeledInput(page.positionBox, "Offset Y", 472, -106, 72, function() return GetProfile().secondary.y end, function(text) GetProfile().secondary.y = math.floor(tonumber(text) or GetProfile().secondary.y or 0) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.offsetY
  page.positionBox.width = CreateLabeledInput(page.positionBox, "Width", 570, -106, 64, function() return GetProfile().secondary.width end, function(text) GetProfile().secondary.width = math.max(90, tonumber(text) or GetProfile().secondary.width or 180) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.width
  page.positionBox.height = CreateLabeledInput(page.positionBox, "Height", 650, -106, 64, function() return GetProfile().secondary.height end, function(text) GetProfile().secondary.height = math.max(40, tonumber(text) or GetProfile().secondary.height or 78) end)
  page.positionBox.controls[#page.positionBox.controls + 1] = page.positionBox.height
  page.positionBox.resetButton = CreateButton(page.positionBox, "Reset Secondary Position", 176, 24, function()
    local defaults = ns.DB:NewDefaultProfile()
    local current = GetProfile().secondary
    current.point = defaults.secondary.point
    current.relativeTo = defaults.secondary.relativeTo
    current.customRelativeTo = defaults.secondary.customRelativeTo
    current.relativePoint = defaults.secondary.relativePoint
    current.x = defaults.secondary.x
    current.y = defaults.secondary.y
    current.width = defaults.secondary.width
    current.height = defaults.secondary.height
    ApplyAndRefresh()
  end, true)
  page.positionBox.resetButton:SetPoint("BOTTOMRIGHT", -12, 12)
  page.positionBox.refresh = function(self)
    RefreshControls(self.controls)
  end

  page.Layout = function(self)
    local y = -10

    SetTopLeft(self.settingsBox, 10, y)
    y = y - self.settingsBox:GetHeight() - 16

    SetTopLeft(self.colorConfigBox, 10, y)
    y = y - self.colorConfigBox:GetHeight() - 16

    SetTopLeft(self.colorBox, 10, y)
    y = y - self.colorBox:GetHeight() - 16

    if GetProfile().secondary.showLabel then
      self.labelStyle:Show()
      SetTopLeft(self.labelStyle, 10, y)
      y = y - self.labelStyle:GetHeight() - 16
    else
      self.labelStyle:Hide()
    end

    self.valueStyle:Show()
    SetTopLeft(self.valueStyle, 10, y)
    y = y - self.valueStyle:GetHeight() - 16

    SetTopLeft(self.positionBox, 10, y)
    y = y - self.positionBox:GetHeight() - 24

    content:SetHeight(math.abs(y) + 20)
  end

  page.refresh = function(self)
    self.settingsBox:refresh()
    self.colorConfigBox:refresh()
    local titleSuffix = page.selectedSecondaryColorKey == "DEFAULT" and "" or ": " .. GetEntryLabel(secondaryColorConfigEntries, page.selectedSecondaryColorKey)
    self.colorBox.title:SetText("Secondary Color" .. titleSuffix)
    self.colorBox:refresh()
    self.labelStyle:refresh()
    self.valueStyle:refresh()
    self.positionBox:refresh()
    self:Layout()
  end

  page:Layout()
  self.pages.secondary = page
end

function ConfigWindow:CreateProfilesPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content
  page.controls = {}

  page.scopeBox = CreateSectionBox(content, "Active Scope", 10, -10, PAGE_SECTION_WIDTH, 120)
  page.scopeBox.controls = {}
  page.scopeBox.scope = CreateLabeledDropdown(page.scopeBox, "Scope", 12, -36, 180, scopeEntries, function() return ns.DB:GetActiveScope() end, function(value) ns.DB:SetActiveScope(value) end)
  page.scopeBox.controls[#page.scopeBox.controls + 1] = page.scopeBox.scope
  page.scopeBox.activeProfile = CreateLabeledDropdown(page.scopeBox, "Active Profile", 250, -36, 220, {}, function() return ns.DB:GetActiveProfileName() end, function(value) ns.DB:SetActiveProfile(ns.DB:GetActiveScope(), value) end)
  page.scopeBox.activeProfile.dropdown.entries = {}
  page.scopeBox.controls[#page.scopeBox.controls + 1] = page.scopeBox.activeProfile
  page.scopeBox.refresh = function(self)
    self.activeProfile.dropdown.entries = {}
    for _, name in ipairs(ns.DB:GetProfileNames(ns.DB:GetActiveScope())) do
      self.activeProfile.dropdown.entries[#self.activeProfile.dropdown.entries + 1] = { key = name, label = name }
    end
    RefreshControls(self.controls)
  end

  page.manageBox = CreateSectionBox(content, "Manage Profiles", 10, -146, PAGE_SECTION_WIDTH, 190)
  page.manageBox.controls = {}
  page.manageBox.nameInput = CreateLabeledInput(page.manageBox, "Profile Name", 12, -36, 180, function() return "" end, function() end)
  page.manageBox.createButton = CreateButton(page.manageBox, "Create", 88, 24, function()
    local name = ns.TrimString(page.manageBox.nameInput.input:GetText())
    if name == "" then
      return
    end
    local _, err = ns.DB:CreateProfile(ns.DB:GetActiveScope(), name, nil)
    if err then
      print("SimpleUnitText: " .. err)
      return
    end
    ns.DB:SetActiveProfile(ns.DB:GetActiveScope(), name)
    page.manageBox.nameInput.input:SetText("")
    ApplyAndRefresh()
  end, true)
  page.manageBox.createButton:SetPoint("TOPLEFT", 230, -56)

  page.manageBox.copyButton = CreateButton(page.manageBox, "Copy Active", 108, 24, function()
    local name = ns.TrimString(page.manageBox.nameInput.input:GetText())
    if name == "" then
      return
    end
    local source = ns.DB:GetProfileCopy(ns.DB:GetActiveScope(), ns.DB:GetActiveProfileName())
    local _, err = ns.DB:CreateProfile(ns.DB:GetActiveScope(), name, source)
    if err then
      print("SimpleUnitText: " .. err)
      return
    end
    ns.DB:SetActiveProfile(ns.DB:GetActiveScope(), name)
    page.manageBox.nameInput.input:SetText("")
    ApplyAndRefresh()
  end)
  page.manageBox.copyButton:SetPoint("LEFT", page.manageBox.createButton, "RIGHT", 10, 0)

  page.manageBox.deleteButton = CreateButton(page.manageBox, "Delete Active", 108, 24, function()
    local ok, err = ns.DB:DeleteProfile(ns.DB:GetActiveScope(), ns.DB:GetActiveProfileName())
    if not ok then
      print("SimpleUnitText: " .. tostring(err))
      return
    end
    ApplyAndRefresh()
  end)
  page.manageBox.deleteButton:SetPoint("LEFT", page.manageBox.copyButton, "RIGHT", 10, 0)

  page.manageBox.resetButton = CreateButton(page.manageBox, "Reset Active", 96, 24, function()
    ns.DB:ResetProfile(ns.DB:GetActiveScope(), ns.DB:GetActiveProfileName())
    ApplyAndRefresh()
  end)
  page.manageBox.resetButton:SetPoint("LEFT", page.manageBox.deleteButton, "RIGHT", 10, 0)

  page.manageBox.copyOtherScope = CreateButton(page.manageBox, "Copy To Other Scope", 164, 24, function()
    local name = ns.TrimString(page.manageBox.nameInput.input:GetText())
    if name == "" then
      name = ns.DB:GetActiveProfileName()
    end
    local source = ns.DB:GetProfileCopy(ns.DB:GetActiveScope(), ns.DB:GetActiveProfileName())
    local otherScope = ns.DB:GetActiveScope() == ns.PROFILE_SCOPE_GLOBAL and ns.PROFILE_SCOPE_CHARACTER or ns.PROFILE_SCOPE_GLOBAL
    local _, err = ns.DB:CreateProfile(otherScope, name, source)
    if err then
      print("SimpleUnitText: " .. err)
      return
    end
    print(string.format("SimpleUnitText: copied '%s' to %s scope.", name, otherScope))
    ApplyAndRefresh()
  end)
  page.manageBox.copyOtherScope:SetPoint("TOPLEFT", 12, -120)

  page.manageBox.info = CreateLabel(page.manageBox, "", "GameFontHighlightSmall")
  page.manageBox.info:SetPoint("TOPLEFT", page.manageBox.copyOtherScope, "BOTTOMLEFT", 0, -12)
  page.manageBox.refresh = function(self)
    self.info:SetText(string.format(
      "Global profiles live in SimpleUnitTextDB. Character profiles live in SimpleUnitTextCharDB. Current scope: %s, active profile: %s.",
      ns.DB:GetActiveScope(),
      ns.DB:GetActiveProfileName()
    ))
  end

  page.refresh = function(self)
    self.scopeBox:refresh()
    self.manageBox:refresh()
  end

  content:SetHeight(420)
  self.pages.profiles = page
end

function ConfigWindow:CreateImportExportPage()
  local page = CreatePageContainer(self.frame.pageHost)
  local content = page.content

  page.desc = CreateLabel(
    content,
    "Export the active profile to a copyable string, or import into global or character scope.",
    "GameFontHighlight"
  )
  page.desc:SetPoint("TOPLEFT", 12, -10)

  page.boxHolder = CreateFrame("Frame", nil, content, "BackdropTemplate")
  page.boxHolder:SetPoint("TOPLEFT", 12, -40)
  page.boxHolder:SetSize(IMPORT_BOX_WIDTH, 350)
  page.boxHolder:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  page.boxHolder:SetBackdropColor(0.05, 0.07, 0.10, 0.92)
  page.boxHolder:SetBackdropBorderColor(0.25, 0.33, 0.45, 1)

  page.scroll = CreateFrame("ScrollFrame", nil, page.boxHolder, "UIPanelScrollFrameTemplate")
  page.scroll:SetPoint("TOPLEFT", 8, -8)
  page.scroll:SetPoint("BOTTOMRIGHT", -30, 8)

  page.editBox = CreateFrame("EditBox", nil, page.scroll)
  page.editBox:SetMultiLine(true)
  page.editBox:SetWidth(IMPORT_EDIT_WIDTH)
  page.editBox:SetPoint("TOPLEFT", 0, 0)
  page.editBox:SetAutoFocus(false)
  page.editBox:SetFontObject(ChatFontNormal)
  page.editBox:SetJustifyH("LEFT")
  page.editBox:SetJustifyV("TOP")
  page.editBox:SetTextInsets(8, 8, 8, 8)
  page.editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  page.editBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    local lineCount = 1
    for _ in text:gmatch("\n") do
      lineCount = lineCount + 1
    end
    self:SetHeight(math.max(320, lineCount * 16 + 32))
  end)
  page.scroll:SetScrollChild(page.editBox)
  page.editBox:SetHeight(320)

  page.exportButton = CreateButton(content, "Export Active Profile", 160, 24, function()
    local encoded = ns.Export:EncodeProfile(ns.DB:GetActiveScope(), ns.DB:GetActiveProfileName())
    page.editBox:SetText(encoded)
    page.editBox:SetFocus()
    page.editBox:HighlightText()
  end, true)
  page.exportButton:SetPoint("TOPLEFT", page.boxHolder, "BOTTOMLEFT", 0, -14)

  page.importScope = CreateLabeledDropdown(
    content,
    "Import Scope",
    190,
    -406,
    150,
    scopeEntries,
    function()
      return ns.DB:GetCharacterRoot().ui.importTargetScope
    end,
    function(value)
      ns.DB:GetCharacterRoot().ui.importTargetScope = value
    end
  )

  page.importName = CreateLabeledInput(
    content,
    "New Profile Name",
    370,
    -406,
    150,
    function()
      return ns.DB:GetCharacterRoot().ui.importProfileName or "Imported"
    end,
    function(text)
      ns.DB:GetCharacterRoot().ui.importProfileName = ns.TrimString(text)
    end
  )

  page.importButton = CreateButton(content, "Import As New", 120, 24, function()
    local result, err = ns.Export:Import(
      page.editBox:GetText(),
      ns.DB:GetCharacterRoot().ui.importTargetScope,
      ns.DB:GetCharacterRoot().ui.importProfileName,
      false
    )
    if not result then
      print("SimpleUnitText: " .. tostring(err))
      return
    end
    print(string.format("SimpleUnitText: imported '%s' into %s scope.", result.profileName, result.scope))
    ApplyAndRefresh()
  end)
  page.importButton:SetPoint("TOPLEFT", 550, -428)

  page.replaceButton = CreateButton(content, "Replace Current", 120, 24, function()
    local result, err = ns.Export:Import(page.editBox:GetText(), ns.DB:GetActiveScope(), nil, true)
    if not result then
      print("SimpleUnitText: " .. tostring(err))
      return
    end
    print(string.format("SimpleUnitText: replaced current profile '%s'.", result.profileName))
    ApplyAndRefresh()
  end)
  page.replaceButton:SetPoint("LEFT", page.importButton, "RIGHT", 10, 0)

  page.refresh = function(self)
    self.importScope:refresh()
    self.importName:refresh()
  end

  content:SetHeight(520)
  self.pages.import_export = page
end

local function CreateLauncherPanel()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then
    return
  end

  local panel = CreateFrame("Frame", "SimpleUnitTextSettingsLauncher", UIParent)
  panel.name = "SimpleUnitText"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("SimpleUnitText")

  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetText("Open the standalone config window to edit HUD layout, scoped profiles, curves, and exports.")

  local button = CreateButton(panel, "Open Config Window", 180, 26, function()
    ConfigWindow:Open()
  end, true)
  button:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)

  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
end

CreateLauncherPanel()
