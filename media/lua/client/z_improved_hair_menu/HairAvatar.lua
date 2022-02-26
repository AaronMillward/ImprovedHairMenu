--[[
	This is a UI element that previews a hair style.

	It extends ISUI3DModel with click detection and can show a given hair style id
]]

local texture_scissors = getTexture("media/ui/Scissors.png")
local texture_razor    = getTexture("media/ui/Razor.png")
local texture_gel      = getTexture("media/ui/HairGel.png")

local base = ISUI3DModelExt

HairAvatar = base:derive("HairAvatar")

function HairAvatar:new(x, y, width, height, isBeard)
	local o = base.new(self, x, y, width, height)
	o.hairInfo = {id = "HAIR_UNINITIALIZED", display = "HAIR_UNINITIALIZED"}
	o.modelData = nil
	o.isBeard = isBeard
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
		if self.hairInfo.requirements == "scissors" then
			self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
		elseif self.hairInfo.requirements == "scissorsrazor" then
			self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			self:drawTextureScaled(texture_razor, x_pos,y_pos+20, size,size, 1, 1, 0.5, 0.5);
		elseif self.hairInfo.requirements == "hairgel" then
			self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
		end
	end
end

function HairAvatar:setModelData(data)
	self.modelData = data
end

function HairAvatar:setHairInfo(args)
	self.hairInfo = args
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

		There's no need to revert externally anymore because this function reverts the desc to it's original state itself.

		In an ideal scenario we copy the description to avoid editing the one we are passed but I've got no idea how to do that from Lua.
	]]

	local visual = nil

	if self.modelData then
		visual = self.modelData:getHumanVisual()
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

	--When a hair id isn't passed this usually means it's a "bald" style
	if self.hairInfo.id ~= "" and self.hairInfo.id ~= nil then
		setter(visual, self.hairInfo.id)
	else
		setter(visual, "")
	end
	
	--This appears to copy the desc likely because ISUI3DModel has a java call that probably copies the table by into an object
	local name = self.modelData:getClass():getName()
	if name == "zombie.characters.SurvivorDesc" then
		self:setSurvivorDesc(self.modelData)
	elseif name == "zombie.characters.IsoPlayer" then
		self:setCharacter(self.modelData)
	end

	setter(visual, original_hair)
end