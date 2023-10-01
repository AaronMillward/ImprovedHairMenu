--[[
	This is the actual menu element.

	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]

local AvatarMenuPanel = require("z_improved_hair_menu/Components/AvatarMenuPanel.lua")
local HairAvatar = require("z_improved_hair_menu/Components/HairAvatar.lua")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local header_height = FONT_HGT_SMALL + 14

local function predicateAvatarIsSelectable(avatar)
	return avatar and avatar.selectable == true
end

local HairMenuPanel = AvatarMenuPanel:derive("HairMenuPanel")

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isModal)
	local o = AvatarMenuPanel.new(self, x, y, size_x, size_y, rows, cols, gap, isModal)
	setmetatable(o, self)
	self.__index = self
	o.avatarElementType = HairAvatar
	return o
end

--##################
--Controller Support
--##################

function HairMenuPanel:onJoypadDown(button, joypadData)
	AvatarMenuPanel.onJoypadDown(self, button, joypadData)
	if button == Joypad.XButton then
		if self.stubbleTickBox then self.stubbleTickBox:forceClick() end
	end
	if button == Joypad.YButton then
		if self.hairColorBtn then self.hairColorBtn:forceClick() end
	end
end

return HairMenuPanel