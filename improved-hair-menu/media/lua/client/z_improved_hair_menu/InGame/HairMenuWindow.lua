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