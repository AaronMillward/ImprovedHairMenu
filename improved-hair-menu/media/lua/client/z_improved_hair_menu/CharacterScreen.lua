--[[
	Here we add the menu to the in-game haircut menu

	To be as compatible as possible we read the options from the existing menu 
]]

--######################
--## Hair Menu Window ##
--######################

HairMenuPanelWindow = ISCollapsableWindowJoypad:derive("HairMenuPanelWindow")

function HairMenuPanelWindow:new(x, y, width, height, playerNum, char, hairlist, isbeard)
	local o = ISCollapsableWindowJoypad.new(self, x, y, width, height)
	o.char = char
	o.hairList = hairlist
	o.onSelect = nil
	o.isbeard = isbeard
	o.playerNum = playerNum
	return o
end

function HairMenuPanelWindow:render()
	ISCollapsableWindowJoypad.render(self)

	if JoypadState.players[self.playerNum+1] then
		if JoypadState.players[self.playerNum+1].focus == self then
			self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0);
			self:drawRectBorder(1, 1, self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
		end
	end
end

function HairMenuPanelWindow:createChildren()
	ISCollapsableWindowJoypad.createChildren(self)

	local th = self:titleBarHeight()
	self.resizable = false

	self.hairPanel = HairMenuPanel:new(0,th, 96,96, 2,3, 3, self.isbeard)
	self.hairPanel.showSelectedName = false
	self.hairPanel:initialise()
	self.hairPanel:setChar(self.char)
	self.hairPanel.onSelect = function(select_name)
		self.onSelect(select_name)
	end
	self.hairPanel:setHairList(self.hairList)
	self:addChild(self.hairPanel)

	self:setWidth(self.hairPanel:getWidth())
	self:setHeight(th + self.hairPanel:getHeight())
end

function HairMenuPanelWindow:close()
	self:setVisible(false)
	self:removeFromUIManager()
	if JoypadState.players[self.playerNum+1] then
		setJoypadFocus(self.playerNum, self.returnFocus)
	end
end

function HairMenuPanelWindow:onLoseJoypadFocus(joypadData)
	ISCollapsableWindowJoypad.onLoseJoypadFocus(self, joypadData)
	self.hairPanel:setJoypadFocused(false)
end

function HairMenuPanelWindow:onGainJoypadFocus(joypadData)
	ISCollapsableWindowJoypad.onGainJoypadFocus(self, joypadData)
	self.hairPanel:setJoypadFocused(true)
end

function HairMenuPanelWindow:onJoypadDown(button, joypadData)
	if button == Joypad.BButton then
		self:close()
	end
	self.hairPanel:onJoypadDown(button, joypadData)
	ISCollapsableWindowJoypad.onJoypadDown(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirLeft(joypadData)
	self.hairPanel:onJoypadDirLeft(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirLeft(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirRight(joypadData)
	self.hairPanel:onJoypadDirRight(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirRight(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirUp(joypadData)
	self.hairPanel:onJoypadDirUp(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirUp(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirDown(joypadData)
	self.hairPanel:onJoypadDirDown(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirDown(self, joypadData)
end

--#######################
--## ISCharacterScreen ##
--#######################

local ContextMenu_CutHairFor = string.gsub(getText("ContextMenu_CutHairFor"),"%%1","")
local ContextMenu_TieHair    = string.gsub(getText("ContextMenu_TieHair")   ,"%%1","")

local function predicateRazor(item)
	if item:isBroken() then return false end
	return item:hasTag("Razor") or item:getType() == "Razor"
end

local function predicateScissors(item)
	if item:isBroken() then return false end
	return item:hasTag("Scissors") or item:getType() == "Scissors"
end

local function predicateNotBroken(item)
	return not item:isBroken()
end

local function compareHairStyle(a, b)
	if a:getName() == "Bald" then return true end
	if b:getName() == "Bald" then return false end
	local nameA = getText("IGUI_Hair_" .. a:getName())
	local nameB = getText("IGUI_Hair_" .. b:getName())
	return not string.sort(nameA, nameB)
end

-- Modified vanilla function to produce `hairInfo` instead of context menu options
function ISCharacterScreen:hairMenu(button)
	local player = self.char;
	local context = ISContextMenu.get(self.char:getPlayerNum(), button:getAbsoluteX(), button:getAbsoluteY() + button:getHeight());
	local playerInv = player:getInventory()
	
	local currentHairStyle = getHairStylesInstance():FindMaleStyle(player:getHumanVisual():getHairModel())
	local hairStyles = getHairStylesInstance():getAllMaleStyles();
	if player:isFemale() then
		currentHairStyle = getHairStylesInstance():FindFemaleStyle(player:getHumanVisual():getHairModel())
		hairStyles = getHairStylesInstance():getAllFemaleStyles();
	end
	local hairList = {}
	for i=1,hairStyles:size() do
		table.insert(hairList, hairStyles:get(i-1))
	end
	table.sort(hairList, compareHairStyle)
	-- if we have hair long enough to trim it
	if currentHairStyle and currentHairStyle:getLevel() > 0 then
		local hairMenu = context

		local tie_options = {}
		local cut_options = {}
		
		if isDebugEnabled() then
			if player:isFemale() then
				hairMenu:addOption("[DEBUG] Grow Long2", player, ISCharacterScreen.onCutHair, "Long2", 10);
			else
				hairMenu:addOption("[DEBUG] Grow Fabian", player, ISCharacterScreen.onCutHair, "Fabian", 10);
			end
		end
		
		-- if we have an attached hair model but non nonAttachedHair reference, we get one
		if currentHairStyle:isAttachedHair() and not player:getVisual():getNonAttachedHair() then
			-- get the growReference of our current level, it'll become our nonAttachedHair, so if we decide to detach our hair (from a pony tail for ex.) we'll go back to this growReference
			for _,hairStyle in ipairs(hairList) do
				if hairStyle:getLevel() == currentHairStyle:getLevel() and hairStyle:isGrowReference() then
					player:getVisual():setNonAttachedHair(hairStyle:getName());
				end
			end
		end
		
		-- untie hair
		if player:getVisual():getNonAttachedHair() then
			hairMenu:addOption(getText("ContextMenu_UntieHair"), player, ISCharacterScreen.onCutHair, player:getVisual():getNonAttachedHair(), 100);
		end
		
		if not player:getVisual():getNonAttachedHair() then
			-- add attached hair
			for _,hairStyle in ipairs(hairList) do
				if hairStyle:getLevel() <= currentHairStyle:getLevel() and hairStyle:getName() ~= currentHairStyle:getName() and hairStyle:isAttachedHair() and hairStyle:getName() ~= "" then
					table.insert(tie_options, {
						id = hairStyle:getName(),
						display = getText("IGUI_Hair_" .. hairStyle:getName()),
						selected = false,
						requirements = nil,
						actionTime = 100, 
					})
				end
			end

			local hairList2 = {}
			-- add all "under level" we can find, any level 2 hair can be cut into a level 1
			for _,hairStyle in ipairs(hairList) do
				if not hairStyle:isAttachedHair() and not hairStyle:isNoChoose() and hairStyle:getLevel() < currentHairStyle:getLevel() and hairStyle:getName() ~= "" then
					table.insert(hairList2, hairStyle)
				end
			end
			-- add other special trim
			for i=1,currentHairStyle:getTrimChoices():size() do
				local styleId = currentHairStyle:getTrimChoices():get(i-1)
				local hairStyle = player:isFemale() and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
				if hairStyle then
					table.insert(hairList2, hairStyle)
				end
			end
			table.sort(hairList2, compareHairStyle)
			
			for _,hairStyle in ipairs(hairList2) do
				local info = {
					id = hairStyle:getName(),
					display = getText("IGUI_Hair_" .. hairStyle:getName()),
					selected = false,
					requirements = {},
					actionTime = 300,
				}

				if hairStyle:getName() == "Bald" then
					info.requirements.razor = player:getInventory():containsEvalRecurse(predicateRazor)
					info.requirements.scissors = player:getInventory():containsEvalRecurse(predicateScissors)
				elseif hairStyle:getName():contains("Mohawk") and hairStyle:getName() ~= "MohawkFlat" then
					info.requirements.hairgel = player:getInventory():containsTypeRecurse("Hairgel")
				elseif hairStyle:getName():contains("GreasedBack") then
					info.requirements.hairgel = player:getInventory():containsTypeRecurse("Hairgel")
				elseif player:getInventory():containsTagEvalRecurse("Scissors", predicateNotBroken) then
					info.requirements.scissors = true
				else
					info.requirements.scissors = false
				end

				table.insert(cut_options, info)
			end
		end

		if #tie_options > 0 then
			hairMenu:addOption(ContextMenu_TieHair, self, self.ihm_open_hair_menu, tie_options, ContextMenu_TieHair, false)
		end
		if #cut_options > 0 then
			hairMenu:addOption(ContextMenu_CutHairFor, self, self.ihm_open_hair_menu, cut_options, ContextMenu_CutHairFor, false)
		end
	else
		local hairMenu = context
		
		if isDebugEnabled() then
			if player:isFemale() then
				hairMenu:addOption("[DEBUG] Grow Long2", player, ISCharacterScreen.onCutHair, "Long2", 10);
			else
				hairMenu:addOption("[DEBUG] Grow Fabian", player, ISCharacterScreen.onCutHair, "Fabian", 10);
			end
		end
	end

	if JoypadState.players[self.playerNum+1] and context.numOptions > 0 then
		context.origin = self
		context.mouseOver = 1
		setJoypadFocus(self.playerNum, context)
	end
end

-- Modified vanilla function to produce `hairInfo` instead of context menu options
function ISCharacterScreen:beardMenu(button)
	local player = self.char;
	local context = ISContextMenu.get(self.char:getPlayerNum(), button:getAbsoluteX(), button:getAbsoluteY() + button:getHeight());
	local playerInv = player:getInventory()
	
	local currentBeardStyle = getBeardStylesInstance():FindStyle(player:getHumanVisual():getBeardModel())
	-- if we have a beard long enough to trim it
	if currentBeardStyle and currentBeardStyle:getLevel() > 0 then
		local beardMenu = context
		
		if isDebugEnabled() then
			beardMenu:addOption("[DEBUG] Grow Long", player, ISCharacterScreen.onTrimBeard, "Long");
		end

		local all_stlyes = {}
		local options = {}

		-- add all "under level" we can find, any level 2 beard/hair can be trim into a level 1
		local allBeard = getBeardStylesInstance():getAllStyles();
		for i=0, allBeard:size()-1 do
			local beardStyle = allBeard:get(i);
			if beardStyle:getLevel() < currentBeardStyle:getLevel() and beardStyle:getName() ~= "" then
				table.insert(all_stlyes, beardStyle)
			end
		end
		-- add other special trim (a goatee can become a moustache, etc.)
		for i=0, currentBeardStyle:getTrimChoices():size()-1 do
			table.insert(all_stlyes, currentBeardStyle:getTrimChoices():get(i))
		end

		table.insert(options, {
			id = "",
			display = "ContextMenu_TrimBeard",
			selected = false,
			requirements = {
				razor = player:getInventory():containsEvalRecurse(predicateRazor),
				scissors = player:getInventory():containsEvalRecurse(predicateScissors),
			},
		})
		for k,style in pairs(all_stlyes) do
			table.insert(options, {
				id = style:getName(),
				display = getText("IGUI_Beard_" .. style:getName()),
				selected = false,
				requirements = {
					razor = player:getInventory():containsEvalRecurse(predicateRazor),
					scissors = player:getInventory():containsEvalRecurse(predicateScissors),
				},
			})
		end

		if #options > 0 then
			local ContextMenu_TrimBeard_For = string.gsub(getText("ContextMenu_TrimBeard_For"),"%%1","")
			context:addOption(ContextMenu_TrimBeard_For, self, self.ihm_open_hair_menu, options, ContextMenu_TrimBeard_For, true)
		end
	else
		local beardMenu = context
		
		if isDebugEnabled() then
			beardMenu:addOption("[DEBUG] Grow Long", player, ISCharacterScreen.onTrimBeard, "Long");
		end
	end

	if JoypadState.players[self.playerNum+1] and context.numOptions > 0 then
		context.origin = self
		context.mouseOver = 1
		setJoypadFocus(self.playerNum, context)
	end
end

local opened_menu = nil

function ISCharacterScreen:ihm_open_hair_menu(hair_options, title, isBeard)
	local player = self.char
	local menu = HairMenuPanelWindow:new(200,200,400,400, self.playerNum, self.char, hair_options, isBeard)
	menu.returnFocus = self
	if isBeard == true then 
		menu.onSelect = function(selection)
			ISCharacterScreen.onTrimBeard(player, selection.id)
			menu:close()
			opened_menu = nil
		end
	else
		menu.onSelect = function(selection)
			ISCharacterScreen.onCutHair(player, selection.id, selection.actionTime)
			menu:close()
			opened_menu = nil
		end
	end

	menu:initialise()
	menu.title = title
	menu:addToUIManager()

	if opened_menu ~= nil then
		opened_menu:close()
	end
	opened_menu = menu
	setJoypadFocus(self.playerNum, opened_menu)
end