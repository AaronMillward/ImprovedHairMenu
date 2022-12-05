ImprovedHairMenu = ImprovedHairMenu or {}
ImprovedHairMenu.math = ImprovedHairMenu.math or {}

function ImprovedHairMenu.math.wrap(value, min, max)
	if value < min then
		return max
	elseif value > max then
		return min
	else
		return value
	end
end