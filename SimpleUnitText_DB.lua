local _, ns = ...

ns.DB = ns.DB or {}
local DB = ns.DB

local DEFAULT_PROFILE_NAME = "Default"

ns.DEFAULT_PROFILE_NAME = DEFAULT_PROFILE_NAME
ns.PROFILE_SCOPE_GLOBAL = "global"
ns.PROFILE_SCOPE_CHARACTER = "character"

local function NewTextStyle(size, fontFile, flags, shadowEnabled)
  return {
    fontFile = fontFile or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    size = size or 12,
    flags = flags or "OUTLINE",
    shadow = {
      enabled = shadowEnabled == true,
      color = ns.MakeColor(0, 0, 0, 1),
      offsetX = 1,
      offsetY = -1,
    },
  }
end

local function NewCurveDefinition(points, curveType)
  return {
    curveType = curveType or "Linear",
    points = ns.DeepCopy(points or {}),
  }
end

local defaultHealthCurvePoints = {
  { x = 0.00, color = ns.MakeColor(0.92, 0.14, 0.14, 1) },
  { x = 0.35, color = ns.MakeColor(0.95, 0.80, 0.18, 1) },
  { x = 0.70, color = ns.MakeColor(0.20, 0.92, 0.36, 1) },
  { x = 1.00, color = ns.MakeColor(0.12, 1.00, 0.18, 1) },
}

local defaultManaCurvePoints = {
  { x = 0.00, color = ns.MakeColor(0.12, 0.34, 0.85, 1) },
  { x = 0.40, color = ns.MakeColor(0.10, 0.62, 1.00, 1) },
  { x = 0.80, color = ns.MakeColor(0.42, 0.86, 1.00, 1) },
  { x = 1.00, color = ns.MakeColor(0.86, 0.96, 1.00, 1) },
}

function DB:NewPlayerPowerOverrideConfig()
  return {
    enabled = false,
    textStyle = NewTextStyle(34, "Fonts\\FRIZQT__.TTF", "OUTLINE", false),
    colorMode = "POWER",
    fixedColor = ns.MakeColor(0.12, 0.62, 1.00, 1),
    colorCurve = NewCurveDefinition(defaultManaCurvePoints, "Linear"),
  }
end

function DB:NewSecondaryColorOverrideConfig()
  return {
    enabled = false,
    colorMode = "POWER",
    fixedColor = ns.MakeColor(1, 1, 1, 1),
    colorCurve = NewCurveDefinition(defaultHealthCurvePoints, "Linear"),
  }
end

function DB:NewDefaultProfile()
  return {
    visibility = {
      showPlayerHP = true,
      showPlayerPower = true,
      showTargetHP = true,
      showTargetPower = true,
      showSecondary = false,
    },
    layout = {
      gap = 8,
      pLineGap = 10,
      tLineGap = 0,
      targetOffsetX = 0,
      targetOffsetY = 0,
      playerPowerJustify = "RIGHT",
      targetPowerJustify = "LEFT",
    },
    mainFrame = {
      point = "CENTER",
      relativeTo = "UIParent",
      customRelativeTo = "",
      relativePoint = "CENTER",
      x = 0,
      y = -200,
      width = 520,
      height = 160,
      locked = false,
      bgAlpha = 0.0,
    },
    secondary = {
      enabled = false,
      point = "TOP",
      relativeTo = "SimpleUnitTextFrame",
      customRelativeTo = "",
      relativePoint = "BOTTOM",
      x = 0,
      y = -16,
      width = 180,
      height = 78,
      locked = false,
      bgAlpha = 0.0,
      resourceMode = "AUTO",
      maxValue = 5,
      hideWhenInactive = false,
      showLabel = true,
      colorMode = "POWER",
      fixedColor = ns.MakeColor(1, 1, 1, 1),
      colorCurve = NewCurveDefinition(defaultHealthCurvePoints, "Linear"),
      colorOverrides = {},
      labelStyle = NewTextStyle(12, nil, "OUTLINE", true),
      valueStyle = NewTextStyle(28, nil, "OUTLINE", true),
    },
    player = {
      hpText = NewTextStyle(44, "Fonts\\FRIZQT__.TTF", "OUTLINE", false),
      powerText = NewTextStyle(34, "Fonts\\FRIZQT__.TTF", "OUTLINE", false),
      hpColorMode = "CLASS",
      hpFixedColor = ns.MakeColor(1, 1, 1, 1),
      hpCurve = NewCurveDefinition(defaultHealthCurvePoints, "Linear"),
      powerColorMode = "POWER",
      powerFixedColor = ns.MakeColor(0.12, 0.62, 1.00, 1),
      powerCurve = NewCurveDefinition(defaultManaCurvePoints, "Linear"),
      powerOverrides = {},
    },
    target = {
      hpText = NewTextStyle(22, "Fonts\\FRIZQT__.TTF", "OUTLINE", false),
      powerText = NewTextStyle(16, "Fonts\\FRIZQT__.TTF", "OUTLINE", false),
      hpColorMode = "REACTION",
      hpFixedColor = ns.MakeColor(1, 0, 0, 1),
      hpCurve = NewCurveDefinition(defaultHealthCurvePoints, "Linear"),
      powerColorMode = "POWER",
      powerFixedColor = ns.MakeColor(0.12, 0.62, 1.00, 1),
      powerCurve = NewCurveDefinition(defaultManaCurvePoints, "Linear"),
    },
  }
