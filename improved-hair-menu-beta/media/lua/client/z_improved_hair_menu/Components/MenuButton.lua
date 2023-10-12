local MenuPanelButton = ISButton:derive("MenuPanelButton")

function MenuPanelButton:new(x, y, width, height, title, clicktarget, onclick, onmousedown, allowMouseUpProcessing, panelType, avatarSizeX, avatarSizeY, rows, cols, gap)
	local o = {}
	o = ISButton:new(x, y, width, height, title, clicktarget, onclick, onmousedown, allowMouseUpProcessing)
	setmetatable(o, self)
	self.__index = self
	o.isAvatarMenuButton = true
	o.attachedPanel = panelType:new(0,0, avatarSizeX, avatarSizeY, rows, cols, gap, true)
	o.attachedPanel.parentBtn = o -- This tells the panel it's part of a button.
	return o
end

function MenuPanelButton:initialise()
	self.attachedPanel:initialise()
	self.attachedPanel:setCapture(true)
end

return MenuPanelButton