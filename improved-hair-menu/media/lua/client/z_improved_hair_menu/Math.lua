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

function ImprovedHairMenu.math.sign(x)
	return x>0 and 1 or x<0 and -1 or 0
end

function ImprovedHairMenu.math.clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end