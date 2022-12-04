--[[
	A menu with an additional close button and event for the popout dialog in the character creation screen
]]

local base = HairMenuPanel
HairMenuPanelModal = base:derive("HairMenuPanelModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function HairMenuPanelModal:close()
	if self.onClose then self.onClose() end
end

function HairMenuPanelModal:initialise()
	base.initialise(self)

	self.backgroundColor = {r=0,g=0,b=0,a=1}

	self.closeButton = ISButton:new(0,self.offset_y, self:getWidth(),FONT_HGT_SMALL*2, getText("UI_Close"), self, HairMenuPanelModal.close)
	self.closeButton:initialise()
	self.closeButton:instantiate()
	self:addChild(self.closeButton)

	self:setHeight(self:getHeight() + self.closeButton:getHeight())
end

function HairMenuPanelModal:onMouseUp(x,y)
	base.onMouseUp(self,x,y)
	if not (0 < x and 0 < y and x < self:getWidth() and y < self:getHeight()) then self:close() end
end