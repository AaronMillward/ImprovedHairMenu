--[[
	Here we intergrate the HairMenuPanel into the character creation menu.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local original_CharacterCreationHeader_create = CharacterCreationHeader.create
function CharacterCreationHeader:create()
	original_CharacterCreationHeader_create(self)
	
	-- This gives us a hook for when the user changes the model
	local setSurvivorDesc_old = self.avatarPanel.setSurvivorDesc
	function self.avatarPanel:setSurvivorDesc(desc)
		setSurvivorDesc_old(self, desc)
		CharacterCreationMain.instance:ihm_update_preview_model(desc)
	end
end

function CharacterCreationMain:ihm_update_preview_model(desc)
	if self.hairMenu then 
		self.hairMenu:applyHair()
	end

	if self.beardMenu then 
		self.beardMenu:applyHair()
	end
end

local base_CharacterCreationMain_disableBtn = CharacterCreationMain.disableBtn
function CharacterCreationMain:disableBtn()

	--##################
	--Generate Hair List
	--##################

	--[[ 
		Originally we read this data out of the combobox but this is making things increasingly difficult.
		With this change the menu can become indepenedent of the original UI.
	 ]]
	
	local desc = MainScreen.instance.desc
	if self.female ~= desc:isFemale() or CharacterCreationMain.forceUpdateCombo then
		-- Don't do this, the vanilla function will handle it.
		-- CharacterCreationMain.forceUpdateCombo = false;

		-- Replaces "self.female" in this block as vanilla also does this same sex switch check. so if we overwrite it here it will break vanilla.
		local female = desc:isFemale()
		
		-- Get Hair Info
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
				})
			end
		end

		if self.hairMenu then self.hairMenu:setHairList(infoHair) end
		
		-- Get Beard Info
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
				})
			end
			if self.beardMenu then self.beardMenu:setHairList(infoBeard) end
		end
	end

	--##################
	--/Generate Hair List
	--##################

	--[[ 
		When the game updates disableBtn will break due to elements changing causing calls to nil in disableBtn.
		If we catch the error here, it will not propegate and break the whole main menu.
	 ]]
	pcall(base_CharacterCreationMain_disableBtn, self)

	--Base sets these depending on gender, we don't need them at all.
	if self.beardTypeLbl    then self.beardTypeLbl:setVisible(false)    end
	if self.beardTypeCombo  then self.beardTypeCombo:setVisible(false)  end
	if self.hairStubbleLbl  then self.hairStubbleLbl:setVisible(false)  end
	if self.beardStubbleLbl then self.beardStubbleLbl:setVisible(false) end

	if self.hairMenu then
		-- hairMenu's onSelect triggers disableBtn so we need to set the selection silently to avoid an infinite loop
		self.hairMenu:setSelectedInfo(self.hairMenu.info[self.hairTypeCombo.selected])
	end

	if self.beardMenu then
		local vis = not MainScreen.instance.desc:isFemale()
		self.beardMenu:setVisible(vis)
		if self.beardMenuButton then self.beardMenuButton:setVisible(vis) end
		self.beardMenu:setSelectedInfo(self.beardMenu.info[self.beardTypeCombo.selected])
	end
end

local function is_low_res()
	--[[
		786 is what I've seen in a lot of vanilla code,
		I'm not certain of its significance but I think it's a common laptop resolution

		2022-03-10 Changed to 900 - Someone said the beard menu still appears offscreen at 900px resolution
	]]
	return (getCore():getScreenHeight() <= 900)
end

--#################
--## Hair Styles ##
--#################

