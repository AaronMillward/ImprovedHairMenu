--[[
	This is a UI element that previews a hair style.

	It extends ISUI3DModel with click detection and can show a given hair style id
]]

require("ISUI/ISUI3DModel")
local base = ISUI3DModel

HairAvatar = base:derive("HairAvatar")

function HairAvatar:new(x, y, width, height, isBeard)
	local o = base.new(self, x, y, width, height)
	o.has_dragged = false
	o.hair_id = "HAIR_UNINITIALIZED"
	o.hair_display = "HAIR_UNINITIALIZED"
	o.desc = nil
	o.char = nil
	o.onSelect = nil
	o.avatarBackgroundTexture = getTexture("media/ui/avatarBackground.png")
	o.isBeard = isBeard
	-- o.tickTexture = getTexture("Quest_Succeed")
	-- o.crossTexture = getTexture("Quest_Failed");
	-- o.drawIcon = nil
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

function HairAvatar:prerender()
	base.prerender(self)
	self:drawTextureScaled(self.avatarBackgroundTexture, 0, 0, self.width, self.height, 1, 1, 1, 1)
end

-- function HairAvatar:render()
-- 	base.render(self)
-- 	if self.drawIcon then
-- 		if self.drawIcon == "tick" then
-- 			self:drawTexture(self.tickTexture, self:getRight(), 0, 1, 1, 1, 1);
-- 		elseif self.drawIcon == "cross" then
-- 			self:drawTexture(self.crossTexture, self:getRight(), 0, 1, 1, 1, 1);
-- 		end
-- 	end
-- end

function HairAvatar:onMouseMove(dx, dy)
	-- This is mostly repeated but it preserves the vanilla code
	if self.mouseDown then
		if math.abs(self.dragX + dx) > 40 then
			self.has_dragged = true
		end
	end
	base.onMouseMove(self, dx, dy)
end

function HairAvatar:onMouseUp(x, y)
	if self.mouseDown then
		if self.has_dragged == false then
			self:onSelect()
		end
	end
	self.has_dragged = false
	base.onMouseUp(self, x, y)
end

function HairAvatar:onMouseUpOutside(x, y)
	if self.mouseDown then
		if self.has_dragged == false then
			self:onSelect()
		end
	end
	self.has_dragged = false
	base.onMouseUpOutside(self, x, y)
end

function HairAvatar:onSelect() 
	self.onSelect(self)
end

function HairAvatar:setDesc(desc)
	self.desc = desc
	self.char = nil
end

function HairAvatar:setChar(char)
	self.char = char
	self.desc = nil
end

function HairAvatar:setHair(id, display)
	self.hair_id = id
	self.hair_display = display
end

function HairAvatar:applyHair()
	--[[
		~~
		Either I don't understand how survivordesc works or this is a bug.

		Lua passes tables by reference so I expect calling setHairModel() should set the hair for all hairavatars using this description
		but it doesn't... the hair menu avatars clearly all have different hair styles.

		This isn't ideal but it works. the caller just has to store the original hair to revert the changes made to the desc here.
		~~

		This is wrong, all descriptions are changed by setHairModel() however,
		it appears the 3D ui element makes a copy of the description instead of referencing it.

		There's no need to revert anymore because this function reverts the desc to it's original state itself.

		In and ideal scenario we copy the description to avoid editing the one we are passed but I've got no idea how to do that from Lua.
	]]

	local visual = nil

	if self.desc then
		visual = self.desc:getHumanVisual()
	elseif self.char then
		visual = self.char:getHumanVisual()
	else
		return
	end

	local original_getter = nil
	local original_setter = nil

	if self.isBeard then
		original_getter = visual.getBeardModel
		original_setter = visual.setBeardModel
	else
		original_getter = visual.getHairModel
		original_setter = visual.setHairModel
	end

	local original_hair = original_getter(visual)

	--When a hair_id isn't passed this usually means it's a "bald" style
	if self.hair_id ~= "" and self.hair_id ~= nil then
		original_setter(visual, self.hair_id)
	else
		original_setter(visual, "")
	end
	
	--This appears to copy the desc likely because ISUI3DModel has a java call that probably copies the table by into an object
	if self.desc then 
		self:setSurvivorDesc(self.desc)
	elseif self.char then
		self:setCharacter(self.char)
	end

	original_setter(visual, original_hair)
end