end

function DB:NewGlobalRoot()
  return {
    version = 2,
    globalProfiles = {
      [DEFAULT_PROFILE_NAME] = self:NewDefaultProfile(),
    },
    exports = {},
  }
end

function DB:NewCharacterRoot()
  return {
    version = 2,
    scope = ns.PROFILE_SCOPE_GLOBAL,
    globalProfile = DEFAULT_PROFILE_NAME,
    charProfile = DEFAULT_PROFILE_NAME,
    charProfiles = {
      [DEFAULT_PROFILE_NAME] = self:NewDefaultProfile(),
    },
    ui = {
      configWindow = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        width = 980,
        height = 680,
      },
      selectedPage = "general",
      importTargetScope = ns.PROFILE_SCOPE_CHARACTER,
      importProfileName = "Imported",
    },
  }
end

local function ApplyStyleMigration(size, fontFile)
  return NewTextStyle(size, fontFile or "Fonts\\FRIZQT__.TTF", "OUTLINE", false)
end

local function MigratePowerSection(section)
  if type(section) ~= "table" then
    return
  end

  if section.powerColorMode == nil then
    section.powerColorMode = section.manaColorMode or "POWER"
  end
  if type(section.powerFixedColor) ~= "table" then
    section.powerFixedColor = ns.CopyColor(section.manaFixedColor or ns.MakeColor(0.12, 0.62, 1.00, 1))
  end
  if type(section.powerCurve) ~= "table" then
    section.powerCurve = ns.DeepCopy(section.manaCurve or NewCurveDefinition(defaultManaCurvePoints, "Linear"))
  end

  section.manaColorMode = nil
  section.manaFixedColor = nil
  section.manaCurve = nil
end

local function NormalizePlayerPowerOverrides(profile)
  if type(profile) ~= "table" or type(profile.player) ~= "table" then
    return
  end

  profile.player.powerOverrides = profile.player.powerOverrides or {}
  for token, override in pairs(profile.player.powerOverrides) do
    if type(token) ~= "string" then
      profile.player.powerOverrides[token] = nil
    elseif type(override) ~= "table" then
      profile.player.powerOverrides[token] = DB:NewPlayerPowerOverrideConfig()
    else
      ns.MergeDefaults(override, DB:NewPlayerPowerOverrideConfig())
    end
  end
end

local function NormalizeSecondaryColorOverrides(profile)
  if type(profile) ~= "table" or type(profile.secondary) ~= "table" then
    return
  end

  profile.secondary.colorOverrides = profile.secondary.colorOverrides or {}
  for token, override in pairs(profile.secondary.colorOverrides) do
    if type(token) ~= "string" then
      profile.secondary.colorOverrides[token] = nil
    elseif type(override) ~= "table" then
      profile.secondary.colorOverrides[token] = DB:NewSecondaryColorOverrideConfig()
    else
      ns.MergeDefaults(override, DB:NewSecondaryColorOverrideConfig())
    end
  end
end

