--[[ 
	Provides joypad support by inserting the menu as a button in the ui and
	forwarding input from the character panel to the menu.
 ]]

-- NOTE: We overwrite this to replace the old combo with the menu in the joypad order
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
	if ImprovedHairMenu.settings.use_modal then
		--[[ XXX:
			If you use the mouse to click the button while also using the joypad the joypad will be detached from the dialog,
			the vanilla game does this too for example when clicking to change sex then using the controller.
		 ]]
		self:insertNewLineOfButtons(charCreationMain.hairMenuButton);
	else
		self:insertNewLineOfButtons(charCreationMain.hairMenu);
	end
	-- self:insertNewLineOfButtons(charCreationMain.hairTypeCombo);
	-- self:insertNewLineOfButtons(charCreationMain.hairColorButton);
	-- self:insertNewLineOfButtons(charCreationMain.hairStubbleTickBox)
	if not MainScreen.instance.desc:isFemale() then
		-- self:insertNewLineOfButtons(charCreationMain.beardTypeCombo);
		-- self:insertNewLineOfButtons(charCreationMain.beardStubbleTickBox)
		if ImprovedHairMenu.settings.use_modal then 
			self:insertNewLineOfButtons(charCreationMain.beardMenuButton)
		else
			self:insertNewLineOfButtons(charCreationMain.beardMenu)
		end
	end
	self.joypadIndex = 1
	self.joypadIndexY = 1
	self.joypadButtons = self.joypadButtonsY[self.joypadIndexY];
--    self.joypadButtons[self.joypadIndex]:setJoypadFocused(true, joypadData)
	if oldFocus and oldFocus:isVisible() and joypadData.focus == self then
		self:setJoypadFocus(oldFocus, joypadData)
	end
end

--[[ NOTE:
	We override these onJoypad* functions to pass joypad events to the menu. Passing focus to
	the menu proved too difficult so this will do.
	
	This is similar to what is seen in the vanilla files mainly `ISPanelJoypad`.
 ]]

--[[ XXX:
	These onJoypad* functions in vanilla call a `ensureVisible` function I don't know if it's needed here?
 ]]

local original_onJoypadDown = CharacterCreationMainCharacterPanel.onJoypadDown
function CharacterCreationMainCharacterPanel:onJoypadDown(button, joypadData)
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	if child and child.isHairMenuButton then
		if child.expanded == false then
			if button == Joypad.AButton then
				child:forceClick()
			else
				original_onJoypadDown(self, button, joypadData)
			end
		else
			if button == Joypad.BButton then
				child.attachedMenu:close()
			else
				child.attachedMenu:onJoypadDown(button, joypadData)
			end
		end
	elseif child and child.isHairMenu then
		if button == Joypad.BButton then original_onJoypadDown(self, button, joypadData) return end
		child:onJoypadDown(button, joypadData)
	else
		original_onJoypadDown(self, button, joypadData)
	end
end

local original_onJoypadDirLeft = CharacterCreationMainCharacterPanel.onJoypadDirLeft
function CharacterCreationMainCharacterPanel:onJoypadDirLeft(joypadData)
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	
	if child and child.isHairMenuButton then
		if child.expanded == false then
			original_onJoypadDirLeft(self, joypadData)
		else
			child.attachedMenu:onJoypadDirLeft(joypadData)
		end
	elseif child and child.isHairMenu then
		child:onJoypadDirLeft(joypadData)
	else
		original_onJoypadDirLeft(self, joypadData)
	end
end

local original_onJoypadDirRight = CharacterCreationMainCharacterPanel.onJoypadDirRight
function CharacterCreationMainCharacterPanel:onJoypadDirRight(joypadData)
	local children = self:getVisibleChildren(self.joypadIndexY)
	local child = children[self.joypadIndex]
	if child and child.isHairMenuButton then
		if child.expanded == false then
			original_onJoypadDirRight(self, joypadData)
		else
			child.attachedMenu:onJoypadDirRight(joypadData)
		end
	elseif child and child.isHairMenu then
		child:onJoypadDirRight(joypadData)
	else
		original_onJoypadDirRight(self, joypadData)
	end
end

local old_onJoypadDirUp = CharacterCreationMainCharacterPanel.onJoypadDirUp
function CharacterCreationMainCharacterPanel:onJoypadDirUp(joypadData)
	local child = self:getVisibleChildren(self.joypadIndexY)[self.joypadIndex]
	if child and child.isHairMenuButton then
		if child.expanded == true then
			child.attachedMenu:onJoypadDirUp(joypadData)
		else
			old_onJoypadDirUp(self, joypadData)
		end
	elseif child and child.isHairMenu then
		if child:isNextUpOutside() then
			old_onJoypadDirUp(self, joypadData)
		else
			child:onJoypadDirUp(joypadData)
		end
	else
		old_onJoypadDirUp(self, joypadData)
	end
end

local old_onJoypadDirDown = CharacterCreationMainCharacterPanel.onJoypadDirDown
function CharacterCreationMainCharacterPanel:onJoypadDirDown(joypadData)
	local child = self:getVisibleChildren(self.joypadIndexY)[self.joypadIndex]
	if child and child.isHairMenuButton then
		if child.expanded == true then
			child.attachedMenu:onJoypadDirDown(joypadData)
		else
			old_onJoypadDirDown(self, joypadData)
		end
	elseif child and child.isHairMenu then
		if child:isNextDownOutside() then
			old_onJoypadDirDown(self, joypadData)
		else
			child:onJoypadDirDown(joypadData)
		end
	else
		old_onJoypadDirDown(self, joypadData)
	end
end