--[[
	Here's where we replace the original hair combo with our new menu.
	This does overwrite the original code but compared with rearranging the existing elements by hand this just seems easier.

	The only real changes made here are
	- Remove labels
	- Hide original combobox
	- Add hair menu
	- Reparent hairColorBtn to hair menu
	- colorPickerHair mouse capture, this includes the onHairColorMouseDown changes below
		We do this to stop click through selecting different hairs under the color picker
]]
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
	
	self.hairTypeCombo = ISComboBox:new(self.xOffset+90, self.yOffset, self.comboWid, comboHgt, self, CharacterCreationMain.onHairTypeSelected);
	self.hairTypeCombo:initialise();
	self.characterPanel:addChild(self.hairTypeCombo)
	self.hairTypeCombo:setVisible(false);
	self.hairType = 0
	--Don't increment the y offset here, the combo is invisible and the menu takes its place

	local panelType = nil

	if use_modal then
		panelType = HairMenuPanelModal
	else
		panelType = HairMenuPanel
	end

	local menu_size = ImprovedHairMenu.settings:get_menu_size(false)

	self.hairMenu = panelType:new(self.xOffset, self.yOffset, avatar_size,avatar_size, menu_size.cols,menu_size.rows, 3, false)
	self.hairMenu.onSelect = function(info) -- INFO: Taken from onHairTypeSelected which requires the combobox as a parameter so obviously can't be used here.
		local desc = MainScreen.instance.desc
		self.hairType = 1 -- XXX: I don't really know if this is important or not but this seems to work.
		desc:getHumanVisual():setHairModel(info.id) -- TODO: vanilla also allows this to be nil
		CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
		self:disableBtn()
	end
	self.hairMenu:initialise()
	self.hairMenu:setDesc(MainScreen.instance.desc)
	
	if use_modal then
		local function showMenu(target)
			target.hairMenuButton.expanded = true
			target.hairMenuButton.attachedMenu = target.hairMenu
			target:removeChild(target.hairMenu)
			target:addChild(target.hairMenu)
			target.hairMenu:setX( (target:getWidth()/2) - (target.hairMenu:getWidth()/2) )
			target.hairMenu:setY( (target:getHeight()/2) - (target.hairMenu:getHeight()/2) )
			target.hairMenu:setCapture(true)
		end

		self.hairMenu.onClose = function()
			self:removeChild(self.hairMenu)
			self.hairMenu:setCapture(false)
			self.hairMenuButton.expanded = false
		end

		self.hairMenuButton = ISButton:new(self.xOffset, self.yOffset, 90, FONT_HGT_SMALL*2, getText("IGUI_Open"), self, showMenu)
		self.hairMenuButton:initialise()
		self.hairMenuButton:instantiate()
		self.hairMenuButton.isHairMenuButton = true
		self.hairMenuButton.isButton = nil -- We don't want this button to be picked up by the vanilla joypad functions
		self.hairMenuButton.expanded = false
		self.characterPanel:addChild(self.hairMenuButton)

		self.yOffset = self.yOffset + self.hairMenuButton:getHeight() + 5;
	else
		self.characterPanel:addChild(self.hairMenu)
		self.yOffset = self.yOffset + self.hairMenu:getHeight() + 5;
	end
	
	
	local xColor = 90;
	
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
	-- self.characterPanel:addChild(hairColorBtn)
	self.hairMenu:addChild(hairColorBtn)
	self.hairMenu.hairColorBtn = hairColorBtn
	self.hairColorButton = hairColorBtn
	
	self.colorPickerHair = ISColorPicker:new(0, 0, nil)
	self.colorPickerHair:initialise()
	self.colorPickerHair.keepOnScreen = true
	self.colorPickerHair.pickedTarget = self
	self.colorPickerHair.resetFocusTo = self.characterPanel
	self.colorPickerHair:setColors(hairColors1, math.min(#hairColors1, 10), math.ceil(#hairColors1 / 10))

	--We override these picker functions so that we can disable mouse capture
	local colorPickerHair_picked = self.colorPickerHair.picked
	function self.colorPickerHair:picked(hide)
		colorPickerHair_picked(self, hide)
		self:setCapture(false)
	end
	local colorPickerHair_picked2 = self.colorPickerHair.picked2
	function self.colorPickerHair:picked2(hide)
		colorPickerHair_picked2(self, hide)
		self:setCapture(false)
	end

	-- ----------------------
	-- -- STUBBLE
	-- ----------------------
	self.hairStubbleLbl = ISLabel:new(self.xOffset, self.yOffset + FONT_HGT_SMALL, comboHgt, getText("UI_Stubble"), 1, 1, 1, 1, UIFont.Small);
	self.hairStubbleLbl:initialise();
	self.hairStubbleLbl:instantiate();
	self.characterPanel:addChild(self.hairStubbleLbl);
	self.yOffset = self.yOffset + FONT_HGT_SMALL

	self.hairStubbleTickBox = ISTickBox:new(self.hairMenu:getWidth() - 55 - FONT_HGT_SMALL - 8, comboHgt/4, FONT_HGT_SMALL-2, FONT_HGT_SMALL-2, "", self, CharacterCreationMain.onShavedHairSelected);
	self.hairStubbleTickBox:initialise()
	self.hairStubbleTickBox:addOption("")
	self.hairStubbleTickBox.tooltip = getText("UI_Stubble")
	self.hairMenu:addChild(self.hairStubbleTickBox)
	self.hairMenu.stubbleTickBox = self.hairStubbleTickBox
end

local base_CharacterCreationMain_onHairColorMouseDown = CharacterCreationMain.onHairColorMouseDown
function CharacterCreationMain:onHairColorMouseDown(button, x, y) 
	base_CharacterCreationMain_onHairColorMouseDown(self, button, x, y)
	self.colorPickerHair:setCapture(true)
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
	
	self.beardTypeCombo = ISComboBox:new(self.xOffset+90, self.yOffset, self.comboWid, comboHgt, self, CharacterCreationMain.onBeardTypeSelected);
	self.beardTypeCombo:initialise();
	--	self.beardTypeCombo:instantiate();
	self.beardTypeCombo:setVisible(false);
	self.characterPanel:addChild(self.beardTypeCombo)


	--The following is copied from above, it only appears in these two places so I'm not making it a function

	local panelType = nil
	if use_modal then
		panelType = HairMenuPanelModal
	else
		panelType = HairMenuPanel
	end
	local menu_size = ImprovedHairMenu.settings:get_menu_size(true)
	self.beardMenu = panelType:new(self.xOffset, self.yOffset, avatar_size,avatar_size, menu_size.cols,menu_size.rows, 3, true)
	self.beardMenu.onSelect = function(info) -- INFO: See `hairMenu` `onSelect` for more info
		local desc = MainScreen.instance.desc
		desc:getHumanVisual():setBeardModel(info.id)
		CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
		self:disableBtn()
	end
	self.beardMenu:initialise()
	self.beardMenu:setDesc(MainScreen.instance.desc)
	
	if use_modal then
		local function showMenu(target)
			target.beardMenuButton.expanded = true
			target.beardMenuButton.attachedMenu = target.beardMenu
			target:removeChild(target.beardMenu)
			target:addChild(target.beardMenu)
			target.beardMenu:setX( (target:getWidth()/2) - (target.beardMenu:getWidth()/2) )
			target.beardMenu:setY( (target:getHeight()/2) - (target.beardMenu:getHeight()/2) )
			target.beardMenu:setCapture(true)
		end

		self.beardMenu.onClose = function()
			self:removeChild(self.beardMenu)
			self.beardMenu:setCapture(false)
			self.beardMenuButton.expanded = false
		end

		self.beardMenuButton = ISButton:new(self.xOffset, self.yOffset, 90, FONT_HGT_SMALL*2, getText("IGUI_Open"), self, showMenu)
		self.beardMenuButton:initialise()
		self.beardMenuButton:instantiate()
		self.beardMenuButton.isHairMenuButton = true
		self.beardMenuButton.isButton = nil -- We don't want this button to be picked up by the vanilla joypad functions
		self.beardMenuButton.expanded = false
		self.characterPanel:addChild(self.beardMenuButton)

		self.yOffset = self.yOffset + self.beardMenuButton:getHeight() + 5;
	else
		self.characterPanel:addChild(self.beardMenu)
		self.yOffset = self.yOffset + self.beardMenu:getHeight() + 5;
	end

	----------------------
	-- STUBBLE
	----------------------
	self.beardStubbleLbl = ISLabel:new(self.xOffset+70, self.yOffset, comboHgt, getText("UI_Stubble"), 1, 1, 1, 1, UIFont.Small);
	self.beardStubbleLbl:initialise();
	self.beardStubbleLbl:instantiate();
	self.characterPanel:addChild(self.beardStubbleLbl);

	self.beardStubbleTickBox = ISTickBox:new(self.beardMenu:getWidth() - FONT_HGT_SMALL - 10, comboHgt/4, FONT_HGT_SMALL-2, FONT_HGT_SMALL-2, "", self, CharacterCreationMain.onBeardStubbleSelected);
	self.beardStubbleTickBox:initialise()
	self.beardStubbleTickBox:addOption("")
	self.beardStubbleTickBox.tooltip = getText("UI_Stubble")
	self.beardMenu:addChild(self.beardStubbleTickBox)
	self.beardMenu.stubbleTickBox = self.beardStubbleTickBox

	self.yOffset = self.yOffset + comboHgt + 10;
end