local addonName, ns = ...

_G.SimpleUnitText = _G.SimpleUnitText or ns
ns = _G.SimpleUnitText

ns.name = addonName or "SimpleUnitText"
ns.ui = ns.ui or {}

local function DeepCopy(value, seen)
  if type(value) ~= "table" then
    return value
  end

  seen = seen or {}
  if seen[value] then
    return seen[value]
  end

  local copy = {}
  seen[value] = copy
  for key, nestedValue in pairs(value) do
    copy[DeepCopy(key, seen)] = DeepCopy(nestedValue, seen)
  end
  return copy
end

local function MergeDefaults(target, defaults)
  if type(target) ~= "table" or type(defaults) ~= "table" then
    return target
  end

  for key, defaultValue in pairs(defaults) do
    if target[key] == nil then
      target[key] = DeepCopy(defaultValue)
    elseif type(target[key]) == "table" and type(defaultValue) == "table" then
      MergeDefaults(target[key], defaultValue)
    end
  end

  return target
end

local function Clamp(value, minValue, maxValue)
  value = tonumber(value)
  if not value then
    return minValue
  end
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

local function TrimString(value)
  if type(value) ~= "string" then
    return ""
  end
  return (value:match("^%s*(.-)%s*$") or ""):gsub("[\r\n\t]", "")
end

local function SortedKeys(tbl)
  local keys = {}
  for key in pairs(tbl or {}) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(left, right)
    return tostring(left) < tostring(right)
  end)
  return keys
end

local function MakeColor(r, g, b, a)
  return {
    r = Clamp(r or 1, 0, 1),
    g = Clamp(g or 1, 0, 1),
    b = Clamp(b or 1, 0, 1),
    a = Clamp(a == nil and 1 or a, 0, 1),
  }
end

local function CopyColor(color)
  if type(color) ~= "table" then
    return MakeColor(1, 1, 1, 1)
  end
  return MakeColor(color.r, color.g, color.b, color.a)
end

local function SafeSetFormattedText(fontString, formatText, value)
  if not fontString then
    return false
  end

  if value == nil or value == "" then
    fontString:SetText("")
    return true
  end

  local ok = pcall(fontString.SetFormattedText, fontString, formatText or "%s", value)
  if ok then
    return true
  end

  ok = pcall(fontString.SetFormattedText, fontString, "%s", value)
  if ok then
    return true
  end

  fontString:SetText("??")
  return false
end

local function SafeSetTextColor(fontString, ...)
  if not fontString then
    return false
  end

  local ok = pcall(fontString.SetTextColor, fontString, ...)
  if ok then
    return true
  end

  fontString:SetTextColor(1, 1, 1, 1)
  return false
end

ns.DeepCopy = DeepCopy
ns.MergeDefaults = MergeDefaults
ns.Clamp = Clamp
ns.TrimString = TrimString
ns.SortedKeys = SortedKeys
ns.MakeColor = MakeColor
ns.CopyColor = CopyColor
ns.SafeSetFormattedText = SafeSetFormattedText
ns.SafeSetTextColor = SafeSetTextColor
