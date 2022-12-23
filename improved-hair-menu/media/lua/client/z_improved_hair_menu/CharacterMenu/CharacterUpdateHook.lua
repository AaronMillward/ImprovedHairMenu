--[[
	Creates a hook for when the user changes the model.
 ]]

local original_CharacterCreationHeader_create = CharacterCreationHeader.create
function CharacterCreationHeader:create()
	original_CharacterCreationHeader_create(self)
	
	local setSurvivorDesc_old = self.avatarPanel.setSurvivorDesc
	function self.avatarPanel:setSurvivorDesc(desc)
		setSurvivorDesc_old(self, desc)
		CharacterCreationMain.instance:ihm_update_preview_model(desc)
	end
end

function CharacterCreationMain:ihm_update_preview_model(desc)
	if self.hairMenu then 
		self.hairMenu:applyVisual()
	end

	if self.beardMenu then 
		self.beardMenu:applyVisual()
	end
end