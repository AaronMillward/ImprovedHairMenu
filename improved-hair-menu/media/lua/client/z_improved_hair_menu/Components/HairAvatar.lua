require("z_improved_hair_menu/Components/VisualAvatar")

HairAvatar = VisualAvatar:derive("HairAvatar")

function HairAvatar:select()
	-- NOTE: Don't allow selection of hairs missing a requirement.
	-- XXX: This is only used by the in-game menu, maybe the in-game should override this function instead?
	if self.visualItem.requirements then
		if self.visualItem.requirements.scissors == false then return end
		if self.visualItem.requirements.scissors == false and self.visualItem.requirements.razor == false then return end -- HACK: Razor only appears along side scissors in an OR relationship
		if self.visualItem.requirements.hairgel == false then return end
	end

	VisualAvatar.select(self)
end

local texture_scissors = getTexture("media/ui/Scissors.png")
local texture_razor    = getTexture("media/ui/Razor.png")
local texture_gel      = getTexture("media/ui/HairGel.png")

function HairAvatar:render()
	VisualAvatar.render(self)
	if self.visualItem.requirements then
		local x_pos = self:getWidth()-20
		local y_pos = 0
		local size = 20
	
		if self.visualItem.requirements.scissors ~= nil then
			if self.visualItem.requirements.scissors then
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end
	
		if self.visualItem.requirements.razor ~= nil then
			-- HACK: Razor only appears for "Bald" which also has scissors so we always draw the razor below regardless.
			if self.visualItem.requirements.razor then
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 0.5, 0.5);
			end
		end
	
		if self.visualItem.requirements.hairgel ~= nil then
			if self.visualItem.requirements.hairgel then
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end
	end
end

function HairAvatar:instantiate()
	VisualAvatar.instantiate(self)
	-- NOTE: Aims at the face.
	self:setZoom(18);
	self:setYOffset(-0.9);
	self:setXOffset(0);
end