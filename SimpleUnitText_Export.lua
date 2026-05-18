local _, ns = ...

ns.Export = ns.Export or {}
local Export = ns.Export

Export.PREFIX = "SUT1:"

local base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function IsFiniteNumber(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function SerializeNumber(value)
  if not IsFiniteNumber(value) then
    return "0"
  end

  local serialized = string.format("%.17g", value)
  if serialized:find(",", 1, true) then
    serialized = serialized:gsub(",", ".")
  end
  return serialized
end

local function BuildSortKey(value)
  local valueType = type(value)
  if valueType == "number" then
    return "1:" .. SerializeNumber(value)
  elseif valueType == "string" then
    return "2:" .. value
  elseif valueType == "boolean" then
    return "3:" .. tostring(value)
  end
  return "9:" .. tostring(value)
end

local function SerializeValue(value, seen)
  local valueType = type(value)
  if valueType == "nil" then
    return "nil"
  elseif valueType == "number" then
    return SerializeNumber(value)
  elseif valueType == "boolean" then
    return tostring(value)
  elseif valueType == "string" then
    return string.format("%q", value)
  elseif valueType == "table" then
    seen = seen or {}
    if seen[value] then
      return "{}"
    end
    seen[value] = true

    local fragments = { "{" }
    local entries = {}
    for key, nestedValue in pairs(value) do
      if type(key) == "number" or type(key) == "string" or type(key) == "boolean" then
        entries[#entries + 1] = {
          key = key,
          value = nestedValue,
          sortKey = BuildSortKey(key),
        }
      end
    end

    table.sort(entries, function(left, right)
      return left.sortKey < right.sortKey
    end)

    for _, entry in ipairs(entries) do
      fragments[#fragments + 1] = "[" .. SerializeValue(entry.key, seen) .. "]=" .. SerializeValue(entry.value, seen) .. ","
    end

    fragments[#fragments + 1] = "}"
    seen[value] = nil
    return table.concat(fragments)
  end

  return "nil"
end

local function ValuesEqual(left, right)
  if left == right then
    return true
  end

  if type(left) ~= type(right) then
    return false
  end

  if type(left) ~= "table" then
    return false
  end

  for key, value in pairs(left) do
    if not ValuesEqual(value, right[key]) then
      return false
    end
  end
  for key, value in pairs(right) do
    if left[key] == nil and value ~= nil then
      return false
    end
  end
  return true
end

local function PruneAgainstDefaults(value, defaults)
  if type(value) ~= "table" then
    if defaults ~= nil and ValuesEqual(value, defaults) then
      return nil
    end
    return value
  end

  local result = {}
  for key, nestedValue in pairs(value) do
    local defaultValue = type(defaults) == "table" and defaults[key] or nil
    local prunedValue = PruneAgainstDefaults(nestedValue, defaultValue)
    if prunedValue ~= nil then
      result[key] = prunedValue
    end
  end

  if next(result) == nil and type(defaults) == "table" then
    return nil
  end
  return result
end

local function Base64Encode(text)
  local bytes = { string.byte(text or "", 1, #text) }
  local fragments = {}
  local index = 1

  while index <= #bytes do
    local a = bytes[index] or 0
    local b = bytes[index + 1] or 0
    local c = bytes[index + 2] or 0
    local value = (a * 65536) + (b * 256) + c

    local first = math.floor(value / 262144) % 64 + 1
    local second = math.floor(value / 4096) % 64 + 1
    local third = math.floor(value / 64) % 64 + 1
    local fourth = (value % 64) + 1

    fragments[#fragments + 1] = base64Alphabet:sub(first, first)
    fragments[#fragments + 1] = base64Alphabet:sub(second, second)
    fragments[#fragments + 1] = (index + 1 <= #bytes) and base64Alphabet:sub(third, third) or "="
    fragments[#fragments + 1] = (index + 2 <= #bytes) and base64Alphabet:sub(fourth, fourth) or "="

    index = index + 3
  end

  return table.concat(fragments)
end

local function Base64Decode(text)
  text = tostring(text or ""):gsub("%s+", "")
  local bytes = {}
  local index = 1

  while index <= #text do
    local c1 = text:sub(index, index)
    local c2 = text:sub(index + 1, index + 1)
    local c3 = text:sub(index + 2, index + 2)
    local c4 = text:sub(index + 3, index + 3)

    local v1 = c1 == "=" and 0 or (base64Alphabet:find(c1, 1, true) or 1) - 1
    local v2 = c2 == "=" and 0 or (base64Alphabet:find(c2, 1, true) or 1) - 1
    local v3 = c3 == "=" and 0 or (base64Alphabet:find(c3, 1, true) or 1) - 1
    local v4 = c4 == "=" and 0 or (base64Alphabet:find(c4, 1, true) or 1) - 1

    local value = (v1 * 262144) + (v2 * 4096) + (v3 * 64) + v4
    local a = math.floor(value / 65536) % 256
    local b = math.floor(value / 256) % 256
    local c = value % 256

    bytes[#bytes + 1] = string.char(a)
    if c3 ~= "=" then
      bytes[#bytes + 1] = string.char(b)
    end
    if c4 ~= "=" then
      bytes[#bytes + 1] = string.char(c)
    end

    index = index + 4
  end

  return table.concat(bytes)
end

function Export:BuildPayload(scope, profileName)
  local profileCopy = ns.DB:GetProfileCopy(scope, profileName)
  local defaults = ns.DB:NewDefaultProfile()
  local compactProfile = PruneAgainstDefaults(profileCopy, defaults) or {}

  return {
    version = 1,
    exportedAt = time(),
    sourceScope = scope,
    sourceProfileName = profileName,
    profile = compactProfile,
  }
end

function Export:EncodeProfile(scope, profileName)
  scope = scope or ns.DB:GetActiveScope()
  profileName = profileName or ns.DB:GetActiveProfileName(scope)
  local payload = self:BuildPayload(scope, profileName)
  local serialized = "return " .. SerializeValue(payload)
  return self.PREFIX .. Base64Encode(serialized), payload
end

function Export:Decode(text)
  text = ns.TrimString(text)
  if text == "" then
    return nil, "Paste an export string first."
  end
  if text:sub(1, #self.PREFIX) ~= self.PREFIX then
    return nil, "That does not look like a SimpleUnitText export."
  end

  local decoded = Base64Decode(text:sub(#self.PREFIX + 1))
  if decoded == "" then
    return nil, "Failed to decode export data."
  end

  local loader = loadstring or load
  local chunk, err = loader(decoded)
  if not chunk then
    return nil, err or "Invalid export payload."
  end

  local ok, payload = pcall(chunk)
  if not ok or type(payload) ~= "table" then
    return nil, "Export payload did not evaluate to a table."
  end

  if payload.version ~= 1 or type(payload.profile) ~= "table" then
    return nil, "Unsupported export payload."
  end

  return payload
end

function Export:Import(text, targetScope, targetProfileName, replaceCurrent)
  local payload, err = self:Decode(text)
  if not payload then
    return nil, err
  end

  local profile = ns.DB:NewDefaultProfile()
  ns.MergeDefaults(payload.profile, profile)
  profile = payload.profile

  targetScope = targetScope or ns.DB:GetActiveScope()
  if replaceCurrent == true then
    targetProfileName = ns.DB:GetActiveProfileName(targetScope)
  else
    targetProfileName = ns.TrimString(targetProfileName)
    if targetProfileName == "" then
      targetProfileName = payload.sourceProfileName or "Imported"
    end
  end

  ns.DB:SetProfile(targetScope, targetProfileName, profile)
  ns.DB:SetActiveScope(targetScope)
  ns.DB:SetActiveProfile(targetScope, targetProfileName)

  return {
    scope = targetScope,
    profileName = targetProfileName,
    sourceScope = payload.sourceScope,
    sourceProfileName = payload.sourceProfileName,
  }
end