function DB:ImportLegacyProfile(legacyProfile)
  local profile = self:NewDefaultProfile()
  local legacy = type(legacyProfile) == "table" and legacyProfile or {}

  profile.visibility.showPlayerHP = legacy.showPlayerHP ~= false
  profile.visibility.showPlayerPower = legacy.showPlayerPower ~= false
  profile.visibility.showTargetHP = legacy.showTargetHP ~= false
  profile.visibility.showTargetPower = legacy.showTargetPower ~= false
  profile.visibility.showSecondary = false

  profile.layout.gap = tonumber(legacy.gap) or profile.layout.gap
  profile.layout.pLineGap = tonumber(legacy.pLineGap) or profile.layout.pLineGap
  profile.layout.tLineGap = tonumber(legacy.tLineGap) or profile.layout.tLineGap
  profile.layout.targetOffsetX = tonumber(legacy.targetOffsetX) or profile.layout.targetOffsetX
  profile.layout.targetOffsetY = tonumber(legacy.targetOffsetY) or profile.layout.targetOffsetY
  profile.layout.playerPowerJustify = legacy.playerPowerJustify == "LEFT" and "LEFT" or "RIGHT"
  profile.layout.targetPowerJustify = legacy.targetPowerJustify == "RIGHT" and "RIGHT" or "LEFT"

  profile.mainFrame.x = tonumber(legacy.frameX) or profile.mainFrame.x
  profile.mainFrame.y = tonumber(legacy.frameY) or profile.mainFrame.y
  profile.mainFrame.locked = legacy.lockFrame == true
  profile.mainFrame.bgAlpha = tonumber(legacy.bgAlpha) or profile.mainFrame.bgAlpha

  profile.player.hpText = ApplyStyleMigration(tonumber(legacy.fontPHp) or profile.player.hpText.size, legacy.fontPathPHp)
  profile.player.powerText = ApplyStyleMigration(tonumber(legacy.fontPPow) or profile.player.powerText.size, legacy.fontPathPPow)
  profile.target.hpText = ApplyStyleMigration(tonumber(legacy.fontTHp) or profile.target.hpText.size, legacy.fontPathTHp)
  profile.target.powerText = ApplyStyleMigration(tonumber(legacy.fontTPow) or profile.target.powerText.size, legacy.fontPathTPow)

  if legacy.useClassColor == false then
    profile.player.hpColorMode = "FIXED"
  else
    profile.player.hpColorMode = "CLASS"
  end

  profile.player.hpFixedColor = ns.CopyColor(legacy.playerHpColor)
  return profile
end

local function LooksLikeLegacyRoot(root)
  if type(root) ~= "table" then
    return false
  end
  if root.version == 2 and type(root.globalProfiles) == "table" then
    return false
  end
  return root.frameX ~= nil
    or root.frameY ~= nil
    or root.lockFrame ~= nil
    or root.fontPHp ~= nil
    or type(root.profiles) == "table"
end

local function NormalizeProfileName(name)
  name = ns.TrimString(name)
  if name == "" then
    return nil
  end
  return name
end

function DB:Initialize()
  SimpleUnitTextDB = SimpleUnitTextDB or {}
  SimpleUnitTextCharDB = SimpleUnitTextCharDB or {}

  if LooksLikeLegacyRoot(SimpleUnitTextDB) then
    local legacyRoot = SimpleUnitTextDB
    local migrated = self:NewGlobalRoot()

    if type(legacyRoot.profiles) == "table" then
      migrated.globalProfiles = {}
      for profileName, legacyProfile in pairs(legacyRoot.profiles) do
        local normalizedName = NormalizeProfileName(profileName) or DEFAULT_PROFILE_NAME
        migrated.globalProfiles[normalizedName] = self:ImportLegacyProfile(legacyProfile)
      end
      if next(migrated.globalProfiles) == nil then
        migrated.globalProfiles[DEFAULT_PROFILE_NAME] = self:NewDefaultProfile()
      end
    else
      migrated.globalProfiles[DEFAULT_PROFILE_NAME] = self:ImportLegacyProfile(legacyRoot)
    end

    SimpleUnitTextDB = migrated

    local migratedCharacterRoot = self:NewCharacterRoot()
    local activeProfile = NormalizeProfileName(legacyRoot.activeProfile) or DEFAULT_PROFILE_NAME
    if migrated.globalProfiles[activeProfile] then
      migratedCharacterRoot.globalProfile = activeProfile
    end
    SimpleUnitTextCharDB = migratedCharacterRoot
  end

  if type(SimpleUnitTextDB.globalProfiles) ~= "table" then
    SimpleUnitTextDB = self:NewGlobalRoot()
  end

  if type(SimpleUnitTextCharDB.charProfiles) ~= "table" then
    SimpleUnitTextCharDB = self:NewCharacterRoot()
  end

  ns.MergeDefaults(SimpleUnitTextDB, self:NewGlobalRoot())
  ns.MergeDefaults(SimpleUnitTextCharDB, self:NewCharacterRoot())

  for _, profileName in ipairs(ns.SortedKeys(SimpleUnitTextDB.globalProfiles)) do
    ns.MergeDefaults(SimpleUnitTextDB.globalProfiles[profileName], self:NewDefaultProfile())
    MigratePowerSection(SimpleUnitTextDB.globalProfiles[profileName].player)
    MigratePowerSection(SimpleUnitTextDB.globalProfiles[profileName].target)
    NormalizePlayerPowerOverrides(SimpleUnitTextDB.globalProfiles[profileName])
    NormalizeSecondaryColorOverrides(SimpleUnitTextDB.globalProfiles[profileName])
  end

  for _, profileName in ipairs(ns.SortedKeys(SimpleUnitTextCharDB.charProfiles)) do
    ns.MergeDefaults(SimpleUnitTextCharDB.charProfiles[profileName], self:NewDefaultProfile())
    MigratePowerSection(SimpleUnitTextCharDB.charProfiles[profileName].player)
    MigratePowerSection(SimpleUnitTextCharDB.charProfiles[profileName].target)
    NormalizePlayerPowerOverrides(SimpleUnitTextCharDB.charProfiles[profileName])
    NormalizeSecondaryColorOverrides(SimpleUnitTextCharDB.charProfiles[profileName])
  end

  local globalProfileName = SimpleUnitTextCharDB.globalProfile
  if type(SimpleUnitTextDB.globalProfiles[globalProfileName]) ~= "table" then
    SimpleUnitTextCharDB.globalProfile = DEFAULT_PROFILE_NAME
  end

  local charProfileName = SimpleUnitTextCharDB.charProfile
  if type(SimpleUnitTextCharDB.charProfiles[charProfileName]) ~= "table" then
    SimpleUnitTextCharDB.charProfile = DEFAULT_PROFILE_NAME
  end

  if SimpleUnitTextCharDB.scope ~= ns.PROFILE_SCOPE_CHARACTER then
    SimpleUnitTextCharDB.scope = ns.PROFILE_SCOPE_GLOBAL
  end
