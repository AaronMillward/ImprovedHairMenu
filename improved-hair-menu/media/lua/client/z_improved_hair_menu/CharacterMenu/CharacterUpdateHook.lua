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
	for _,p in ipairs(self.ICSVisuals) do
		p:applyVisual()
	end
end

function CharacterCreationMain:ICSAddPanel(panel)
	self.ICSVisuals = self.ICSVisuals or {}
	table.insert(self.ICSVisuals, panel)
end

function CharacterCreationMain:ICSRemovePanel(panel)
	self.ICSVisuals = self.ICSVisuals or {}
	for i,storedPanel in ipairs(self.ICSVisuals) do
		if panel == storedPanel then
			table.remove(self.ICSVisuals, i)
			break
		end
	end
end