local _, ns = ...

ns.Addon = ns.Addon or {}
local Addon = ns.Addon

local resourceEntries = {
  { key = "AUTO", label = "Auto Detect" },
  { key = "COMBO_POINTS", label = "Combo Points" },
  { key = "HOLY_POWER", label = "Holy Power" },
  { key = "CHI", label = "Chi" },
  { key = "SOUL_SHARDS", label = "Soul Shards" },
}

local resourceDefinitions = {
  COMBO_POINTS = {
    label = "Combo Points",
    enumKey = "ComboPoints",
    powerToken = "COMBO_POINTS",
    defaultMax = 5,
    allowedClasses = {
      ROGUE = true,
      DRUID = true,
    },
  },
  HOLY_POWER = {
    label = "Holy Power",
    enumKey = "HolyPower",
    powerToken = "HOLY_POWER",
    defaultMax = 5,
    allowedClasses = {
      PALADIN = true,
    },
  },
  CHI = {
    label = "Chi",
    enumKey = "Chi",
    powerToken = "CHI",
    defaultMax = 6,
    allowedClasses = {
      MONK = true,
    },
  },
  SOUL_SHARDS = {
    label = "Soul Shards",
    enumKey = "SoulShards",
    powerToken = "SOUL_SHARDS",
    defaultMax = 5,
    allowedClasses = {
      WARLOCK = true,
    },
  },
}

ns.secondaryResourceEntries = resourceEntries

local parent = CreateFrame("Frame", "SimpleUnitTextFrame", UIParent)
parent:SetClampedToScreen(false)
parent:SetMovable(true)

local secondaryFrame = CreateFrame("Frame", "SimpleUnitTextSecondaryFrame", UIParent)
secondaryFrame:SetClampedToScreen(false)
secondaryFrame:SetMovable(true)

local playerBlock = CreateFrame("Frame", nil, parent)
local targetBlock = CreateFrame("Frame", nil, parent)
playerBlock:EnableMouse(false)
targetBlock:EnableMouse(false)

parent.bg = parent:CreateTexture(nil, "BACKGROUND")
parent.bg:SetAllPoints(true)
parent.bg:SetColorTexture(0, 0, 0, 0)

secondaryFrame.bg = secondaryFrame:CreateTexture(nil, "BACKGROUND")
secondaryFrame.bg:SetAllPoints(true)
secondaryFrame.bg:SetColorTexture(0, 0, 0, 0)

local pHP = playerBlock:CreateFontString(nil, "OVERLAY")
local pPow = playerBlock:CreateFontString(nil, "OVERLAY")
local tHP = targetBlock:CreateFontString(nil, "OVERLAY")
local tPow = targetBlock:CreateFontString(nil, "OVERLAY")

local secondaryLabel = secondaryFrame:CreateFontString(nil, "OVERLAY")
local secondaryValue = secondaryFrame:CreateFontString(nil, "OVERLAY")

Addon.frame = parent
Addon.secondaryFrame = secondaryFrame
Addon.playerBlock = playerBlock
Addon.targetBlock = targetBlock

local compiledState = {
  playerHpCurve = nil,
  playerPowerCurve = nil,
  playerPowerOverrideCurves = {},
  targetHpCurve = nil,
  targetPowerCurve = nil,
  secondaryValueCurve = nil,
  secondaryColorCurve = nil,
  secondaryColorOverrideCurves = {},
}

local function ApplyTextStyle(fontString, style)
  if not fontString or type(style) ~= "table" then
    return
  end

  fontString:SetFont(style.fontFile or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", tonumber(style.size) or 12, style.flags or "")

  local shadow = style.shadow or {}
  if shadow.enabled == true then
    local color = shadow.color or ns.MakeColor(0, 0, 0, 1)
    fontString:SetShadowOffset(tonumber(shadow.offsetX) or 1, tonumber(shadow.offsetY) or -1)
    fontString:SetShadowColor(color.r or 0, color.g or 0, color.b or 0, color.a == nil and 1 or color.a)
  else
    fontString:SetShadowOffset(0, 0)
    fontString:SetShadowColor(0, 0, 0, 0)
  end
end

local function SetMovableState(frame, locked, anchorTable)
  if locked then
    frame:RegisterForDrag()
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
    frame:EnableMouse(false)
    return
  end

  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    ns.Anchors.SaveToScreenCenter(self, anchorTable)
  end)
