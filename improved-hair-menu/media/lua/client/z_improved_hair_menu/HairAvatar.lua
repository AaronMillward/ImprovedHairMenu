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

	--[[ 2022-02-26
		It has to be done like this with 2 separate variables for the char/desc, compairing the java types of 1 object doesn't work everywhere

		I've just thought of the reason for this, using `:getClass():getName()` is probably very dependent on java environment
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

	if self.hairInfo and self.hairInfo.id then
		original_setter(visual, self.hairInfo.id)
	end
	
	--This appears to copy the desc likely because ISUI3DModel has a java call that probably copies the table by into an object
	if self.desc then 
		self:setSurvivorDesc(self.desc)
	elseif self.char then
		self:setCharacter(self.char)
	end

	original_setter(visual, original_hair)
end

function HairAvatar:select()
	-- NOTE: Don't allow selection of hairs missing a requirement.
	if self.hairInfo.requirements then
		if self.hairInfo.requirements.scissors == false then return end
		if self.hairInfo.requirements.scissors == false and self.hairInfo.requirements.razor == false then return end -- HACK: Razor only appears along side scissors in an OR relationship
		if self.hairInfo.requirements.hairgel == false then return end
	end

	base.select(self)
end