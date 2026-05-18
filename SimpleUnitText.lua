-- SimpleUnitText.lua (runtime, WoW 12.0+ / Midnight-safe)
-- Text-only HUD for player + target HP and power.
-- Secret-safe: health and mana shown as percent via UnitHealthPercent/UnitPowerPercent using CurveConstants.ScaleTo100.

SimpleUnitTextDB = SimpleUnitTextDB or {}
SimpleUnitText = SimpleUnitText or {}

local DEFAULT_PROFILE_NAME = "Default"

local DEFAULTS = {
  -- Visibility
  showPlayerHP = true,
  showPlayerPower = true,
  showTargetHP = true,
  showTargetPower = true,

  -- Colors
  useClassColor = true,
  playerHpColor = { r = 1, g = 1, b = 1 }, -- used when useClassColor = false

  -- Background
  bgAlpha = 0.0, -- 0..1

  -- Layout
  gap = 8,            -- spacing between player and target blocks (px)
  pLineGap = 10,      -- player HP -> power gap
  tLineGap = 0,       -- target HP -> power gap
  targetOffsetX = 0,  -- additional target X offset
  targetOffsetY = 0,  -- additional target Y offset

  -- Alignment
  playerPowerJustify = "RIGHT", -- LEFT/RIGHT
  targetPowerJustify = "LEFT",  -- LEFT/RIGHT

  -- Position (whole HUD)
  frameX = 0,
  frameY = -200,

  -- Fonts
  fontPHp = 44,
  fontPPow = 34,
  fontTHp = 22,
  fontTPow = 16,
  fontPathPHp = "Fonts\\FRIZQT__.TTF",
  fontPathPPow = "Fonts\\FRIZQT__.TTF",
  fontPathTHp = "Fonts\\FRIZQT__.TTF",
  fontPathTPow = "Fonts\\FRIZQT__.TTF",

  -- Interaction
  lockFrame = false,
}

local function CopyTable(src)
  local dst = {}
  for k, v in pairs(src) do
    if type(v) == "table" then
      local sub = {}
      for kk, vv in pairs(v) do sub[kk] = vv end
      dst[k] = sub
    else
      dst[k] = v
    end
  end
  return dst
end

local function EnsureProfiles()
  -- Migrate old flat DB into profiles if needed.
  if type(SimpleUnitTextDB.profiles) ~= "table" then
    local migrated = {}
    for k, v in pairs(SimpleUnitTextDB) do
      -- ignore internal
      if k ~= "profiles" and k ~= "activeProfile" then
        migrated[k] = v
      end
    end
    SimpleUnitTextDB.profiles = {}
    SimpleUnitTextDB.profiles[DEFAULT_PROFILE_NAME] = CopyTable(DEFAULTS)
    -- overlay migrated values
    for k, v in pairs(migrated) do
      SimpleUnitTextDB.profiles[DEFAULT_PROFILE_NAME][k] = v
    end
    SimpleUnitTextDB.activeProfile = DEFAULT_PROFILE_NAME
    -- keep only profiles-related keys at top-level
    for k, _ in pairs(migrated) do
      SimpleUnitTextDB[k] = nil
    end
  end
  if type(SimpleUnitTextDB.activeProfile) ~= "string" then
    SimpleUnitTextDB.activeProfile = DEFAULT_PROFILE_NAME
  end
  if type(SimpleUnitTextDB.profiles[SimpleUnitTextDB.activeProfile]) ~= "table" then
    SimpleUnitTextDB.profiles[SimpleUnitTextDB.activeProfile] = CopyTable(DEFAULTS)
  end
end

local function DB()
  EnsureProfiles()
  return SimpleUnitTextDB.profiles[SimpleUnitTextDB.activeProfile]
end

local function ApplyDefaults(db)
  for k, v in pairs(DEFAULTS) do
    if db[k] == nil then
      if type(v) == "table" then
        db[k] = CopyTable(v)
      else
        db[k] = v
      end
    end
  end
end

-- ========================
-- Parent frame
-- ========================
local parent = CreateFrame("Frame", "SimpleUnitTextFrame", UIParent)
SimpleUnitText.frame = parent