end

local function GetScaleTo100()
  return CurveConstants and CurveConstants.ScaleTo100 or nil
end

local function GetClassRGB(unit)
  local _, classToken = UnitClass(unit)
  local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
  if classColor then
    return classColor.r, classColor.g, classColor.b
  end
  return 1, 1, 1
end

local function GetPowerRGBForToken(powerToken, fallbackR, fallbackG, fallbackB)
  local color = powerToken and PowerBarColor and PowerBarColor[powerToken]
  if color then
    return color.r, color.g, color.b
  end
  if fallbackR and fallbackG and fallbackB then
    return fallbackR, fallbackG, fallbackB
  end
  return 0.12, 0.62, 1.00
end

local function GetPowerRGBForUnit(unit)
  local ok, _, powerToken, r, g, b = pcall(UnitPowerType, unit)
  if ok then
    return GetPowerRGBForToken(powerToken, r, g, b)
  end
  return 0.12, 0.62, 1.00
end

local function GetTargetHPFallbackColor()
  if UnitIsPlayer("target") then
    return GetClassRGB("target")
  end

  local reaction = UnitReaction("target", "player")
  local reactionColor = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
  if reactionColor then
    return reactionColor.r, reactionColor.g, reactionColor.b
  end

  return 1, 0, 0
end

local function GetActivePlayerPowerOverride(profile, powerToken)
  if type(profile) ~= "table" or type(profile.player) ~= "table" then
    return nil
  end

  local overrides = profile.player.powerOverrides
  if type(overrides) ~= "table" or type(powerToken) ~= "string" then
    return nil
  end

  local override = overrides[powerToken]
  if type(override) == "table" and override.enabled == true then
    return override
  end

  return nil
end

local function GetPlayerPowerPresentation(profile, powerToken)
  local player = profile.player or {}
  local override = GetActivePlayerPowerOverride(profile, powerToken)
  if override then
    return (
      override.textStyle or player.powerText
    ), (
      override.colorMode or player.powerColorMode or "POWER"
    ), (
      override.fixedColor or player.powerFixedColor
    ), (
      compiledState.playerPowerOverrideCurves[powerToken] or compiledState.playerPowerCurve
    )
  end

  return (
    player.powerText
  ), (
    player.powerColorMode or "POWER"
  ), (
    player.powerFixedColor
  ), (
    compiledState.playerPowerCurve
  )
end

local function ApplyCurrentPlayerPowerStyle(profile)
  local _, powerToken = UnitPowerType("player")
  local textStyle = GetPlayerPowerPresentation(profile, powerToken)
  ApplyTextStyle(pPow, textStyle or profile.player.powerText)
end

local function GetActiveSecondaryColorOverride(profile, resourceMode)
  if type(profile) ~= "table" or type(profile.secondary) ~= "table" then
    return nil
  end

  local overrides = profile.secondary.colorOverrides
  if type(overrides) ~= "table" or type(resourceMode) ~= "string" then
    return nil
  end

  local override = overrides[resourceMode]
  if type(override) == "table" and override.enabled == true then
    return override
  end

  return nil
end

local function GetSecondaryColorPresentation(profile, resourceMode)
  local secondary = profile.secondary or {}
  local override = GetActiveSecondaryColorOverride(profile, resourceMode)
  if override then
    return (
      override.colorMode or secondary.colorMode or "POWER"
    ), (
      override.fixedColor or secondary.fixedColor
    ), (
      compiledState.secondaryColorOverrideCurves[resourceMode] or compiledState.secondaryColorCurve
    )
  end

  return (
    secondary.colorMode or "POWER"
  ), (
    secondary.fixedColor
  ), (
    compiledState.secondaryColorCurve
  )
end

local function SafeSetColorFromCurve(fontString, curve, evaluator, ...)
  if not curve or not evaluator then
    return false
  end

  local ok, color = pcall(evaluator, ...)
  if not ok or not color or not color.GetRGBA then
    return false
  end

  local r, g, b, a = color:GetRGBA()
  ns.SafeSetTextColor(fontString, r, g, b, a)
  return true
end

