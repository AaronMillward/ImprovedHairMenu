--[[
	disableBtn modified to use modded UI elements.
	- We break down the method into smaller functions in case anyone needs to inject anything for compatibility.
	- Completely overwrites the original method as the original doesn't work due to removing elements from the screen.

	Earlier versions of this mod simply appended functionality to this method but this means we have to keep all
	the vanilla elements around and functional which is hard to maintain when the game updates.
]]

ImprovedHairMenu = ImprovedHairMenu or {}


function ImprovedHairMenu.clothingapplyToDesc(visualItem, desc)
	local wornItems = desc:getWornItems()

	visualItem.original = {}
	for i=0, wornItems:size()-1 do
		table.insert(visualItem.original, wornItems:get(i))
	end
	
	if visualItem.id then
		wornItems:setItem(visualItem.bodyLocation, InventoryItemFactory.CreateItem(visualItem.id))
	else
		wornItems:setItem(visualItem.bodyLocation, nil)
	end
end

function ImprovedHairMenu.clothingrestoreDesc(visualItem, desc)
	local wornItems = desc:getWornItems()
	wornItems:clear()
	for _,wornItem in ipairs(visualItem.original) do
		wornItems:setItem(wornItem:getLocation(), wornItem:getItem())
	end
end

local function generateHairList(female)
	local desc = MainScreen.instance.desc
	local infoHair = {}
	local hairStyles = getAllHairStyles(desc:isFemale())
	for i=1,hairStyles:size() do
		local styleId = hairStyles:get(i-1)
		local hairStyle = female and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
		local label = styleId
		if label == "" then
			label = getText("IGUI_Hair_Bald")
		else
			label = getText("IGUI_Hair_" .. label);
		end
		if not hairStyle:isNoChoose() then
			table.insert(infoHair, {
				id = hairStyles:get(i-1),
				display = label,
				selected = false,
				getterName = "getHairModel",
				setterName = "setHairModel",
			})
		end
	end

	return infoHair
end

local function generateBeardList()
	local desc = MainScreen.instance.desc
	local infoBeard = {}
	if desc:isFemale() then
		-- no bearded ladies
	else
		local beardStyles = getAllBeardStyles()
		for i=1,beardStyles:size() do
			local label = beardStyles:get(i-1)
			if label == "" then
				label = getText("IGUI_Beard_None")
			else
				label = getText("IGUI_Beard_" .. label);
			end
			table.insert(infoBeard, {
				id = beardStyles:get(i-1),
				display = label,
				selected = false,
				getterName = "getBeardModel",
				setterName = "setBeardModel",
			})
		end
	end
	return infoBeard
end

local function updateCombo(self, desc)
	local infoHair = generateHairList(self.female)
	if self.hairMenu then self.hairMenu:setInfoTable(infoHair) end

	local infoBeard = generateBeardList()
	if self.beardMenu then self.beardMenu:setInfoTable(infoBeard) end

	--########
	--Clothing
	--########
	
	if self.outfitCombo then
		self.outfitCombo.options = {}
		self.outfitCombo:addOptionWithData(getText("UI_characreation_clothing_none"), nil)
		local outfits = getAllOutfits(desc:isFemale())
		for i=1,outfits:size() do
			self.outfitCombo:addOptionWithData(outfits:get(i-1), outfits:get(i-1))
		end
	end
	
	local fillMenu = function(bodyLocation)
		local menu = self.clothingMenu[bodyLocation]
		local items = getAllItemsForBodyLocation(bodyLocation)
		table.sort(items, function(a,b)
			local itemA = ScriptManager.instance:FindItem(a)
			local itemB = ScriptManager.instance:FindItem(b)
			return not string.sort(itemA:getDisplayName(), itemB:getDisplayName())
		end)
		
		local info = {
			{
				id = nil,
				display = getText("UI_characreation_clothing_none"),
				applyToDesc = ImprovedHairMenu.clothingapplyToDesc,
				restoreDesc = ImprovedHairMenu.clothingrestoreDesc,
				bodyLocation = bodyLocation,
			},
		}
		for _,fullType in ipairs(items) do
			local item = ScriptManager.instance:FindItem(fullType)
			local displayName = item:getDisplayName()
			table.insert(info,
				{
					id = fullType,
					display = displayName,
					applyToDesc = ImprovedHairMenu.clothingapplyToDesc,
					restoreDesc = ImprovedHairMenu.clothingrestoreDesc,
					bodyLocation = bodyLocation,
				}
			)
		end
		menu.attachedPanel:setInfoTable(info)
	end
	
	if CharacterCreationMain.debug then
		for bodyLocation,menu in pairs(self.clothingMenu) do
			fillMenu(bodyLocation)
			menu.attachedPanel:showPage(1)
		end
	end
end

local function setMaleVisiblity(self, visible)
	self.chestHairLbl:setVisible(visible)
	self.chestHairTickBox:setVisible(visible)
	self.beardRect:setVisible(visible)
	self.beardLbl:setVisible(visible)
	self.beardMenu:setVisible(visible)
	if self.beardMenuButton then self.beardMenuButton:setVisible(visible) end
	-- NOTE: We don't set the stubble box because it's a child of beardMenu
end

local function updateSkinColor(self)
	if ImprovedHairMenu.skinColors and self.skinColor then
		local color = ImprovedHairMenu.skinColors[self.skinColor]
		self.skinColorButton.backgroundColor.r = color.r
		self.skinColorButton.backgroundColor.g = color.g
		self.skinColorButton.backgroundColor.b = color.b
		self.skinColorButton.attachedPanel:setSelectedInfoIndex(self.skinColor)
	end