end

function DB:EnsureInitialized()
  local defaultCharacterRoot = nil
  local needsGlobal = type(SimpleUnitTextDB) ~= "table" or type(SimpleUnitTextDB.globalProfiles) ~= "table"
  local needsCharacter = type(SimpleUnitTextCharDB) ~= "table" or type(SimpleUnitTextCharDB.charProfiles) ~= "table"

  if needsGlobal or needsCharacter then
    self:Initialize()
  end

  if type(SimpleUnitTextDB.globalProfiles) ~= "table" then
    SimpleUnitTextDB.globalProfiles = self:NewGlobalRoot().globalProfiles
  end

  if type(SimpleUnitTextCharDB.charProfiles) ~= "table" then
    defaultCharacterRoot = defaultCharacterRoot or self:NewCharacterRoot()
    SimpleUnitTextCharDB.charProfiles = defaultCharacterRoot.charProfiles
  end

  if type(SimpleUnitTextCharDB.ui) ~= "table" then
    defaultCharacterRoot = defaultCharacterRoot or self:NewCharacterRoot()
    SimpleUnitTextCharDB.ui = defaultCharacterRoot.ui
  end

  if type(SimpleUnitTextCharDB.ui.configWindow) ~= "table" then
    defaultCharacterRoot = defaultCharacterRoot or self:NewCharacterRoot()
    SimpleUnitTextCharDB.ui.configWindow = defaultCharacterRoot.ui.configWindow
  end

  if type(SimpleUnitTextCharDB.ui.selectedPage) ~= "string" then
    SimpleUnitTextCharDB.ui.selectedPage = "general"
  end

  if type(SimpleUnitTextCharDB.ui.importTargetScope) ~= "string" then
    SimpleUnitTextCharDB.ui.importTargetScope = ns.PROFILE_SCOPE_CHARACTER
  end

  if type(SimpleUnitTextCharDB.ui.importProfileName) ~= "string" then
    SimpleUnitTextCharDB.ui.importProfileName = "Imported"
  end

  if type(SimpleUnitTextCharDB.globalProfile) ~= "string" then
    SimpleUnitTextCharDB.globalProfile = DEFAULT_PROFILE_NAME
  end

  if type(SimpleUnitTextCharDB.charProfile) ~= "string" then
    SimpleUnitTextCharDB.charProfile = DEFAULT_PROFILE_NAME
  end
end

function DB:GetGlobalRoot()
  self:EnsureInitialized()
  return SimpleUnitTextDB
end

function DB:GetCharacterRoot()
  self:EnsureInitialized()
  return SimpleUnitTextCharDB
end

function DB:GetConfigWindowState()
  return self:GetCharacterRoot().ui.configWindow
end

