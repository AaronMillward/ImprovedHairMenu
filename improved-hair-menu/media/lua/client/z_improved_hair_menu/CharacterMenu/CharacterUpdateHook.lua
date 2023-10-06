--[[
	Creates a hook for when the user changes the model.
 ]]

ImprovedHairMenu = ImprovedHairMenu or {}

local original_CharacterCreationHeader_create = CharacterCreationHeader.create
function CharacterCreationHeader:create()
	original_CharacterCreationHeader_create(self)
	
	local setSurvivorDesc_old = self.avatarPanel.setSurvivorDesc
	function self.avatarPanel:setSurvivorDesc(desc)
		setSurvivorDesc_old(self, desc)
		ImprovedHairMenu:updatePreviewModels(desc)
	end
end

function ImprovedHairMenu:updatePreviewModels(desc)
	for _,p in ipairs(self.RegisteredPanels) do
		p:applyVisual()
	end
end

function ImprovedHairMenu:RegisterPanel(panel)
	self.RegisteredPanels = self.RegisteredPanels or {}
	table.insert(self.RegisteredPanels, panel)
end

function ImprovedHairMenu:UnregisterPanel(panel)
	self.RegisteredPanels = self.RegisteredPanels or {}
	for i,storedPanel in ipairs(self.RegisteredPanels) do
		if panel == storedPanel then
			table.remove(self.RegisteredPanels, i)
			break
		end
	end
end