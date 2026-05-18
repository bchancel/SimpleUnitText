local _, ns = ...

ns.Anchors = ns.Anchors or {}
local Anchors = ns.Anchors

local pointEntries = {
  { key = "CENTER", label = "Center" },
  { key = "TOP", label = "Top" },
  { key = "BOTTOM", label = "Bottom" },
  { key = "LEFT", label = "Left" },
  { key = "RIGHT", label = "Right" },
  { key = "TOPLEFT", label = "Top Left" },
  { key = "TOPRIGHT", label = "Top Right" },
  { key = "BOTTOMLEFT", label = "Bottom Left" },
  { key = "BOTTOMRIGHT", label = "Bottom Right" },
}

local targets = {
  { key = "UIParent", label = "Screen" },
  { key = "SimpleUnitTextFrame", label = "Main HUD" },
  { key = "SimpleUnitTextSecondaryFrame", label = "Secondary Window" },
  { key = "SimpleUnitTextConfigWindow", label = "Config Window" },
  { key = "PlayerFrame", label = "Player Frame" },
  { key = "TargetFrame", label = "Target Frame" },
  { key = "FocusFrame", label = "Focus Frame" },
  { key = "PetFrame", label = "Pet Frame" },
  { key = "CUSTOM", label = "Custom Global Name" },
}

function Anchors.GetPointList()
  return pointEntries
end

function Anchors.GetTargetList()
  return targets
end

function Anchors.GetTargetLabel(key)
  for _, entry in ipairs(targets) do
    if entry.key == key then
      return entry.label
    end
  end
  return key or "Screen"
end

function Anchors.Resolve(targetKey, customTarget)
  if targetKey == nil or targetKey == "" or targetKey == "UIParent" then
    return UIParent
  end

  if targetKey == "CUSTOM" then
    local resolved = customTarget and _G[customTarget] or nil
    return resolved or UIParent
  end

  return _G[targetKey] or UIParent
end

function Anchors.Apply(frame, anchor)
  if not frame or type(anchor) ~= "table" then
    return
  end

  local point = anchor.point or "CENTER"
  local relativePoint = anchor.relativePoint or point
  local relativeToKey = anchor.relativeTo or "UIParent"
  local relativeTo = Anchors.Resolve(relativeToKey, anchor.customRelativeTo)

  if relativeTo == frame then
    relativeTo = UIParent
    relativeToKey = "UIParent"
  end

  frame:ClearAllPoints()
  frame:SetPoint(point, relativeTo, relativePoint, tonumber(anchor.x) or 0, tonumber(anchor.y) or 0)
end

function Anchors.SaveToScreenCenter(frame, anchor)
  if not frame or type(anchor) ~= "table" then
    return
  end

  local centerX, centerY = frame:GetCenter()
  local uiCenterX, uiCenterY = UIParent:GetCenter()
  if not centerX or not centerY or not uiCenterX or not uiCenterY then
    return
  end

  anchor.point = "CENTER"
  anchor.relativeTo = "UIParent"
  anchor.customRelativeTo = ""
  anchor.relativePoint = "CENTER"
  anchor.x = math.floor((centerX - uiCenterX) + 0.5)
  anchor.y = math.floor((centerY - uiCenterY) + 0.5)
end
