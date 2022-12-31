--[[
	Replace the original hair combo with our new menu.

	This does overwrite the original code but compared with rearranging the existing elements by hand this just seems easier.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function is_low_res()
	--[[ NOTE:
		786 is what I've seen in a lot of vanilla code,
		I'm not certain of its significance but I think it's a common laptop resolution

		2022-03-10 Changed to 900 - Someone said the beard menu still appears offscreen at 900px resolution
	]]
	return (getCore():getScreenHeight() <= 900)
end

function CharacterCreationMain:createHairTypeBtn()
	--XXX: Should low res users be forced to use modal?
	local use_modal = ImprovedHairMenu.settings.use_modal == true or is_low_res()
	local avatar_size = ImprovedHairMenu.settings:get_avatar_size()
	local comboHgt = FONT_HGT_SMALL + 3 * 2
	
	local lbl = ISLabel:new(self.xOffset, self.yOffset, FONT_HGT_MEDIUM, getText("UI_characreation_hair"), 1, 1, 1, 1, UIFont.Medium, true);
	lbl:initialise();
	lbl:instantiate();
	self.characterPanel:addChild(lbl);
	
	local rect = ISRect:new(self.xOffset, self.yOffset + FONT_HGT_MEDIUM + 5, 300, 1, 1, 0.3, 0.3, 0.3);
	rect:setAnchorRight(false);
	rect:initialise();
	rect:instantiate();
	self.characterPanel:addChild(rect);
	
	self.yOffset = self.yOffset + FONT_HGT_MEDIUM + 15;
	
	local menu_size = ImprovedHairMenu.settings:get_menu_size(false)
	
	if use_modal then
		self.hairMenuButton = MenuPanelButton:new(
			self.xOffset, self.yOffset, 90, FONT_HGT_SMALL*2, getText("IGUI_Open"),
			self, CharacterCreationMain.onMenuButtonClick, nil, nil, 
			HairMenuPanel, avatar_size, avatar_size, menu_size.cols, menu_size.rows, 3
		)
		self.hairMenuButton:initialise()
		self.hairMenuButton:instantiate()
		self.characterPanel:addChild(self.hairMenuButton)
		self.yOffset = self.yOffset + self.hairMenuButton:getHeight() + 5;

		self.hairMenu = self.hairMenuButton.attachedPanel
	else
		self.hairMenu = HairMenuPanel:new(self.xOffset, self.yOffset, avatar_size,avatar_size, menu_size.cols,menu_size.rows, 3, false)
		self.hairMenu:initialise()
		
		self.characterPanel:addChild(self.hairMenu)
		self.yOffset = self.yOffset + self.hairMenu:getHeight() + 5;
	end

	self.hairMenu.onSelect = function(info) -- NOTE: Taken from onHairTypeSelected which requires the combobox as a parameter so obviously can't be used here.
		self:onHairTypeSelected(info.id)
	end
	self.hairMenu.resetFocusTo = self.characterPanel
	self.hairMenu:setDesc(MainScreen.instance.desc)
	self:ICSAddPanel(self.hairMenu)

	local hairColors = MainScreen.instance.desc:getCommonHairColor();
	local hairColors1 = {}
	local info = ColorInfo.new()
	for i=1,hairColors:size() do
		local color = hairColors:get(i-1)
		-- we create a new info color to desaturate it (like in the game)
		info:set(color:getRedFloat(), color:getGreenFloat(), color:getBlueFloat(), 1)
		--		info:desaturate(0.5)
		table.insert(hairColors1, { r=info:getR(), g=info:getG(), b=info:getB() })
	end

	local hairColorBtn = ISButton:new(self.hairMenu:getWidth() - 55, FONT_HGT_SMALL/2 , 45, FONT_HGT_SMALL, "", self, CharacterCreationMain.onHairColorMouseDown)
	hairColorBtn:initialise()
	hairColorBtn:instantiate()
	local color = hairColors1[1]
	hairColorBtn.backgroundColor = {r=color.r, g=color.g, b=color.b, a=1}
	self.hairMenu:addChild(hairColorBtn)
	self.hairMenu.hairColorBtn = hairColorBtn
	self.hairColorButton = hairColorBtn
	
	self.colorPickerHair = ISColorPicker:new(0, 0, nil)
	self.colorPickerHair:initialise()
	self.colorPickerHair.keepOnScreen = true
	self.colorPickerHair.pickedTarget = self
	if use_modal then
		self.colorPickerHair.resetFocusTo = self.hairMenu
	else
		self.colorPickerHair.resetFocusTo = self.characterPanel
	end
	self.colorPickerHair:setCapture(true)
	self.colorPickerHair:setColors(hairColors1, math.min(#hairColors1, 10), math.ceil(#hairColors1 / 10))

	-- ----------------------
	-- -- STUBBLE
	-- ----------------------

	self.hairStubbleTickBox = ISTickBox:new(self.hairMenu:getWidth() - 55 - FONT_HGT_SMALL - 8, comboHgt/4, FONT_HGT_SMALL-2, FONT_HGT_SMALL-2, "", self, CharacterCreationMain.onShavedHairSelected);
	self.hairStubbleTickBox:initialise()
	self.hairStubbleTickBox:addOption("")
	self.hairStubbleTickBox.tooltip = getText("UI_Stubble")
	self.hairMenu:addChild(self.hairStubbleTickBox)
	self.hairMenu.stubbleTickBox = self.hairStubbleTickBox
end

function CharacterCreationMain:onMenuButtonClick(button)
	button.attachedPanel:addToUIManager()
	button.attachedPanel:setX( (getCore():getScreenWidth()/2) - (button.attachedPanel:getWidth()/2) )
	button.attachedPanel:setY( (getCore():getScreenHeight()/2) - (button.attachedPanel:getHeight()/2) )
	if self.characterPanel.joyfocus then
		self.characterPanel.joyfocus.focus = button.attachedPanel
	end
end

function CharacterCreationMain:onHairColorMouseDown(button, x, y)
	self.colorPickerHair:setPickedFunc(CharacterCreationMain.onHairColorPicked)
	local color = button.backgroundColor
	self.colorPickerHair:setInitialColor(ColorInfo.new(color.r, color.g, color.b, 1))
	self.colorPickerHair:addToUIManager()
	self.colorPickerHair:setX(button:getAbsoluteX())
	self.colorPickerHair:setY(button:getAbsoluteY() + button:getHeight())

	if self.characterPanel.joyfocus then
		self.characterPanel.joyfocus.focus = self.colorPickerHair
	end
	if self.hairMenu.joyfocus then
		self.hairMenu.joyfocus.focus = self.colorPickerHair
	end
end

function CharacterCreationMain:onHairTypeSelected(name)
	local desc = MainScreen.instance.desc
	desc:getHumanVisual():setHairModel(name)
	CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
	self:disableBtn()
end

--##################
--## Beard Styles ##
--##################

function CharacterCreationMain:createBeardTypeBtn()
	local comboHgt = FONT_HGT_SMALL + 3 * 2
	local use_modal = ImprovedHairMenu.settings.use_modal == true or is_low_res()
	local avatar_size = ImprovedHairMenu.settings:get_avatar_size()
	
	self.beardLbl = ISLabel:new(self.xOffset, self.yOffset, FONT_HGT_MEDIUM, getText("UI_characreation_beard"), 1, 1, 1, 1, UIFont.Medium, true);
	self.beardLbl:initialise();
	self.beardLbl:instantiate();
	self.beardLbl:setVisible(false);
	self.characterPanel:addChild(self.beardLbl);
	
	self.beardRect = ISRect:new(self.xOffset, self.yOffset + FONT_HGT_MEDIUM + 5, 300, 1, 1, 0.3, 0.3, 0.3);
	self.beardRect:setAnchorRight(false);
	self.beardRect:initialise();
	self.beardRect:instantiate();
	self.beardRect:setVisible(false);
	self.characterPanel:addChild(self.beardRect);
	
	self.yOffset = self.yOffset + FONT_HGT_MEDIUM + 15;
	
	self.beardTypeLbl = ISLabel:new(self.xOffset+ 70, self.yOffset, comboHgt, getText("UI_characreation_beardtype"), 1, 1, 1, 1, UIFont.Small);
	self.beardTypeLbl:initialise();
	self.beardTypeLbl:instantiate();
	self.beardTypeLbl:setVisible(false);
	self.characterPanel:addChild(self.beardTypeLbl);
	
	-- NOTE: The following is copied from above, it only appears in these two places so I'm not making it a function

	local menu_size = ImprovedHairMenu.settings:get_menu_size(true)

	if use_modal then
		self.beardMenuButton = MenuPanelButton:new(
			self.xOffset, self.yOffset, 90, FONT_HGT_SMALL*2, getText("IGUI_Open"),
			self, CharacterCreationMain.onMenuButtonClick, nil, nil,
			HairMenuPanel, avatar_size, avatar_size, menu_size.cols, menu_size.rows, 3
		)
		self.beardMenuButton:initialise()
		self.beardMenuButton:instantiate()
		self.characterPanel:addChild(self.beardMenuButton)
		self.yOffset = self.yOffset + self.beardMenuButton:getHeight() + 5;

		self.beardMenu = self.beardMenuButton.attachedPanel
	else
		self.beardMenu = HairMenuPanel:new(self.xOffset, self.yOffset, avatar_size,avatar_size, menu_size.cols,menu_size.rows, 3, false)
		self.beardMenu:initialise()
		
		self.characterPanel:addChild(self.beardMenu)
		self.yOffset = self.yOffset + self.beardMenu:getHeight() + 5;
	end

	self.beardMenu.onSelect = function(info)
		self:onBeardTypeSelected(info.id)
	end
	self.beardMenu.resetFocusTo = self.characterPanel
	self.beardMenu:setDesc(MainScreen.instance.desc)
	self:ICSAddPanel(self.beardMenu)

	----------------------
	-- STUBBLE
	----------------------
	self.beardStubbleTickBox = ISTickBox:new(self.beardMenu:getWidth() - FONT_HGT_SMALL - 10, comboHgt/4, FONT_HGT_SMALL-2, FONT_HGT_SMALL-2, "", self, CharacterCreationMain.onBeardStubbleSelected);
	self.beardStubbleTickBox:initialise()
	self.beardStubbleTickBox:addOption("")
	self.beardStubbleTickBox.tooltip = getText("UI_Stubble")
	self.beardMenu:addChild(self.beardStubbleTickBox)
	self.beardMenu.stubbleTickBox = self.beardStubbleTickBox

	self.yOffset = self.yOffset + comboHgt + 10;
end

function CharacterCreationMain:onBeardTypeSelected(name)
	local desc = MainScreen.instance.desc
	desc:getHumanVisual():setBeardModel(name)
	CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
	self:disableBtn()
end