parent:SetSize(520, 160)
parent:ClearAllPoints()
parent:SetPoint("CENTER", UIParent, "CENTER", 0, -200)

parent.bg = parent:CreateTexture(nil, "BACKGROUND")
parent.bg:SetAllPoints(true)
parent.bg:SetColorTexture(0, 0, 0, 0)

-- ========================
-- Dragging + lock
-- ========================
local function SaveParentPosition()
  local cx, cy = parent:GetCenter()
  local ux, uy = UIParent:GetCenter()
  if cx and cy and ux and uy then
    local db = DB()
    db.frameX = math.floor((cx - ux) + 0.5)
    db.frameY = math.floor((cy - uy) + 0.5)
  end
end

local function EnableDragging()
  parent:SetMovable(true)
  parent:EnableMouse(true)
  parent:SetMouseClickEnabled(true)
  parent:RegisterForDrag("LeftButton")
  parent:SetScript("OnDragStart", parent.StartMoving)
  parent:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveParentPosition()
  end)
end

local function DisableDragging()
  parent:SetMovable(false)
  parent:RegisterForDrag()
  parent:SetScript("OnDragStart", nil)
  parent:SetScript("OnDragStop", nil)
  parent:EnableMouse(false)
end

local function ApplyLockState(db)
  if db.lockFrame then
    DisableDragging()
  else
    parent:EnableMouse(true)
    EnableDragging()
  end
end

-- ========================
-- Child frames: player + target blocks
-- ========================
local playerBlock = CreateFrame("Frame", nil, parent)
local targetBlock = CreateFrame("Frame", nil, parent)
playerBlock:EnableMouse(false)
targetBlock:EnableMouse(false)

local flags = "OUTLINE"

local pHP = playerBlock:CreateFontString(nil, "OVERLAY")
local pPow = playerBlock:CreateFontString(nil, "OVERLAY")
local tHP = targetBlock:CreateFontString(nil, "OVERLAY")
local tPow = targetBlock:CreateFontString(nil, "OVERLAY")

-- ========================
-- Secret-safe percent helpers
-- ========================
local function GetScaleTo100()
  return CurveConstants and CurveConstants.ScaleTo100 or nil
end

local function SafeToString(v, fallback)
  fallback = fallback or "??"
  local ok, s = pcall(tostring, v)
  if ok and type(s) == "string" then
    return s
  end
  return fallback
end

local function TruncDecimalString(s)
  local ok, whole = pcall(string.match, s, "^%-?%d+")
  if ok and whole then
    return whole
  end
  return s
end

local function FormatWhole(v)
  local ok, out = pcall(string.format, "%.0f", v)
  if ok and type(out) == "string" then
    return out
  end
  return TruncDecimalString(SafeToString(v, "??"))
end

local function HPPercent(unit)
  if not UnitHealthPercent then return "??" end
  local curve = GetScaleTo100()
  if curve then
    return FormatWhole(UnitHealthPercent(unit, false, curve))
  end
  return FormatWhole(UnitHealthPercent(unit, false))
end

local function PowerPercent(unit)
  if not UnitPowerPercent then return "??" end
  local curve = GetScaleTo100()
  if curve then
    local ok, v = pcall(UnitPowerPercent, unit, nil, false, curve)
    if ok then return FormatWhole(v) end
    return "??"
  end
  local ok, v = pcall(UnitPowerPercent, unit)
  if ok then return FormatWhole(v) end
  return "??"
end

-- Mana = percent; other power types = literal value
local function PowerDisplay(unit)
  if not UnitExists(unit) then return "" end

  local ok, _, powerToken = pcall(UnitPowerType, unit)
  powerToken = ok and powerToken or nil

  if powerToken == "MANA" then
    return PowerPercent(unit)
  end

  if UnitPower then
    local ok2, v = pcall(UnitPower, unit)
    if ok2 and v ~= nil then
      return FormatWhole(v)
    end
  end

  return "??"
end

-- ========================
-- Colors
-- ========================
local function SetFSColor(fs, r, g, b)
  fs:SetTextColor(r or 1, g or 1, b or 1)
end

local function GetClassRGB(unit)
  local _, class = UnitClass(unit)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

