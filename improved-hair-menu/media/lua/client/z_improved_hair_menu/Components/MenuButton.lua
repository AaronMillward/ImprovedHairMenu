AvatarMenuPanelButton = ISButton:derive("AvatarMenuPanelButton")

function AvatarMenuPanelButton:new(x, y, width, height, title, allowMouseUpProcessing, avatarSizeX, avatarSizeY, rows, cols, gap)
	local o = {}
	o = ISButton:new(x, y, width, height, title, nil, nil, nil, allowMouseUpProcessing)
	setmetatable(o, self)
    self.__index = self
	o.expanded = false
	o.attachedPanel = AvatarMenuPanel:new(0,0, avatarSizeX, avatarSizeY, rows, cols, gap)
	o.attachedPanel.parentBtn = o -- This enables the "attached" behaviours of the panel.
	return o
end

function AvatarMenuPanelButton:initialise()
	self.attachedPanel:initialise()
	self.attachedPanel:setCapture(true)
	self.attachedPanel:setAlwaysOnTop(true)
	self:setOnClick(function()
		if self.expanded then
			self:hideMenu()
		else
			self:showMenu()
		end
	end)
end

function AvatarMenuPanelButton:showMenu()
	self.expanded = true
	self.attachedPanel:setX(self:getAbsoluteX())
	self.attachedPanel:setY(self:getAbsoluteY() + self:getHeight())
	self.attachedPanel:addToUIManager()
end

function AvatarMenuPanelButton:hideMenu()
	self.expanded = false
	self.attachedPanel:removeFromUIManager()
end