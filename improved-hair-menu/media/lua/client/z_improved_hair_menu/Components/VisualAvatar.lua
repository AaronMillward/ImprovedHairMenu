--[[
	This is a UI element that previews a HumanVisual change.
]]

require("z_improved_hair_menu/Components/ExtendedUI3DModel")

VisualAvatar = ISUI3DModelExt:derive("VisualAvatar")

function VisualAvatar:new(x, y, width, height)
	local o = ISUI3DModelExt.new(self, x, y, width, height)
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
	self.char = nil
end

function VisualAvatar:setChar(char)
	self.char = char
	self.desc = nil
end

function VisualAvatar:setVisualItem(args)
	self.visualItem = args
end

function VisualAvatar:applyVisual()
	--[[ XXX:
		The getter and setter functions will affect the visual for all other avatars. this is due
		to the visual being a table which is passed by reference in lua. this means we have to revert
		any changes made while we're in here.

		This still works because when passing the visual to the 3D element the java side makes a copy
		instead of referencing the table.
	 ]]

	--[[ XXX:
		It has to be done like this with 2 separate variables for the char/desc. we can't seem to pass
		the char/desc as a parameter because comparing the java types doesn't work everywhere.
		Possibly something to do with java environment?
	 ]]

	local visual = nil

	if self.desc then
		visual = self.desc:getHumanVisual()
	elseif self.char then
		visual = self.char:getHumanVisual()
	else
		return
	end

	local getter = visual[self.visualItem.getterName]
	local setter = visual[self.visualItem.setterName]

	-- NOTE: Unitialized items won't have getters or setters.
	if not (getter and setter) then
		return
	end

	local original_item = getter(visual)

	if self.visualItem and self.visualItem.id then
		setter(visual, self.visualItem.id)
	end
	
	-- NOTE: This appears to copy the data likely because ISUI3DModel has a java call that copies the table into an object
	if self.desc then 
		self:setSurvivorDesc(self.desc)
	elseif self.char then
		self:setCharacter(self.char)
	end

	setter(visual, original_item)
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