local function GetPowerRGBForUnit(unit)
  local ok, _, powerToken, altR, altG, altB = pcall(UnitPowerType, unit)
  if ok then
    if powerToken and PowerBarColor and PowerBarColor[powerToken] then
      local c = PowerBarColor[powerToken]
      return c.r, c.g, c.b
    end
    if altR and altG and altB then
      return altR, altG, altB
    end
  end

  if PowerBarColor and PowerBarColor["MANA"] then
    local c = PowerBarColor["MANA"]
    return c.r, c.g, c.b
  end
  return 0, 0.55, 1
end

local function GetTargetHPColor()
  if UnitIsPlayer("target") then
    return GetClassRGB("target")
  end

  local reaction = UnitReaction("target", "player")
  if reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
    local rc = FACTION_BAR_COLORS[reaction]
    return rc.r, rc.g, rc.b
  end

  return 1, 0, 0
end

function SimpleUnitText:UpdateColors()
  local db = DB()
  ApplyDefaults(db)

  if db.useClassColor then
    SetFSColor(pHP, GetClassRGB("player"))
  else
    local c = db.playerHpColor or DEFAULTS.playerHpColor
    SetFSColor(pHP, c.r or 1, c.g or 1, c.b or 1)
  end

  SetFSColor(pPow, GetPowerRGBForUnit("player"))

  if UnitExists("target") then
    SetFSColor(tHP, GetTargetHPColor())
    SetFSColor(tPow, GetPowerRGBForUnit("target"))
  else
    SetFSColor(tHP, 1, 0, 0)
    SetFSColor(tPow, 0.7, 0.7, 0.7)
  end
end

function SimpleUnitText:UpdateDisplay()
  local db = DB()
  ApplyDefaults(db)

  -- Player
  if db.showPlayerHP then
    pHP:SetText(HPPercent("player"))
  else
    pHP:SetText("")
  end

  if db.showPlayerPower then
    pPow:SetText(PowerDisplay("player"))
  else
    pPow:SetText("")
  end

  -- Target
  if UnitExists("target") then
    if db.showTargetHP then
      tHP:SetText(HPPercent("target"))
    else
      tHP:SetText("")
    end

    if db.showTargetPower then
      tPow:SetText(PowerDisplay("target"))
    else
      tPow:SetText("")
    end
  else
    tHP:SetText("")
    tPow:SetText("")
  end

  self:UpdateColors()
end

-- ========================
-- Apply settings (layout + visuals)
-- ========================
function SimpleUnitText:ApplySettings()
  local db = DB()
  ApplyDefaults(db)

  ApplyLockState(db)

  parent:ClearAllPoints()
  parent:SetPoint("CENTER", UIParent, "CENTER", db.frameX, db.frameY)

  parent.bg:SetColorTexture(0, 0, 0, db.bgAlpha or 0)

  -- Fonts
  pHP:SetFont(db.fontPathPHp or DEFAULTS.fontPathPHp, db.fontPHp or DEFAULTS.fontPHp, flags)
  pPow:SetFont(db.fontPathPPow or DEFAULTS.fontPathPPow, db.fontPPow or DEFAULTS.fontPPow, flags)
  tHP:SetFont(db.fontPathTHp or DEFAULTS.fontPathTHp, db.fontTHp or DEFAULTS.fontTHp, flags)
  tPow:SetFont(db.fontPathTPow or DEFAULTS.fontPathTPow, db.fontTPow or DEFAULTS.fontTPow, flags)

  -- Justification
  pHP:SetJustifyH("RIGHT")
  pPow:SetJustifyH(db.playerPowerJustify == "LEFT" and "LEFT" or "RIGHT")
  tHP:SetJustifyH("LEFT")
  tPow:SetJustifyH(db.targetPowerJustify == "RIGHT" and "RIGHT" or "LEFT")

  -- Layout
  pHP:ClearAllPoints()
  pHP:SetPoint("TOPRIGHT", playerBlock, "TOPRIGHT", 0, 0)

  pPow:ClearAllPoints()
  pPow:SetPoint("TOPRIGHT", pHP, "BOTTOMRIGHT", 0, -((db.pLineGap or DEFAULTS.pLineGap) - 6))

  tHP:ClearAllPoints()
  tHP:SetPoint("TOPLEFT", targetBlock, "TOPLEFT", 0, 0)

  tPow:ClearAllPoints()
  -- keep power anchored under HP. Use LEFT or RIGHT depending on desired growth direction.
  if (db.targetPowerJustify == "RIGHT") then
    tPow:SetPoint("TOPRIGHT", tHP, "BOTTOMRIGHT", 0, -(db.tLineGap or DEFAULTS.tLineGap))
  else
    tPow:SetPoint("TOPLEFT", tHP, "BOTTOMLEFT", 0, -(db.tLineGap or DEFAULTS.tLineGap))
  end

  -- Sizes (generous)
  playerBlock:SetSize(240, 140)
  targetBlock:SetSize(240, 140)

  local gap = db.gap or DEFAULTS.gap
  local tx = db.targetOffsetX or 0
  local ty = db.targetOffsetY or 0
  local halfGap = math.floor(gap / 2)

  playerBlock:ClearAllPoints()
  playerBlock:SetPoint("TOPRIGHT", parent, "TOP", -halfGap, -18)

  targetBlock:ClearAllPoints()
  targetBlock:SetPoint("TOPLEFT", playerBlock, "TOPRIGHT", gap + tx, ty)

  self:UpdateDisplay()
