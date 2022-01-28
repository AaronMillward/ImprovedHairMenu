--[[
	Here we add the menu to the in-game haircut menu

	To be as compatible as possible we read the options from the existing menu 
]]

--######################
--## Hair Menu Window ##
--######################

HairMenuPanelWindow = ISCollapsableWindowJoypad:derive("HairMenuPanelWindow")

function HairMenuPanelWindow:new(x, y, width, height, char, hairlist)
	local o = ISCollapsableWindowJoypad.new(self, x, y, width, height)
	o.char = char
	o.hairlist = hairlist
	o.onSelect = nil
	return o
end

function HairMenuPanelWindow:createChildren()
	ISCollapsableWindowJoypad.createChildren(self)

	local th = self:titleBarHeight()
	self.resizable = false

	self.hairPanel = HairMenuPanel:new(0,th, 96,96, 2,3, 3, false)
	self.hairPanel:initialise()
	self.hairPanel:setChar(self.char)
	self.hairPanel.onSelect = function(select_name)
		self.onSelect(select_name)
		self:close()
	end
	self.hairPanel:setHairList(self.hairlist)
	self:addChild(self.hairPanel)

	self:setWidth(self.hairPanel:getWidth())
	self:setHeight(th + self.hairPanel:getHeight())
end

function HairMenuPanelWindow:close()
	self:removeFromUIManager()
end

--#######################
--## ISCharacterScreen ##
--#######################

local cuthair_text = string.gsub(getText("ContextMenu_CutHairFor"),"%%1","")
local tiehair_text = string.gsub(getText("ContextMenu_TieHair"),"%%1","")

base_ISCharacterScreen_hairMenu = ISCharacterScreen.hairMenu
function ISCharacterScreen:hairMenu(button)
	base_ISCharacterScreen_hairMenu(self, button)

	local player = self.char;
	local context = getPlayerContextMenu(player:getPlayerNum());

	local delete_options = {}

	local hair_options_cut = {}
	local hair_options_tie = {}

	if #context.options ~= 0 then
		for k,v in ipairs(context.options) do
			if string.match(v.name, tiehair_text) then --Hair Ties
				if v.notAvailable == nil or v.notAvailable == false then
					table.insert(hair_options_tie, v)
				end
				table.insert(delete_options, k)
			elseif string.match(v.name, cuthair_text) then --Hair Cuts
				if v.notAvailable == nil or v.notAvailable == false then
					table.insert(hair_options_cut, v)
				end
				table.insert(delete_options, k)
			end
		end
	end

	--Replace Context Menu--

	for _,v in ipairs(delete_options) do
		context.options[v] = nil;
		context.numOptions = context.numOptions -1;
	end

	local new_options = {}
	for _,v in pairs(context.options) do
		table.insert(new_options, v)
	end
	context.options = new_options

	context:calcHeight()
	local y = button:getAbsoluteY() + button:getHeight()
	context:setSlideGoalY(y - 10, y) --Without this the context menu shrinks it's height but doesn't move down

	if #hair_options_cut > 0 then
		context:addOption(cuthair_text, player, ihm_open_hair_menu, hair_options_cut, cuthair_text)
	end
	if #hair_options_tie > 0 then
		context:addOption(tiehair_text, player, ihm_open_hair_menu, hair_options_tie, tiehair_text)
	end
end

function ihm_open_hair_menu(player, hair_options, title)
	local hairlist = {}
	for k,v in ipairs(hair_options) do
		local info = {}
		info.id = v.param1
		info.display = v.name
		table.insert(hairlist, info)
	end

	local menu = HairMenuPanelWindow:new(200,200,400,400, player, hairlist)
	menu.onSelect = function(selection)
		for k,v in ipairs(hair_options) do
			if v.param1 == selection then
				v.onSelect(v.target, v.param1, v.param2, v.param3, v.param4, v.param5, v.param6, v.param7, v.param8, v.param9, v.param10)
			end
		end
	end
	menu:initialise()
	menu.title = title
	menu:addToUIManager()
end