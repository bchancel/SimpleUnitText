local _, ns = ...

ns.Curves = ns.Curves or {}
local Curves = ns.Curves

Curves.typeEntries = {
  { key = "Linear", label = "Linear" },
  { key = "Step", label = "Step" },
  { key = "Cosine", label = "Cosine" },
  { key = "Cubic", label = "Cubic" },
}

Curves.discreteCache = Curves.discreteCache or {}

local function GetEnumCurveType(curveType)
  local enumTable = Enum and Enum.LuaCurveType or nil
  if not enumTable then
    return nil
  end
  return enumTable[curveType or "Linear"] or enumTable.Linear
end

function Curves.NormalizeDefinition(definition)
  local normalized = ns.DeepCopy(definition or {})
  normalized.curveType = normalized.curveType or "Linear"
  normalized.points = normalized.points or {}

  for index = #normalized.points, 1, -1 do
    local point = normalized.points[index]
    if type(point) ~= "table" then
      table.remove(normalized.points, index)
    else
      point.x = ns.Clamp(tonumber(point.x) or 0, 0, 1)
      point.color = ns.CopyColor(point.color)
    end
  end

  table.sort(normalized.points, function(left, right)
    return (left.x or 0) < (right.x or 0)
  end)

  if #normalized.points < 2 then
    normalized.points = {
      { x = 0.0, color = ns.MakeColor(1, 0, 0, 1) },
      { x = 1.0, color = ns.MakeColor(0, 1, 0, 1) },
    }
  end

  return normalized
end

function Curves.BuildColorCurve(definition)
  if not (C_CurveUtil and C_CurveUtil.CreateColorCurve) then
    return nil
  end

  local normalized = Curves.NormalizeDefinition(definition)
  local curve = C_CurveUtil.CreateColorCurve()
  local enumType = GetEnumCurveType(normalized.curveType)
  if enumType and curve.SetType then
    curve:SetType(enumType)
  end

  for _, point in ipairs(normalized.points) do
    curve:AddPoint(point.x, CreateColor(point.color.r, point.color.g, point.color.b, point.color.a))
  end

  return curve
end

function Curves.EvaluatePreview(definition, x)
  local curve = Curves.BuildColorCurve(definition)
  if not curve or not curve.Evaluate then
    return ns.MakeColor(1, 1, 1, 1)
  end

  local ok, color = pcall(curve.Evaluate, curve, ns.Clamp(x or 0, 0, 1))
  if not ok or not color then
    return ns.MakeColor(1, 1, 1, 1)
  end

  local r, g, b, a = color:GetRGBA()
  return ns.MakeColor(r, g, b, a)
end

function Curves.GetDiscreteValueCurve(maxValue)
  maxValue = math.max(1, math.floor(tonumber(maxValue) or 1))
  if Curves.discreteCache[maxValue] then
    return Curves.discreteCache[maxValue]
  end

  if not (C_CurveUtil and C_CurveUtil.CreateCurve) then
    return nil
  end

  local curve = C_CurveUtil.CreateCurve()
  if curve.SetType and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
    curve:SetType(Enum.LuaCurveType.Step)
  end

  curve:AddPoint(0.0, 0)
  for value = 1, maxValue do
    curve:AddPoint(value / maxValue, value)
  end

  Curves.discreteCache[maxValue] = curve
  return curve
end
