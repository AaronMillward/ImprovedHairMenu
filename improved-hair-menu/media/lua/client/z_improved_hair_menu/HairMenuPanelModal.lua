--[[
	A menu with an additional close button and event for the popout dialog in the character creation screen
]]

local base = HairMenuPanel
HairMenuPanelModal = base:derive("HairMenuPanelModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function HairMenuPanelModal:initialise()
	base.initialise(self)

	self.backgroundColor = {r=0,g=0,b=0,a=1}

	self.closeButton = ISButton:new(0,self.offset_y, self:getWidth(),FONT_HGT_SMALL*2, getText("UI_Close"), self, function()
		if self.onClose then self.onClose() end
	end)
	self.closeButton:initialise()
	self.closeButton:instantiate()
	self:addChild(self.closeButton)

	self:setHeight(self:getHeight() + self.closeButton:getHeight())
end
