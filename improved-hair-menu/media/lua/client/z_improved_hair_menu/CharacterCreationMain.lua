-- We overwrite this to replace the old combo with the menu in the joypad order
function CharacterCreationMainCharacterPanel:loadJoypadButtons(joypadData)
	joypadData = joypadData or self.joyfocus
--[[
	if joypadData and #self.joypadButtonsY > 0 then
		return
	end
--]]
	local oldFocus = nil
	if joypadData then
		oldFocus = self:getJoypadFocus()
		self:clearJoypadFocus(joypadData)
	end
	self.joypadButtonsY = {};
	self:insertNewLineOfButtons(MainScreen.instance.charCreationHeader.forenameEntry)
	self:insertNewLineOfButtons(MainScreen.instance.charCreationHeader.surnameEntry)
	self:insertNewLineOfButtons(MainScreen.instance.charCreationHeader.genderCombo)
	local buttons = {}
	local charCreationMain = self.parent.parent
	table.insert(buttons, charCreationMain.skinColorButton)
	table.insert(buttons, charCreationMain.clothingOutfitCombo)
	self:insertNewListOfButtons(buttons)
	if not MainScreen.instance.desc:isFemale() then
		self:insertNewLineOfButtons(charCreationMain.chestHairTickBox)
	end
	self:insertNewLineOfButtons(charCreationMain.hairMenu);
	-- self:insertNewLineOfButtons(charCreationMain.hairTypeCombo);
	-- self:insertNewLineOfButtons(charCreationMain.hairColorButton);
	-- self:insertNewLineOfButtons(charCreationMain.hairStubbleTickBox)
	if not MainScreen.instance.desc:isFemale() then
		-- self:insertNewLineOfButtons(charCreationMain.beardTypeCombo);
		-- self:insertNewLineOfButtons(charCreationMain.beardStubbleTickBox)
		self:insertNewLineOfButtons(charCreationMain.beardMenu)
	end
	self.joypadIndex = 1
	self.joypadIndexY = 1
	self.joypadButtons = self.joypadButtonsY[self.joypadIndexY];
--    self.joypadButtons[self.joypadIndex]:setJoypadFocused(true, joypadData)
	if oldFocus and oldFocus:isVisible() and joypadData.focus == self then
		self:setJoypadFocus(oldFocus, joypadData)
	end
end

--[[ 
	We override these functions to pass joypad events to the menu.
	Passing focus to the menu proved too difficult so this will do.
 ]]

local original_onJoypadDown = CharacterCreationMainCharacterPanel.onJoypadDown
function CharacterCreationMainCharacterPanel:onJoypadDown(button, joypadData)
	if button == Joypad.BButton then
		original_onJoypadDown(self, button, joypadData)
		return
	end
	
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	if child and child.isHairMenu then
		child:onJoypadDown(button, joypadData)
	else
		original_onJoypadDown(self, button, joypadData)
	end
end

-- See comment in HairMenuPanel:onJoypadDirDown
-- local original_onJoypadDirDown = CharacterCreationMainCharacterPanel.onJoypadDirDown
-- function CharacterCreationMainCharacterPanel:onJoypadDirDown(joypadData)
-- end

local original_onJoypadDirLeft = CharacterCreationMainCharacterPanel.onJoypadDirLeft
function CharacterCreationMainCharacterPanel:onJoypadDirLeft(joypadData)
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	if child and child.isHairMenu then
		child:onJoypadDirLeft(joypadData)
	else
		original_onJoypadDirLeft(self, joypadData)
	end
end

local original_onJoypadDirRight = CharacterCreationMainCharacterPanel.onJoypadDirRight
function CharacterCreationMainCharacterPanel:onJoypadDirRight(joypadData)
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	if child and child.isHairMenu then
		child:onJoypadDirRight(joypadData)
	else
		original_onJoypadDirRight(self, joypadData)
	end
end