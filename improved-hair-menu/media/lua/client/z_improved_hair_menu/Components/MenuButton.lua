MenuPanelButton = ISButton:derive("MenuPanelButton")

function MenuPanelButton:new(x, y, width, height, title, allowMouseUpProcessing, panelType, avatarSizeX, avatarSizeY, rows, cols, gap, isCentered)
	local o = {}
	o = ISButton:new(x, y, width, height, title, nil, nil, nil, allowMouseUpProcessing)
	setmetatable(o, self)
    self.__index = self
	o.expanded = false
	o.attachedPanel = panelType:new(0,0, avatarSizeX, avatarSizeY, rows, cols, gap, true)
	o.attachedPanel.parentBtn = o -- This tells the panel it's part of a button.
	o.isCentered = isCentered
	return o
end

function MenuPanelButton:initialise()
	self.attachedPanel:initialise()
	self.attachedPanel:setCapture(true)
	self.attachedPanel.onWantsClose = function()
		self:hideMenu()
	end
	self:setOnClick(function()
		if self.expanded then
			self:hideMenu()
		else
			self:showMenu()
		end
	end)
end

function MenuPanelButton:showMenu()
	self.expanded = true
	if self.isCentered then
		self.attachedPanel:setX( (getCore():getScreenWidth()/2) - (self.attachedPanel:getWidth()/2) )
		self.attachedPanel:setY( (getCore():getScreenHeight()/2) - (self.attachedPanel:getHeight()/2) )
	else
		self.attachedPanel:setX(self:getAbsoluteX())
		self.attachedPanel:setY(self:getAbsoluteY() + self:getHeight())
	end
	self.attachedPanel:addToUIManager()
end

function MenuPanelButton:hideMenu()
	self.expanded = false
	self.attachedPanel:removeFromUIManager()
end