end

local function setHairColor(self, desc)
	local color = desc:getHumanVisual():getHairColor()
	self.hairColorButton.backgroundColor.r = color:getRedFloat()
	self.hairColorButton.backgroundColor.g = color:getGreenFloat()
	self.hairColorButton.backgroundColor.b = color:getBlueFloat()
end

local function matchDescriptionHairModel(hairMenu, desc)
	local hairModel = desc:getHumanVisual():getHairModel()
	local i = hairMenu:findInfoIndex(function (info)
		return info.id:lower() == hairModel:lower()
	end)
	-- NOTE: hairMenu's onSelect triggers disableBtn so we need to set the selection silently to avoid an infinite loop
	if i then
		hairMenu:setSelectedInfoIndex(i)
	end
end

local function matchDescriptionBeardModel(beardMenu, desc)
	local beardModel = desc:getHumanVisual():getBeardModel()
	local i = beardMenu:findInfoIndex(function (info)
		return info.id:lower() == beardModel:lower()
	end)
	if i then
		beardMenu:setSelectedInfoIndex(i)
	end
end

local function updateTextureChoices(clothingTextureCombo, clothingItem, item, bodyLocation)
	local textureChoices = clothingItem and (clothingItem:hasModel() and clothingItem:getTextureChoices() or clothingItem:getBaseTextures())
	
	local hasTextureChoices = textureChoices and (textureChoices:size() > 1)
	
	if hasTextureChoices == true then
		local textureChoice = clothingItem:hasModel() and item:getVisual():getTextureChoice() or item:getVisual():getBaseTexture()
		local combo = clothingTextureCombo[bodyLocation];
		combo:setVisible(true);
		combo.options = {}
		for i=0,textureChoices:size() - 1 do
			combo:addOptionWithData("Type " .. (i + 1), textureChoices:get(i))
			if i == textureChoice then
				combo:select("Type " .. (i + 1));
			end
		end
	else
		clothingTextureCombo[bodyLocation].options = {};
		clothingTextureCombo[bodyLocation]:setVisible(false);
	end
end

local function updateTint(clothingColorBtn, clothingItem, item, bodyLocation)
	if clothingItem and clothingItem:getAllowRandomTint() then
		local color = item:getVisual():getTint(clothingItem)
		clothingColorBtn[bodyLocation].backgroundColor = { r=color:getRedFloat(), g=color:getGreenFloat(), b=color:getBlueFloat(), a = 1 }
		clothingColorBtn[bodyLocation]:setVisible(true)
	else
		clothingColorBtn[bodyLocation].backgroundColor = { r=1, g=1, b=1, a = 1 }
		clothingColorBtn[bodyLocation]:setVisible(false)
	end
end

local function updateDecal(self, clothingDecalCombo, clothingItem, item, bodyLocation)
	if clothingItem and clothingItem:getDecalGroup() then
		-- Fill the decal combo if a different clothing item is now selected.
		if self.decalItem ~= item then
			self.decalItem = item
			local decalCombo = clothingDecalCombo[bodyLocation]
			decalCombo.options = {}
			local items = getAllDecalNamesForItem(item)
			for i=1,items:size() do
				decalCombo:addOptionWithData(items:get(i-1), items:get(i-1))
			end
		end
		local decalName = item:getVisual():getDecal(clothingItem)
		clothingDecalCombo[bodyLocation]:select(decalName)
		clothingDecalCombo[bodyLocation]:setVisible(true)
	else
		clothingDecalCombo[bodyLocation]:setVisible(false)
	end
end

local function setupDebug(self, desc)
	for bodyLocation,menuButton in pairs(self.clothingMenu) do
		local menu = menuButton.attachedPanel

		local selected = menu.selectedInfo
		menu:setSelectedInfoIndex(1)
		local item = desc:getWornItem(bodyLocation)
		local clothingItem = nil
		if item and item:getVisual() then
			local i = menu:findInfoIndex(function (info)
				return info.id == item:getFullType()
			end)
			menu:setSelectedInfoIndex(i)
			clothingItem = item:getVisual():getClothingItem()
		end
		menuButton:setTitle(selected.display)
		
		updateTextureChoices(self.clothingTextureCombo, clothingItem, item, bodyLocation)
		updateTint(self.clothingColorBtn, clothingItem, item, bodyLocation)
		updateDecal(self, self.clothingDecalCombo, clothingItem, item, bodyLocation)
	end
end

function CharacterCreationMain:disableBtn()
	-- CharacterCreationHeader calls this during creation
	if not self.chestHairLbl then return end -- If the menu hasn't been created yet
	
	local desc = MainScreen.instance.desc
	setMaleVisiblity(self, not desc:isFemale())
	local genderHasChanged = self.female ~= desc:isFemale()
	if genderHasChanged or CharacterCreationMain.forceUpdateCombo then
		CharacterCreationMain.forceUpdateCombo = false
		self.female = desc:isFemale()
		updateCombo(self, desc)
	end
	self:syncUIWithTorso()
	updateSkinColor(self)
	setHairColor(self, desc)

	if MainScreen.instance.avatar then
		matchDescriptionHairModel(self.hairMenu, desc)
		
		if not desc:isFemale() then
			matchDescriptionBeardModel(self.beardMenu, desc)
		end
		
		if CharacterCreationMain.debug then
			setupDebug(self, desc)
		end
	end
end