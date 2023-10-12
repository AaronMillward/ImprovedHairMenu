--[[
	This is a UI element that previews a HumanVisual change.
]]

local ISUI3DModelExt = require("z_improved_hair_menu/Components/ExtendedUI3DModel.lua")

local VisualAvatar = ISUI3DModelExt:derive("VisualAvatar")

function VisualAvatar:new(x, y, width, height)
	local o = ISUI3DModelExt.new(self, x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.visualItem = {id = "UNINITIALIZED", display = "UNINITIALIZED", selected = false}
	o.desc = nil
	o.char = nil
	o.cursor = false
	return o
end

function VisualAvatar:instantiate()
	ISUI3DModelExt.instantiate(self)
	self:setState("idle")
	self:setDirection(IsoDirections.S)
	self:setIsometric(false)
end

function VisualAvatar:render()
	ISUI3DModelExt.render(self)
	if self.visualItem.selected == true then self:drawRectBorder(0, 0, self.width, self.height, 0.5,0,1,0) end
	if self.cursor == true then
		if self.visualItem.selected == true then
			self:drawRectBorder(1, 1, self.width-2, self.height-2, 0.5,1,1,1)
		else
			self:drawRectBorder(0, 0, self.width, self.height, 0.5,1,1,1)
		end
	end
end

function VisualAvatar:setDesc(desc)
	self.desc = desc
end

function VisualAvatar:setChar(char)
	self.desc = char:getDescriptor()
end

function VisualAvatar:setVisualItem(args)
	self.visualItem = args
end

function VisualAvatar:applyVisual()
	--[[ XXX:
		The desc is shared between the whole UI so this means we have to revert any changes made while we're in here.

		This still works because when passing the visual to the 3D element the java side makes a copy
		instead of referencing the table.
	 ]]

	if not self.desc then return end

	if not self.visualItem.applyToDesc then
		if not self.visualItem.getterName then return end
		if not self.visualItem.setterName then return end
		
		self.visualItem.applyToDesc = function (visualItem, desc)
			local visual = desc:getHumanVisual()
			visualItem.original = visual[visualItem.getterName](visual)
			visual[visualItem.setterName](visual, visualItem.id)
		end
	end

	if not self.visualItem.restoreDesc then
		if not self.visualItem.setterName then return end
		self.visualItem.restoreDesc = function (visualItem, desc)
			local visual = desc:getHumanVisual()
			visual[visualItem.setterName](visual, visualItem.original)
		end
	end

	self.visualItem:applyToDesc(self.desc)

	-- NOTE: This appears to copy the data likely because ISUI3DModel has a java call that copies the table into an object
	self:setSurvivorDesc(self.desc)

	self.visualItem:restoreDesc(self.desc)
end

function VisualAvatar:setCursor(state)
	self.cursor = state
	if state == true then
		self:showTooltip()
	else
		self:hideTooltip()
	end
end

function VisualAvatar:showTooltip()
	if not self.tooltipUI then
		self.tooltipUI = ISToolTip:new()
		self.tooltipUI:setOwner(self)
		self.tooltipUI:setVisible(false)
		self.tooltipUI:setAlwaysOnTop(true)
		self.tooltipUI.maxLineWidth = 300
	end
	if not self.tooltipUI:getIsVisible() then
		self.tooltipUI:addToUIManager()
		self.tooltipUI:setVisible(true)
	end
	self.tooltipUI.description = self.visualItem.display
	self.tooltipUI:setDesiredPosition(self:getAbsoluteX() + self:getWidth(), self:getAbsoluteY())
end

function VisualAvatar:hideTooltip()
	if self.tooltipUI and self.tooltipUI:getIsVisible() then
		self.tooltipUI:setVisible(false)
		self.tooltipUI:removeFromUIManager()
	end
end

return VisualAvatar