function DB:GetProfileContainer(scope)
  self:EnsureInitialized()
  if scope == ns.PROFILE_SCOPE_CHARACTER then
    local charRoot = self:GetCharacterRoot()
    charRoot.charProfiles = charRoot.charProfiles or self:NewCharacterRoot().charProfiles
    return charRoot.charProfiles
  end
  local globalRoot = self:GetGlobalRoot()
  globalRoot.globalProfiles = globalRoot.globalProfiles or self:NewGlobalRoot().globalProfiles
  return globalRoot.globalProfiles
end

function DB:GetActiveScope()
  return self:GetCharacterRoot().scope or ns.PROFILE_SCOPE_GLOBAL
end

function DB:SetActiveScope(scope)
  local charRoot = self:GetCharacterRoot()
  charRoot.scope = scope == ns.PROFILE_SCOPE_CHARACTER and ns.PROFILE_SCOPE_CHARACTER or ns.PROFILE_SCOPE_GLOBAL
end

function DB:GetActiveProfileName(scope)
  local charRoot = self:GetCharacterRoot()
  scope = scope or self:GetActiveScope()
  if scope == ns.PROFILE_SCOPE_CHARACTER then
    return charRoot.charProfile
  end
  return charRoot.globalProfile
end

function DB:SetActiveProfile(scope, profileName)
  profileName = NormalizeProfileName(profileName)
  if not profileName then
    return false
  end

  scope = scope or self:GetActiveScope()
  if type(self:GetProfileContainer(scope)[profileName]) ~= "table" then
    return false
  end

  local charRoot = self:GetCharacterRoot()
  if scope == ns.PROFILE_SCOPE_CHARACTER then
    charRoot.charProfile = profileName
  else
    charRoot.globalProfile = profileName
  end
  return true
end

function DB:GetProfile(scope, profileName)
  scope = scope or self:GetActiveScope()
  profileName = profileName or self:GetActiveProfileName(scope)
  local container = self:GetProfileContainer(scope)
  if type(container[profileName]) ~= "table" then
    container[profileName] = self:NewDefaultProfile()
  end
  ns.MergeDefaults(container[profileName], self:NewDefaultProfile())
  return container[profileName]
end

function DB:GetActiveProfile()
  return self:GetProfile(self:GetActiveScope(), self:GetActiveProfileName())
end

function DB:GetProfileNames(scope)
  return ns.SortedKeys(self:GetProfileContainer(scope or self:GetActiveScope()))
end

function DB:CreateProfile(scope, profileName, sourceProfile)
  scope = scope or self:GetActiveScope()
  profileName = NormalizeProfileName(profileName)
  if not profileName then
    return nil, "Profile name is required."
  end

  local container = self:GetProfileContainer(scope)
  if container[profileName] then
    return nil, "A profile with that name already exists."
  end

  if type(sourceProfile) == "table" then
    container[profileName] = ns.DeepCopy(sourceProfile)
  else
    container[profileName] = self:NewDefaultProfile()
  end

  ns.MergeDefaults(container[profileName], self:NewDefaultProfile())
  return container[profileName]
end

function DB:SetProfile(scope, profileName, profile)
  scope = scope or self:GetActiveScope()
  profileName = NormalizeProfileName(profileName)
  if not profileName then
    return nil, "Profile name is required."
  end

  local container = self:GetProfileContainer(scope)
  container[profileName] = ns.DeepCopy(profile or self:NewDefaultProfile())
  ns.MergeDefaults(container[profileName], self:NewDefaultProfile())
  return container[profileName]
end

function DB:DeleteProfile(scope, profileName)
  scope = scope or self:GetActiveScope()
  profileName = NormalizeProfileName(profileName)
  if not profileName then
    return false, "Profile name is required."
  end
  if profileName == DEFAULT_PROFILE_NAME then
    return false, "The default profile cannot be deleted."
  end

  local container = self:GetProfileContainer(scope)
  if not container[profileName] then
    return false, "That profile does not exist."
  end

  container[profileName] = nil
  if self:GetActiveProfileName(scope) == profileName then
    self:SetActiveProfile(scope, DEFAULT_PROFILE_NAME)
  end
  return true
end

function DB:ResetProfile(scope, profileName)
  scope = scope or self:GetActiveScope()
  profileName = profileName or self:GetActiveProfileName(scope)
  return self:SetProfile(scope, profileName, self:NewDefaultProfile())
end

function DB:GetProfileCopy(scope, profileName)
  return ns.DeepCopy(self:GetProfile(scope, profileName))
end

DB:Initialize()
