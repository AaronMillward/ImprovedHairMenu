--[[
	This is a UI element that extends ISUI3DModel with click detection
]]

require("z_improved_hair_menu/ModCompatibility/ReorganizedInfoScreen.lua")
require("ISUI/ISUI3DModel")
local base = ISUI3DModel
ISUI3DModelExt = base:derive("ISUI3DModelExt")

function ISUI3DModelExt:new(x, y, width, height)
	local o = base.new(self, x, y, width, height)
	o.hasDragged = false
	o.onSelect = nil
	o.selectable = true
	return o
end

local texture_avatar_background = getTexture("media/ui/avatarBackground.png")
function ISUI3DModelExt:prerender()
	base.prerender(self)
	self:drawTextureScaled(texture_avatar_background, 0, 0, self.width, self.height, 1, 1, 1, 1)
end

function ISUI3DModelExt:onMouseMove(dx, dy)
	-- NOTE: This is mostly repeated but it preserves the vanilla code
	if self.mouseDown then
		if math.abs(self.dragX + dx) > 40 then
			self.hasDragged = true
		end
	end
	base.onMouseMove(self, dx, dy)
end

function ISUI3DModelExt:onMouseUp(x, y)
	if self.mouseDown then
		if self.hasDragged == false then
			self:select()
		end
	end
	self.hasDragged = false
	base.onMouseUp(self, x, y)
end

function ISUI3DModelExt:onMouseUpOutside(x, y)
	if self.mouseDown then
		if self.hasDragged == false then
			self:select()
		end
	end
	self.hasDragged = false
	base.onMouseUpOutside(self, x, y)
end

function ISUI3DModelExt:select()
	if self.selectable and self.onSelect then
		self.onSelect(self)
	end
end