local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

ImprovedHairMenu = ImprovedHairMenu or {}

local AvatarMenuPanel = require("z_improved_hair_menu/Components/AvatarMenuPanel.lua")
local MenuPanelButton = require("z_improved_hair_menu/Components/MenuButton.lua")

function CharacterCreationMain:createChestTypeBtn()
	local comboHgt = FONT_HGT_SMALL + 3 * 2
	
	local lbl = ISLabel:new(self.xOffset, self.yOffset, FONT_HGT_MEDIUM, getText("UI_characreation_body"), 1, 1, 1, 1, UIFont.Medium, true);
	lbl:initialise();
	lbl:instantiate();
	self.characterPanel:addChild(lbl);
	
	local rect = ISRect:new(self.xOffset, self.yOffset + FONT_HGT_MEDIUM + 5, 300, 1, 1, 0.3, 0.3, 0.3);
	rect:initialise();
	rect:instantiate();
	self.characterPanel:addChild(rect);
	
	self.yOffset = self.yOffset + FONT_HGT_MEDIUM + 15;
	
	-------------
	-- SKIN COLOR 
	-------------
	self.skinColorLbl = ISLabel:new(self.xOffset+70, self.yOffset, comboHgt, getText("UI_SkinColor"), 1, 1, 1, 1, UIFont.Small);
	self.skinColorLbl:initialise();
	self.skinColorLbl:instantiate();
	self.characterPanel:addChild(self.skinColorLbl);
	
	local xColor = 90;
	
	local avatar_size = ImprovedHairMenu.settings:get_avatar_size()
	self.skinColorButton = MenuPanelButton:new(
		self.xOffset+xColor, self.yOffset, 45, comboHgt, "",
		self, CharacterCreationMain.onSkinColorButtonClick, nil, nil, 
		AvatarMenuPanel, avatar_size, avatar_size * 1.5, 1, #ImprovedHairMenu.skinColors, 3, false
	)
	self.skinColorButton:initialise()
	self.skinColorButton:instantiate()
	local color = ImprovedHairMenu.skinColors[1]
	self.skinColorButton.backgroundColor = {r = color.r, g = color.g, b = color.b, a = 1}
	self.characterPanel:addChild(self.skinColorButton)
	
	self.skinColorButton.attachedPanel.resetFocusTo = self.characterPanel
	self.skinColorButton.attachedPanel:setDesc(MainScreen.instance.desc)
	ImprovedHairMenu:RegisterPanel(self.skinColorButton.attachedPanel)

	function self.skinColorButton.attachedPanel.onSelect(info)
		ImprovedHairMenu:onSkinColorSelected(self, CharacterCreationHeader.instance, info.id)
	end
	
	self.skinColorButton.attachedPanel:setInfoTable({
		{
			id = 0,
			display = getText("IGUI_IHM_lightest_skin_color"),
			getterName = "getSkinTextureIndex",
			setterName = "setSkinTextureIndex",
		},
		{
			id = 1,
			display = getText("IGUI_IHM_light_skin_color"),
			getterName = "getSkinTextureIndex",
			setterName = "setSkinTextureIndex",
		},
		{
			id = 2,
			display = getText("IGUI_IHM_medium_skin_color"),
			getterName = "getSkinTextureIndex",
			setterName = "setSkinTextureIndex",
		},
		{
			id = 3,
			display = getText("IGUI_IHM_dark_skin_color"),
			getterName = "getSkinTextureIndex",
			setterName = "setSkinTextureIndex",
		},
		{
			id = 4,
			display = getText("IGUI_IHM_darkest_skin_color"),
			getterName = "getSkinTextureIndex",
			setterName = "setSkinTextureIndex",
		},
	})
	
	self.yOffset = self.yOffset + FONT_HGT_SMALL + 5 + 4;
	
	-------------
	-- CHEST HAIR
	-------------
	self.chestHairLbl = ISLabel:new(self.xOffset+70, self.yOffset, comboHgt, getText("UI_ChestHair"), 1, 1, 1, 1, UIFont.Small);
	self.chestHairLbl:initialise();
	self.chestHairLbl:instantiate();
	self.characterPanel:addChild(self.chestHairLbl);

	local tickBox = ISTickBox:new(self.xOffset+90, self.yOffset, self.comboWid, comboHgt, "", self, CharacterCreationMain.onChestHairSelected)
	tickBox:initialise()
	self.characterPanel:addChild(tickBox)
	tickBox:addOption("")
	self.chestHairLbl:setHeight(tickBox.height)
	self.chestHairTickBox = tickBox

	self.yOffset = self.yOffset + comboHgt + 10;
end

function CharacterCreationMain:onSkinColorButtonClick(button)
	button.attachedPanel:addToUIManager()
	button.attachedPanel:setX(button:getAbsoluteX())
	button.attachedPanel:setY(button:getAbsoluteY() + button:getHeight())
	if self.characterPanel.joyfocus then
		self.characterPanel.joyfocus.focus = button.attachedPanel
	end
end

function ImprovedHairMenu:onSkinColorSelected(characterCreationMain, characterCreationHeader, index)
	local color = ImprovedHairMenu.skinColors[index+1]
	characterCreationMain.skinColorButton.backgroundColor = { r=color.r, g=color.g, b=color.b, a = 1 }
	local desc = MainScreen.instance.desc
	desc:getHumanVisual():setSkinTextureIndex(index)
	characterCreationHeader.avatarPanel:setSurvivorDesc(desc)
	characterCreationMain:disableBtn()
end

ImprovedHairMenu.skinColors = {
	{r=1,g=0.91,b=0.72},
	{r=0.98,g=0.79,b=0.49},
	{r=0.8,g=0.65,b=0.45},
	{r=0.54,g=0.38,b=0.25},
	{r=0.36,g=0.25,b=0.14}
}

function ImprovedHairMenu:getSkinRGBAsIndex(color)
	for i,sc in ipairs(self.skinColors) do
		if sc.r == color.r and sc.g == color.g and sc.b == color.b then
			return i-1
		end
	end
end

function ImprovedHairMenu:getSkinIndexAsRHB(index)
	return self.skinColors[index+1]
end