local function SetHealthPercentText(fontString, unit)
  if not UnitHealthPercent then
    fontString:SetText("??")
    return
  end

  local scaleTo100 = GetScaleTo100()
  if scaleTo100 then
    ns.SafeSetFormattedText(fontString, "%.0f", UnitHealthPercent(unit, false, scaleTo100))
    return
  end

  ns.SafeSetFormattedText(fontString, "%.0f", UnitHealthPercent(unit, false))
end

local function SetPowerText(fontString, unit)
  if not UnitExists(unit) then
    fontString:SetText("")
    return
  end

  local powerType, powerToken = UnitPowerType(unit)
  if powerToken == "MANA" and UnitPowerPercent then
    local scaleTo100 = GetScaleTo100()
    if scaleTo100 then
      ns.SafeSetFormattedText(fontString, "%.0f", UnitPowerPercent(unit, powerType, false, scaleTo100))
      return
    end
    ns.SafeSetFormattedText(fontString, "%.0f", UnitPowerPercent(unit, powerType, false))
    return
  end

  ns.SafeSetFormattedText(fontString, "%.0f", UnitPower(unit, powerType, false))
end

local function ResolveAutoResource()
  local playerClass = select(2, UnitClass("player"))
  if playerClass == "ROGUE" or playerClass == "DRUID" then
    return "COMBO_POINTS"
  elseif playerClass == "PALADIN" then
    return "HOLY_POWER"
  elseif playerClass == "MONK" then
    return "CHI"
  elseif playerClass == "WARLOCK" then
    return "SOUL_SHARDS"
  end
  return nil
end

local function ResolveSecondaryResource(profile)
  local mode = profile.secondary.resourceMode or "AUTO"
  if mode == "AUTO" then
    mode = ResolveAutoResource()
  end
  if not mode then
    return nil
  end
  return resourceDefinitions[mode], mode
end

local function IsSecondaryResourceRelevant(profile, resourceDefinition, mode)
  if not resourceDefinition then
    return false
  end

  if profile.secondary.hideWhenInactive ~= true then
    return true
  end

  local playerClass = select(2, UnitClass("player"))
  local allowedClasses = resourceDefinition.allowedClasses
  if allowedClasses and not allowedClasses[playerClass] then
    return false
  end

  if mode == "COMBO_POINTS" and playerClass == "DRUID" then
    local _, powerToken = UnitPowerType("player")
    return powerToken == "ENERGY"
  end

  return true
end

local function ShouldShowSecondary(profile)
  if not (profile.visibility.showSecondary and profile.secondary.enabled) then
    return false, nil, nil
  end

  local resourceDefinition, mode = ResolveSecondaryResource(profile)
  if not resourceDefinition then
    return false, nil, nil
  end

  if not IsSecondaryResourceRelevant(profile, resourceDefinition, mode) then
    return false, resourceDefinition, mode
  end

  return true, resourceDefinition, mode
end

local function SetSecondaryValueText(profile)
  local shouldShow, resourceDefinition = ShouldShowSecondary(profile)
  if not shouldShow or not resourceDefinition then
    secondaryValue:SetText("")
    return
  end

  local powerType = Enum and Enum.PowerType and Enum.PowerType[resourceDefinition.enumKey]
  if not powerType then
    secondaryValue:SetText("")
    return
  end

  local value = nil
  if UnitPowerPercent and compiledState.secondaryValueCurve then
    local ok, result = pcall(UnitPowerPercent, "player", powerType, false, compiledState.secondaryValueCurve)
    if ok then
      value = result
    end
  end

  if value == nil and UnitPower then
    local ok, result = pcall(UnitPower, "player", powerType, false)
    if ok then
      value = result
    end
  end

  ns.SafeSetFormattedText(secondaryValue, "%.0f", value)
end

