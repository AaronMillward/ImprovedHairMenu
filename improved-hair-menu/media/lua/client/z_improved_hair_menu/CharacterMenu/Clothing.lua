local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_TITLE = getTextManager():getFontHeight(UIFont.Title)

local function createClothingComboUnified(self, bodyLocation, debug)
	local comboHgt = FONT_HGT_SMALL + 3 * 2
	local x = 0

	if debug == false and not self.clothingPanel then return; end
	
	local label = ISLabel:new(x + 70 + 70, self.yOffset, comboHgt, getText("UI_ClothingType_" .. bodyLocation), 1, 1, 1, 1, UIFont.Small)
	label:initialise()
	self.clothingPanel:addChild(label)

	local avatar_size = ImprovedHairMenu.settings:get_avatar_size()
	local menuButton = MenuPanelButton:new(
		90 + 70, self.yOffset, self.comboWid, comboHgt, getText("UI_ClothingType_" .. bodyLocation),
		self, CharacterCreationMain.onSkinColorButtonClick, nil, nil,
		AvatarMenuPanel, avatar_size, avatar_size * 1.5, 1, 5, 3
	)
	menuButton:initialise()
	menuButton:instantiate()
	self.clothingPanel:addChild(menuButton)
	
	menuButton.attachedPanel.resetFocusTo = self.characterPanel
	menuButton.attachedPanel:setDesc(MainScreen.instance.desc)
	self:ICSAddPanel(menuButton.attachedPanel)
	menuButton.bodyLocation = bodyLocation

	function menuButton.attachedPanel.onSelect(info)
		local desc = MainScreen.instance.desc
		desc:setWornItem(bodyLocation, nil)
		local itemType = info.id
		if itemType then
			local item = InventoryItemFactory.CreateItem(itemType)
			if item then
				desc:setWornItem(bodyLocation, item)
			end
		end
		self:updateSelectedClothingCombo();
		
		CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
		self:disableBtn()
	end

	local fontHgt = getTextManager():getFontHeight(self.skinColorLbl.font)
	local button = ISButton:new(menuButton:getRight() + 20, self.yOffset, 45, comboHgt, "", self)
	button:setOnClick(CharacterCreationMain.onClothingColorClicked, bodyLocation)
	button.internal = color
	button:initialise()
	button.backgroundColor = {r = 1, g = 1, b = 1, a = 1}
	self.clothingPanel:addChild(button)

	local comboDecal = nil
	if debug == true then
		local comboDecal = ISComboBox:new(button:getRight() + 20, self.yOffset, self.comboWid, comboHgt, self, self.onClothingDecalComboSelected, bodyLocation)
		comboDecal:initialise()
		self.clothingPanel:addChild(comboDecal)
	end 

	local comboTexture = ISComboBox:new(menuButton:getRight() + 20, self.yOffset, 80, comboHgt, self, self.onClothingTextureComboSelected, bodyLocation)
	comboTexture:initialise()
	self.clothingPanel:addChild(comboTexture)
	
	self.clothingMenu = self.clothingMenu or {}
	self.clothingColorBtn = self.clothingColorBtn or {}
	self.clothingTextureCombo = self.clothingTextureCombo or {}
	self.clothingDecalCombo = self.clothingDecalCombo or {}
	self.clothingComboLabel = self.clothingComboLabel or {}
	
	self.clothingMenu[bodyLocation] = menuButton
	self.clothingColorBtn[bodyLocation] = button
	self.clothingTextureCombo[bodyLocation] = comboTexture
	self.clothingDecalCombo[bodyLocation] = comboDecal
	self.clothingComboLabel[bodyLocation] = label;

	table.insert(self.clothingWidgets, { menuButton, button, comboDecal, comboTexture })
	
	self.yOffset = self.yOffset + menuButton:getHeight() + 4
	
	return
end

function CharacterCreationMain:createClothingCombo(bodyLocation)
	createClothingComboUnified(self, bodyLocation, false)
end

function CharacterCreationMain:createClothingComboDebug(bodyLocation)
	createClothingComboUnified(self, bodyLocation, true)
end

