--[[
	This is a UI element that previews a hair style.
]]

local texture_scissors = getTexture("media/ui/Scissors.png")
local texture_razor    = getTexture("media/ui/Razor.png")
local texture_gel      = getTexture("media/ui/HairGel.png")

local base = ISUI3DModelExt
HairAvatar = base:derive("HairAvatar")

function HairAvatar:new(x, y, width, height, isBeard)
	local o = base.new(self, x, y, width, height)
	o.hairInfo = {id = "HAIR_UNINITIALIZED", display = "HAIR_UNINITIALIZED", selected = false}
	o.desc = nil
	o.char = nil
	o.isBeard = isBeard
	o.cursor = false
	return o
end

function HairAvatar:instantiate()
	base.instantiate(self)
	self:setState("idle")
	self:setDirection(IsoDirections.S)
	self:setIsometric(false)
	self:setZoom(18);
	self:setYOffset(-0.9);
	self:setXOffset(0);
end

function HairAvatar:render()
	base.render(self)
	if self.hairInfo.requirements then
		local x_pos = self:getWidth()-20
		local y_pos = 0
		local size = 20

		if self.hairInfo.requirements.scissors ~= nil then
			if self.hairInfo.requirements.scissors then
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end

		if self.hairInfo.requirements.razor ~= nil then
			-- HACK: Razor only appears for "Bald" which also has scissors so we always draw the razor below regardless.
			if self.hairInfo.requirements.razor then
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 0.5, 0.5);
			end
		end

		if self.hairInfo.requirements.hairgel ~= nil then
			if self.hairInfo.requirements.hairgel then
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end
	end
	if self.hairInfo.selected == true then self:drawRectBorder(0, 0, self.width, self.height, 0.5,0,1,0) end
	if self.cursor == true then
		if self.hairInfo.selected == true then
			self:drawRectBorder(1, 1, self.width-2, self.height-2, 0.5,1,1,1)
		else
			self:drawRectBorder(0, 0, self.width, self.height, 0.5,1,1,1)
		end
	end
end

function HairAvatar:setDesc(desc)
	self.desc = desc
	self.char = nil
end

function HairAvatar:setChar(char)
	self.char = char
	self.desc = nil
end

function HairAvatar:setHairInfo(args)
	self.hairInfo = args
end

function HairAvatar:applyHair()
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

	local getter = nil
	local setter = nil

	if self.isBeard then
		getter = visual.getBeardModel
		setter = visual.setBeardModel
	else
		getter = visual.getHairModel
		setter = visual.setHairModel
	end

	local original_hair = getter(visual)

	if self.hairInfo and self.hairInfo.id then
		setter(visual, self.hairInfo.id)
	end
	
	-- NOTE: This appears to copy the data likely because ISUI3DModel has a java call that copies the table into an object
	if self.desc then 
		self:setSurvivorDesc(self.desc)
	elseif self.char then
		self:setCharacter(self.char)
	end

	setter(visual, original_hair)
end

function HairAvatar:select()
	-- NOTE: Don't allow selection of hairs missing a requirement.
	-- XXX: This is only used by the in-game menu, maybe the in-game should override this function instead?
	if self.hairInfo.requirements then
		if self.hairInfo.requirements.scissors == false then return end
		if self.hairInfo.requirements.scissors == false and self.hairInfo.requirements.razor == false then return end -- HACK: Razor only appears along side scissors in an OR relationship
		if self.hairInfo.requirements.hairgel == false then return end
	end

	base.select(self)
end

function HairAvatar:setCursor(state)
	self.cursor = state
	if state == true then
		self:showTooltip()
	else
		self:hideTooltip()
	end
end

function HairAvatar:showTooltip()
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
	self.tooltipUI.description = self.hairInfo.display
	self.tooltipUI:setDesiredPosition(self:getAbsoluteX() + self:getWidth(), self:getAbsoluteY())
end

function HairAvatar:hideTooltip()
	if self.tooltipUI and self.tooltipUI:getIsVisible() then
		self.tooltipUI:setVisible(false)
		self.tooltipUI:removeFromUIManager()
	end
end