end

-- helper for Options file
function SimpleUnitText_ApplySettings()
  if SimpleUnitText and SimpleUnitText.ApplySettings then
    SimpleUnitText:ApplySettings()
  end
end

-- ========================
-- Events
-- ========================
parent:RegisterEvent("PLAYER_ENTERING_WORLD")
parent:RegisterEvent("PLAYER_TARGET_CHANGED")
parent:RegisterEvent("UNIT_HEALTH")
parent:RegisterEvent("UNIT_MAXHEALTH")
parent:RegisterEvent("UNIT_POWER_UPDATE")
parent:RegisterEvent("UNIT_POWER_FREQUENT")
parent:RegisterEvent("UNIT_MAXPOWER")
parent:RegisterEvent("UNIT_DISPLAYPOWER")
parent:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

parent:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_ENTERING_WORLD" then
    SimpleUnitText:ApplySettings()
    return
  end
  if not unit or unit == "player" or unit == "target" then
    SimpleUnitText:UpdateDisplay()
  end
end)

-- Light refresh fallback
local acc = 0
parent:SetScript("OnUpdate", function(_, dt)
  acc = acc + dt
  if acc >= 0.25 then
    acc = 0
    SimpleUnitText:UpdateDisplay()
  end
end)

-- ========================
-- Slash commands
-- ========================
SLASH_SIMPLEUNITTEXT1 = "/sut"
SlashCmdList.SIMPLEUNITTEXT = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")

  if msg == "reset" then
    local db = DB()
    db.frameX = 0
    db.frameY = -200
    SimpleUnitText:ApplySettings()
    print("SimpleUnitText: position reset.")
    return
  end

  -- Open config by default
  if msg == "" or msg == "config" or msg == "options" then
    local cat = _G.SimpleUnitText_SettingsCategory
    local catID = _G.SimpleUnitText_SettingsCategoryID

    -- Preferred: category object
    if Settings and Settings.OpenToCategory and cat then
      local ok = pcall(Settings.OpenToCategory, cat)
      if ok then return end
    end

    -- Fallback: numeric category ID
    if (catID == nil) and cat and type(cat.GetID) == "function" then
      local ok2, id = pcall(cat.GetID, cat)
      if ok2 and type(id) == "number" then
        catID = id
        _G.SimpleUnitText_SettingsCategoryID = id
      end
    end

    if C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel and type(catID) == "number" then
      pcall(C_SettingsUtil.OpenSettingsPanel, catID)
      return
    end

    -- Final fallback: open Settings root
    if Settings and Settings.OpenToCategory and Settings.GetTopLevelCategory then
      pcall(Settings.OpenToCategory, Settings.GetTopLevelCategory())
    end
    return
  end

  print("SimpleUnitText: /sut (opens config) | /sut reset")
end