function CharacterCreationMain:doClothingCombo(definition, erasePrevious)
	if not self.clothingPanel then return; end
	
	-- reinit all combos
	if erasePrevious then
		if self.clothingMenu then
			for i,v in pairs(self.clothingMenu) do
				self.clothingPanel:removeChild(self.clothingColorBtn[v.bodyLocation]);
				self.clothingPanel:removeChild(self.clothingTextureCombo[v.bodyLocation]);
				self.clothingPanel:removeChild(self.clothingComboLabel[v.bodyLocation]);
				self:ICSRemovePanel(v.attachedPanel)
				self.clothingPanel:removeChild(v);
			end
		end
		self.clothingMenu = {};
		self.clothingColorBtn = {};
		self.clothingTextureCombo = {};
		self.clothingComboLabel = {};
		self.yOffset = self.originalYOffset;
	end
	
	-- create new combo or populate existing one (for when having specific profession clothing)
	local desc = MainScreen.instance.desc;
	for bodyLocation, profTable in pairs(definition) do
		local menuButton = nil;
		if self.clothingMenu then
			menuButton = self.clothingMenu[bodyLocation]
		end
		if not menuButton then
			self:createClothingCombo(bodyLocation);
			menuButton = self.clothingMenu[bodyLocation];
			table.insert(menuButton.attachedPanel.info, {
					id = nil,
					display = getText("UI_characreation_clothing_none"),
					applyToDesc = clothingapplyToDesc,
					restoreDesc = clothingrestoreDesc,
					bodyLocation = bodyLocation,
				}
			)
		end
		if erasePrevious then
			menuButton.attachedPanel:setInfoTable({})
			table.insert(menuButton.attachedPanel.info, {
				id = nil,
				display = getText("UI_characreation_clothing_none"),
				applyToDesc = clothingapplyToDesc,
				restoreDesc = clothingrestoreDesc,
				bodyLocation = bodyLocation,
			})
		end
		
		for j,clothing in ipairs(profTable.items) do
			local item = ScriptManager.instance:FindItem(clothing)
			local displayName = item:getDisplayName()
			-- some clothing are president in default list AND profession list, so we can force a specific clothing in profession we already have
			local isDuplicate = false
			for _, info in ipairs(menuButton.attachedPanel.info) do
				if info.display == displayName then isDuplicate = true end
			end
			if isDuplicate == false then
				table.insert(menuButton.attachedPanel.info, {
					id = clothing,
					display = displayName,
					applyToDesc = clothingapplyToDesc,
					restoreDesc = clothingrestoreDesc,
					bodyLocation = bodyLocation,
				})
			end
		end

		menuButton.attachedPanel:showPage(1)
	end
	
	self:updateSelectedClothingCombo();
	
	self.clothingPanel:setScrollChildren(true)
	self.clothingPanel:setScrollHeight(self.yOffset)
	self.clothingPanel:addScrollBars()
	
	self.colorPicker = ISColorPicker:new(0, 0, {h=1,s=0.6,b=0.9});
	self.colorPicker:initialise()
	self.colorPicker.keepOnScreen = true
	self.colorPicker.pickedTarget = self
	self.colorPicker.resetFocusTo = self.clothingPanel
end

function CharacterCreationMain:updateSelectedClothingCombo()
	if CharacterCreationMain.debug then return; end
	local desc = MainScreen.instance.desc;
	if self.clothingMenu then
		for i,menu in pairs(self.clothingMenu) do
			menu.attachedPanel:setSelectedInfoIndex(1)
			self.clothingColorBtn[menu.bodyLocation]:setVisible(false);
			self.clothingTextureCombo[menu.bodyLocation]:setVisible(false);
			-- we select the current clothing we have at this location in the combo
			local currentItem = desc:getWornItem(menu.bodyLocation);
			if currentItem then
				for j,v in ipairs(menu.attachedPanel.info) do
					if v.display == currentItem:getDisplayName() then
						menu.attachedPanel:setSelectedInfoIndex(j)
						break
					end
				end
				self:updateColorButton(menu.bodyLocation, currentItem);
				self:updateClothingTextureCombo(menu.bodyLocation, currentItem);
			end
		end
	end
end