function Addon:UpdateColors()
  local profile = ns.DB:GetActiveProfile()

  if profile.player.hpColorMode == "CURVE" and compiledState.playerHpCurve then
    SafeSetColorFromCurve(pHP, compiledState.playerHpCurve, UnitHealthPercent, "player", false, compiledState.playerHpCurve)
  elseif profile.player.hpColorMode == "FIXED" then
    local color = profile.player.hpFixedColor
    ns.SafeSetTextColor(pHP, color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
  else
    ns.SafeSetTextColor(pHP, GetClassRGB("player"))
  end

  local playerPowerType, playerPowerToken = UnitPowerType("player")
  local _, playerPowerColorMode, playerPowerFixedColor, playerPowerCurve = GetPlayerPowerPresentation(profile, playerPowerToken)
  if playerPowerColorMode == "CURVE" and playerPowerCurve and playerPowerType ~= nil then
    SafeSetColorFromCurve(pPow, playerPowerCurve, UnitPowerPercent, "player", playerPowerType, false, playerPowerCurve)
  elseif playerPowerColorMode == "FIXED" then
    local color = playerPowerFixedColor or profile.player.powerFixedColor
    ns.SafeSetTextColor(pPow, color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
  else
    ns.SafeSetTextColor(pPow, GetPowerRGBForUnit("player"))
  end

  if UnitExists("target") then
    if profile.target.hpColorMode == "CURVE" and compiledState.targetHpCurve then
      SafeSetColorFromCurve(tHP, compiledState.targetHpCurve, UnitHealthPercent, "target", false, compiledState.targetHpCurve)
    elseif profile.target.hpColorMode == "FIXED" then
      local color = profile.target.hpFixedColor
      ns.SafeSetTextColor(tHP, color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
    else
      ns.SafeSetTextColor(tHP, GetTargetHPFallbackColor())
    end

    local targetPowerType, targetPowerToken = UnitPowerType("target")
    if profile.target.powerColorMode == "CURVE" and compiledState.targetPowerCurve and targetPowerType ~= nil then
      SafeSetColorFromCurve(tPow, compiledState.targetPowerCurve, UnitPowerPercent, "target", targetPowerType, false, compiledState.targetPowerCurve)
    elseif profile.target.powerColorMode == "FIXED" then
      local color = profile.target.powerFixedColor
      ns.SafeSetTextColor(tPow, color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
    else
      ns.SafeSetTextColor(tPow, GetPowerRGBForUnit("target"))
    end
  else
    ns.SafeSetTextColor(tHP, 1, 0, 0, 1)
    ns.SafeSetTextColor(tPow, 0.70, 0.70, 0.70, 1)
  end

  local showSecondary, secondaryResourceDefinition, secondaryResourceMode = ShouldShowSecondary(profile)
  local secondaryColorMode, secondaryFixedColor, secondaryColorCurve = GetSecondaryColorPresentation(profile, secondaryResourceMode)
  if secondaryColorMode == "CURVE" and secondaryColorCurve and showSecondary == true and secondaryResourceDefinition then
    local powerType = Enum and Enum.PowerType and Enum.PowerType[secondaryResourceDefinition.enumKey]
    local appliedCurveColor = false
    if powerType then
      appliedCurveColor = SafeSetColorFromCurve(
        secondaryValue,
        secondaryColorCurve,
        UnitPowerPercent,
        "player",
        powerType,
        false,
        secondaryColorCurve
      )
    end

    if not appliedCurveColor then
      ns.SafeSetTextColor(secondaryValue, GetPowerRGBForToken(secondaryResourceDefinition.powerToken))
    end
  elseif secondaryColorMode == "FIXED" then
    local color = secondaryFixedColor or profile.secondary.fixedColor
    ns.SafeSetTextColor(secondaryValue, color.r or 1, color.g or 1, color.b or 1, color.a == nil and 1 or color.a)
  else
    if secondaryResourceDefinition then
      ns.SafeSetTextColor(secondaryValue, GetPowerRGBForToken(secondaryResourceDefinition.powerToken))
    else
      ns.SafeSetTextColor(secondaryValue, 1, 1, 1, 1)
    end
  end

  ns.SafeSetTextColor(secondaryLabel, 1, 1, 1, 1)
end

function Addon:UpdateDisplay()
  local profile = ns.DB:GetActiveProfile()
  ApplyCurrentPlayerPowerStyle(profile)

  if profile.visibility.showPlayerHP then
    SetHealthPercentText(pHP, "player")
  else
    pHP:SetText("")
  end

  if profile.visibility.showPlayerPower then
    SetPowerText(pPow, "player")
  else
    pPow:SetText("")
  end

  if UnitExists("target") then
    if profile.visibility.showTargetHP then
      SetHealthPercentText(tHP, "target")
    else
      tHP:SetText("")
    end

    if profile.visibility.showTargetPower then
      SetPowerText(tPow, "target")
    else
      tPow:SetText("")
    end
  else
    tHP:SetText("")
    tPow:SetText("")
  end

  local showSecondary, secondaryResourceDefinition = ShouldShowSecondary(profile)
  secondaryLabel:SetText(profile.secondary.showLabel and ((secondaryResourceDefinition and secondaryResourceDefinition.label) or "Secondary") or "")
  secondaryFrame:SetShown(showSecondary == true)
  if showSecondary == true then
    SetSecondaryValueText(profile)
  else
    secondaryValue:SetText("")
  end

  self:UpdateColors()
end

function Addon:ApplySettings()
  local profile = ns.DB:GetActiveProfile()

  compiledState.playerHpCurve = ns.Curves.BuildColorCurve(profile.player.hpCurve)
  compiledState.playerPowerCurve = ns.Curves.BuildColorCurve(profile.player.powerCurve)
  compiledState.playerPowerOverrideCurves = {}
  for powerToken, override in pairs(profile.player.powerOverrides or {}) do
    if type(override) == "table" then
      compiledState.playerPowerOverrideCurves[powerToken] = ns.Curves.BuildColorCurve(override.colorCurve)
    end
  end
  compiledState.targetHpCurve = ns.Curves.BuildColorCurve(profile.target.hpCurve)
  compiledState.targetPowerCurve = ns.Curves.BuildColorCurve(profile.target.powerCurve)
  compiledState.secondaryColorCurve = ns.Curves.BuildColorCurve(profile.secondary.colorCurve)
  compiledState.secondaryColorOverrideCurves = {}
  for resourceMode, override in pairs(profile.secondary.colorOverrides or {}) do
    if type(override) == "table" then
      compiledState.secondaryColorOverrideCurves[resourceMode] = ns.Curves.BuildColorCurve(override.colorCurve)
    end
  end

  local secondaryResource = ResolveSecondaryResource(profile)
  if secondaryResource then
    compiledState.secondaryValueCurve = ns.Curves.GetDiscreteValueCurve(tonumber(profile.secondary.maxValue) or secondaryResource.defaultMax or 5)
  else
    compiledState.secondaryValueCurve = nil
  end

  parent:SetSize(profile.mainFrame.width or 520, profile.mainFrame.height or 160)
  ns.Anchors.Apply(parent, profile.mainFrame)
  parent.bg:SetColorTexture(0, 0, 0, profile.mainFrame.bgAlpha or 0)
  SetMovableState(parent, profile.mainFrame.locked == true, profile.mainFrame)

  secondaryFrame:SetSize(profile.secondary.width or 180, profile.secondary.height or 78)
  ns.Anchors.Apply(secondaryFrame, profile.secondary)
  secondaryFrame.bg:SetColorTexture(0, 0, 0, profile.secondary.bgAlpha or 0)
  SetMovableState(secondaryFrame, profile.secondary.locked == true, profile.secondary)

  ApplyTextStyle(pHP, profile.player.hpText)
  ApplyCurrentPlayerPowerStyle(profile)
  ApplyTextStyle(tHP, profile.target.hpText)
  ApplyTextStyle(tPow, profile.target.powerText)
  ApplyTextStyle(secondaryLabel, profile.secondary.labelStyle)
  ApplyTextStyle(secondaryValue, profile.secondary.valueStyle)

  pHP:SetJustifyH("RIGHT")
  pPow:SetJustifyH(profile.layout.playerPowerJustify == "LEFT" and "LEFT" or "RIGHT")
  tHP:SetJustifyH("LEFT")
  tPow:SetJustifyH(profile.layout.targetPowerJustify == "RIGHT" and "RIGHT" or "LEFT")
  secondaryLabel:SetJustifyH("CENTER")
  secondaryValue:SetJustifyH("CENTER")

  pHP:ClearAllPoints()
  pHP:SetPoint("TOPRIGHT", playerBlock, "TOPRIGHT", 0, 0)

  pPow:ClearAllPoints()
  pPow:SetPoint("TOPRIGHT", pHP, "BOTTOMRIGHT", 0, -((profile.layout.pLineGap or 10) - 6))

  tHP:ClearAllPoints()
  tHP:SetPoint("TOPLEFT", targetBlock, "TOPLEFT", 0, 0)

  tPow:ClearAllPoints()
  if profile.layout.targetPowerJustify == "RIGHT" then
    tPow:SetPoint("TOPRIGHT", tHP, "BOTTOMRIGHT", 0, -(profile.layout.tLineGap or 0))
  else
    tPow:SetPoint("TOPLEFT", tHP, "BOTTOMLEFT", 0, -(profile.layout.tLineGap or 0))
  end

  secondaryLabel:ClearAllPoints()
  if profile.secondary.showLabel then
    secondaryLabel:SetPoint("TOP", secondaryFrame, "TOP", 0, -8)
    secondaryValue:ClearAllPoints()
    secondaryValue:SetPoint("TOP", secondaryLabel, "BOTTOM", 0, -4)
  else
    secondaryValue:ClearAllPoints()
    secondaryValue:SetPoint("CENTER", secondaryFrame, "CENTER", 0, 0)
  end

  playerBlock:SetSize(240, 140)
  targetBlock:SetSize(240, 140)

  local gap = profile.layout.gap or 8
  local halfGap = math.floor(gap / 2)

  playerBlock:ClearAllPoints()
  playerBlock:SetPoint("TOPRIGHT", parent, "TOP", -halfGap, -18)

  targetBlock:ClearAllPoints()
  targetBlock:SetPoint(
    "TOPLEFT",
    playerBlock,
    "TOPRIGHT",
    gap + (profile.layout.targetOffsetX or 0),
    profile.layout.targetOffsetY or 0
  )

  self:UpdateDisplay()
end

function Addon:ResetPositions()
  local profile = ns.DB:GetActiveProfile()
  local defaults = ns.DB:NewDefaultProfile()
  profile.mainFrame = ns.DeepCopy(defaults.mainFrame)
  profile.secondary.point = defaults.secondary.point
  profile.secondary.relativeTo = defaults.secondary.relativeTo
  profile.secondary.customRelativeTo = defaults.secondary.customRelativeTo
  profile.secondary.relativePoint = defaults.secondary.relativePoint
  profile.secondary.x = defaults.secondary.x
  profile.secondary.y = defaults.secondary.y
  profile.secondary.width = defaults.secondary.width
  profile.secondary.height = defaults.secondary.height
  self:ApplySettings()
end

function Addon:OpenConfig(pageKey)
  local window = ns.ui and ns.ui.ConfigWindow
  if window and window.Open then
    window:Open(pageKey)
  end
end

parent:RegisterEvent("PLAYER_ENTERING_WORLD")
parent:RegisterEvent("PLAYER_TARGET_CHANGED")
parent:RegisterEvent("UNIT_HEALTH")
parent:RegisterEvent("UNIT_MAXHEALTH")
parent:RegisterEvent("UNIT_POWER_UPDATE")
parent:RegisterEvent("UNIT_POWER_FREQUENT")
parent:RegisterEvent("UNIT_MAXPOWER")
parent:RegisterEvent("UNIT_DISPLAYPOWER")
parent:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
parent:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
parent:RegisterEvent("UNIT_POWER_POINT_CHARGE")

parent:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_ENTERING_WORLD" then
    Addon:ApplySettings()
    return
  end

  if not unit or unit == "player" or unit == "target" then
    Addon:UpdateDisplay()
  end
end)

local elapsed = 0
parent:SetScript("OnUpdate", function(_, delta)
  elapsed = elapsed + delta
  if elapsed >= 0.25 then
    elapsed = 0
    Addon:UpdateDisplay()
  end
end)

SLASH_SIMPLEUNITTEXT1 = "/sut"
SlashCmdList.SIMPLEUNITTEXT = function(message)
  message = ns.TrimString((message or ""):lower())

  if message == "reset" then
    Addon:ResetPositions()
    print("SimpleUnitText: positions reset.")
    return
  end

  if message == "export" then
    Addon:OpenConfig("import_export")
    return
  end

  if message == "" or message == "config" or message == "options" or message == "import" then
    Addon:OpenConfig(message == "import" and "import_export" or nil)
    return
  end

  print("SimpleUnitText: /sut | /sut export | /sut reset")
end

function SimpleUnitText_ApplySettings()
  Addon:ApplySettings()
end

ns.RefreshAddon = function()
  Addon:ApplySettings()
end
