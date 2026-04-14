--!strict

local Utils = {}

function Utils:MapToInterval(value: number, oldMin: number, oldMax: number, newMin: number, newMax: number)
  local oldRange = oldMax - oldMin
  local newRange = newMax - newMin
  local translatedValue = (((value - oldMin) * newRange) / oldRange) + newMin
  return translatedValue
end

function Utils:GetCamera(): Camera
  local camera = workspace.CurrentCamera
  if camera then
    return camera
  end
  error("No camera found")
end

function Utils:GetFromPath(parent: Instance, ...: string): Instance
  local current = parent

  for i = 1, select("#", ...) do
    local name = select(i, ...)
    local child = current:FindFirstChild(name)

    if not child then
      error(`Missing child "{name}" in {current:GetFullName()}`)
    end

    current = child
  end

  return current
end

return Utils
