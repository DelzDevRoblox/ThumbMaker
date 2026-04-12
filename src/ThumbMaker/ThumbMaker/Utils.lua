--!strict

local Utils = {}

function Utils:MapToInterval(value: number, oldMin: number, oldMax: number, newMin: number, newMax: number)
  local oldRange = oldMax - oldMin
  local newRange = newMax - newMin
  local translatedValue = (((value - oldMin) * newRange) / oldRange) + newMin
  return translatedValue
end

return Utils
