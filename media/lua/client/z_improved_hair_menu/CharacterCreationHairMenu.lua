--[[
	Here we intergrate the HairMenuPanel into the character creation menu.
]]

require("HairMenuPanel")

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

--To reduce vanilla mods we use the comboboxes to get and select hair styles
local base_CharacterCreationMain_disableBtn = CharacterCreationMain.disableBtn
function CharacterCreationMain:disableBtn()
	base_CharacterCreationMain_disableBtn(self)

	--Base sets these depending on gender, we don't need them at all.
	if self.beardTypeLbl and self.beardTypeCombo then
		self.beardTypeLbl:setVisible(false)
		self.beardTypeCombo:setVisible(false)
	end

	if self.hairTypeCombo and self.hairMenu then
		local hairs = {}
		for i=1,#self.hairTypeCombo.options do
			local info = {}
			info.id = self.hairTypeCombo:getOptionData(i):lower()
			info.display = self.hairTypeCombo:getOptionText(i)
	
			table.insert(hairs, info)
		end
	
		self.hairMenu:setHairList(hairs)
	end

	if self.beardTypeCombo and self.beardMenu then
		local vis = not MainScreen.instance.desc:isFemale()
		self.beardMenu:setVisible(vis)
		if vis then
			local hairs = {}
			for i=1,#self.beardTypeCombo.options do
				local info = {}
				info.id = self.beardTypeCombo:getOptionData(i):lower()
				info.display = self.beardTypeCombo:getOptionText(i)
		
				table.insert(hairs, info)
			end
			self.beardMenu:setHairList(hairs)
		end
	end
end

--#################
--## Hair Styles ##
--#################

local small_avatar_size = 46
local normal_avatar_size = 96

local function get_menu_parameters()
	local avatar_size = normal_avatar_size
	local grid_size = {rows = 2, cols = 3}
	
	if getCore():getScreenHeight() <= 768 then 
		avatar_size = small_avatar_size 
		grid_size = {rows = 1, cols = 5}
	end

	return avatar_size, grid_size
end

--[[
	Here's where we replace the original hair combo with our new menu.
	This does overwrite the original code but compared with rearranging the existing elements by hand this just seems easier.

	The only real changes made here are
	- Removal of labels
	- Hiding original combobox
	- Adding hair menu
	- Reparent hairColorBtn to hair menu
	- colorPickerHair mouse capture, this includes the onHairColorMouseDown changes below
		We do this to stop click through selecting different hairs under the color picker
]]
function CharacterCreationMain:createHairTypeBtn()
	
	local avatar_size, grid_size = get_menu_parameters()

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

	self.hairMenu = HairMenuPanel:new(self.xOffset, self.yOffset, avatar_size,avatar_size, grid_size.rows,grid_size.cols, 3, false)
	self.hairMenu:initialise()
	self.hairMenu:setDesc(MainScreen.instance.desc)
	self.hairMenu.onSelect = function(select_name)
		for i=1,#self.hairTypeCombo.options do
			local name = self.hairTypeCombo:getOptionData(i):lower()
			if name == select_name:lower() then
				--[[
					~~
					Leaving this here in case I have this problem in the future.
					This set me back a while, basically it's a matter of procedure.

						onHairTypeSelected(combo)
					Sets the hair model on the player.
						desc:getHumanVisual():setHairModel(hair)
					So the avatar panel has to be updated.
						CharacterCreationHeader.instance.avatarPanel:setSurvivorDesc(desc)
					This triggers the hair menu preview update to apply hair.
						ihm_update_preview_model()
						applyHair()
					So when this func ends and the combobox updates again the models hairstyle is set to the last hair in the menu. 
					This causes the combo to misalign with the shown hairstyle.

					To fix this we just have to set the hair type in the combo again before leaving the function.

					See the note in HairAvatar:applyHair() about why this is the case.
					~~

					RESOLVED:
					HairAvatar now restores the desc exiting so there is no need to correct for this anymore.
				]]
				self.hairTypeCombo.selected = i
				self:onHairTypeSelected(self.hairTypeCombo)
				break
			end
		end
	end
	self.characterPanel:addChild(self.hairMenu)

	self.yOffset = self.yOffset + self.hairMenu:getHeight() + 5;
	
	local xColor = 90;
	local fontHgt = FONT_HGT_SMALL
	
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
	-- local hairColorBtn = ISButton:new(self.xOffset+xColor, self.yOffset, 45, fontHgt, "", self, CharacterCreationMain.onHairColorMouseDown)
	local hairColorBtn = ISButton:new(self.hairMenu:getWidth() - 55, fontHgt/2 , 45, fontHgt, "", self, CharacterCreationMain.onHairColorMouseDown)

	hairColorBtn:initialise()
	hairColorBtn:instantiate()
	local color = hairColors1[1]
	hairColorBtn.backgroundColor = {r=color.r, g=color.g, b=color.b, a=1}
	-- self.characterPanel:addChild(hairColorBtn)
	self.hairMenu:addChild(hairColorBtn)
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
end

local base_CharacterCreationMain_onHairColorMouseDown = CharacterCreationMain.onHairColorMouseDown
function CharacterCreationMain:onHairColorMouseDown(button, x, y) 
	base_CharacterCreationMain_onHairColorMouseDown(self, button, x, y)
	self.colorPickerHair:setCapture(true)
end

local base_CharacterCreationMain_onHairTypeSelected = CharacterCreationMain.onHairTypeSelected
function CharacterCreationMain:onHairTypeSelected(combo)
	base_CharacterCreationMain_onHairTypeSelected(self, combo)
	self.hairMenu.selected_display = combo:getOptionText(combo.selected)
end


--##################
--## Beard Styles ##
--##################

function CharacterCreationMain:createBeardTypeBtn()
	local comboHgt = FONT_HGT_SMALL + 3 * 2

	local avatar_size, grid_size = get_menu_parameters()
	
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

	self.beardMenu = HairMenuPanel:new(self.xOffset, self.yOffset, avatar_size,avatar_size, 1,grid_size.cols, 3, true)
	self.beardMenu:initialise()
	self.beardMenu:setDesc(MainScreen.instance.desc)
	self.beardMenu.onSelect = function(select_name)
		for i=1,#self.beardTypeCombo.options do
			local name = self.beardTypeCombo:getOptionData(i):lower()
			if name == select_name:lower() then
				self.beardTypeCombo.selected = i
				self:onBeardTypeSelected(self.beardTypeCombo)
				break
			end
		end
	end
	self.characterPanel:addChild(self.beardMenu)

	self.yOffset = self.yOffset + self.hairMenu:getHeight() + 5;
end

local base_CharacterCreationMain_onBeardTypeSelected = CharacterCreationMain.onBeardTypeSelected
function CharacterCreationMain:onBeardTypeSelected(combo)
	base_CharacterCreationMain_onBeardTypeSelected(self, combo)
	self.beardMenu.selected_display = combo:getOptionText(combo.selected)
end