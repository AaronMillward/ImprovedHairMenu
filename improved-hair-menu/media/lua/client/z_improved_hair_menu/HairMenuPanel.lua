--[[
	This is where a bulk of the menu resides.
	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local header_height = FONT_HGT_SMALL + 14

local base = ISPanelJoypad
HairMenuPanel = base:derive("HairMenuPanel")

function HairMenuPanel:render()
	base.render(self)
	local height = getTextManager():MeasureFont(self.font);
	local x_off = self.pageRightButton:getRight()

	x_off = x_off + 10
	self:drawText(self.pageCurrent .. "/" .. #self.pages, x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

	x_off = x_off + 40

	self:drawText(self.selectedHairInfo.display or "", x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

end

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isBeard)
	size_x = size_x or 96
	size_y = size_y or 96
	rows   = rows or 2
	cols   = cols or 4
	gap    = gap or 3

	local o = base.new(self, x, y, (size_x * cols) + (gap * (cols-1)) , (size_y * rows) + (gap * (rows-1)) + header_height)
	o.isHairMenu = true -- Used by panels to determine type for passing in events
	o.gridSizeX = size_x
	o.gridSizeY = size_y
	o.gridRows   = rows
	o.gridCols   = cols
	o.pageSize = (rows * cols)
	o.gap = gap
	o.avatarList = {}
	o.pages = {} -- HairInfo stored here
	o.pageCurrent = 1
	o.onSelect = nil -- Callback
	o.isBeard = isBeard
	o.showNameOnHover = false
	o.joypadCursor = 1
	o.selectedHairInfo = {id = "", display = ""}
	o.hasInfo = false
	return o
end

function HairMenuPanel:initialise()
	local fnt_height = getTextManager():MeasureFont(self.font);

	self.offset_x = 0
	self.offset_y = fnt_height/2

	self.pageLeftButton = ISButton:new(5, self.offset_y, 15, 15, "", self, self.onChangePageButton)
	self.pageLeftButton.internal = "PREV"
	self.pageLeftButton:initialise()
	self.pageLeftButton:instantiate()
	self.pageLeftButton:setImage(getTexture("media/ui/ArrowLeft.png"))
	self:addChild(self.pageLeftButton)
	
	self.pageRightButton = ISButton:new(self.pageLeftButton:getRight() + 5, self.offset_y, 15, 15, "", self, self.onChangePageButton)
	self.pageRightButton.internal = "NEXT"
	self.pageRightButton:initialise()
	self.pageRightButton:instantiate()
	self.pageRightButton:setImage(getTexture("media/ui/ArrowRight.png"))
	self:addChild(self.pageRightButton)

	--Here we create the styles page, note that there is only one page of avatars. 
	--this is to reduce the number of 3d models by loading the hairs onto these avatars when switching pages

	self.offset_y = self.offset_y + 20
	for h=1,self.gridRows do
		for v=1,self.gridCols do
			local idx = ((h-1)*self.gridCols) + v
			
			local x = ((v-1) * self.gridSizeX) + (self.gap*(v-1))
			local y = (self.offset_y + ((h-1) * self.gridSizeY)) + (self.gap*(h-1))
			local hairAvatar = HairAvatar:new(x, y, self.gridSizeX, self.gridSizeY, self.isBeard)
			hairAvatar:initialise()
			hairAvatar:instantiate()
			hairAvatar:setVisible(true)
			hairAvatar.onSelect = function(hairAvatar)
				self:onAvatarSelect(hairAvatar)
			end
			local old_onMouseMove = hairAvatar.onMouseMove
			hairAvatar.onMouseMove = function(avatar, x, y)
				old_onMouseMove(avatar, x, y)

				if self.showNameOnHover then
					local x = self:getMouseX()
					local y = self:getMouseY()
					if avatar:containsPoint(x,y) then
						self.selectedDisplay = avatar.hairInfo.display
					end
				end
			end

			self:addChild(hairAvatar)
			self.avatarList[idx] = hairAvatar
		end
	end

	self.offset_y = self.offset_y + (self.gridRows * self.gridSizeY) + (self.gap * (self.gridRows-1))
end

function HairMenuPanel:onAvatarSelect(hairAvatar)
	if self.selectedHairInfo then self.selectedHairInfo.selected = false end
	self.selectedHairInfo = hairAvatar.hairInfo
	self.selectedHairInfo.selected = true
	if self.onSelect then self.onSelect(hairAvatar.hairInfo.id) end
end

function HairMenuPanel:setDesc(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setDesc(desc)
	end
end

function HairMenuPanel:setChar(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setChar(desc)
	end
end

function HairMenuPanel:applyHair(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:applyHair()
	end
end

function HairMenuPanel:setHairList(list)
	self.pages = {}
	local page_no = 1
	self.pages[page_no] = {}

	for i=1,#list do
		adj_i = i - ((page_no-1) * self.pageSize)
		
		if adj_i > self.pageSize then
			page_no = page_no + 1
			self.pages[page_no] = {}
			adj_i = i - ((page_no-1) * self.pageSize)
		end
		
		self.pages[page_no][adj_i] = list[i]
	end

	if #self.pages[page_no] < self.pageSize then
		for i=#self.pages[page_no]+1,self.pageSize do
			self.pages[page_no][i] = "DISABLED"
		end
	end

	if self.pageCurrent > #self.pages then 
		self.pageCurrent = #self.pages
	end
	self:showPage(self.pageCurrent)
	--TODO: Adding this seems to cause the unstable hair orderings
	-- self:onAvatarSelect(self.avatarList[1])
	self.hasInfo = true
end

function HairMenuPanel:onChangePageButton(button,x,y)
	if button.internal == "NEXT" then 
		self:changePage(1)
	elseif button.internal == "PREV" then 
		self:changePage(-1)
	end
end

function HairMenuPanel:changePage(step)
	self.pageCurrent = ImprovedHairMenu.math.wrap(self.pageCurrent + step, 1, #self.pages)
	self:showPage(self.pageCurrent)
end

function HairMenuPanel:showPage(page_number)
	if #self.pages < 1 then return end

	for i=1,self.pageSize do
		if self.pages[page_number][i] == "DISABLED" then 
			self.avatarList[i]:setVisible(false)
		else
			local hair_data = self.pages[page_number][i]
			self.avatarList[i]:setHairInfo(hair_data)
			self.avatarList[i]:applyHair()
			self.avatarList[i]:setVisible(true)
		end
	end
end

-- TODO: Use this on mouse over to highlight the hover
function HairMenuPanel:setAvatarAsCursor(avatar)
	for k,a in pairs(self.avatarList) do
		a.cursor = false
	end
	avatar.cursor = true
end

--##################
--Controller Support
--##################

--[[ 
	We never actually get the joypad focus onto this element.
	Similar to how vanilla handles this (see `ISPanelJoypad`) we forward events from the panel to the element.
 ]]

function HairMenuPanel:stepCursor(step)
	self.joypadCursor = ImprovedHairMenu.math.wrap(self.joypadCursor + step, 1, self.pageSize)
	self:setAvatarAsCursor(self.avatarList[self.joypadCursor])
end

function HairMenuPanel:setJoypadFocused(focused, joypadData)
	-- You can either ignore this here or make heavy changes to `ISPanelJoypad` to not call this function on hair menus, guess which I picked.
	return
end

function HairMenuPanel:onJoypadDown(button, joypadData)
	-- if not self.joypadFocused == true then return end
	if button == Joypad.RBumper then self:changePage(1) end
	if button == Joypad.LBumper then self:changePage(-1) end
	if button == Joypad.AButton then
		if self.avatarList[self.joypadCursor] then self:onAvatarSelect(self.avatarList[self.joypadCursor]) end
	end
	if button == Joypad.XButton then
		if self.stubbleTickBox then self.stubbleTickBox:forceClick() end
	end
	if button == Joypad.YButton then
		if self.hairColorBtn then self.hairColorBtn:forceClick() end
	end
end

function HairMenuPanel:onJoypadDirLeft(joypadData)  self:stepCursor(-1) end
function HairMenuPanel:onJoypadDirRight(joypadData) self:stepCursor(1)  end

function HairMenuPanel:onJoypadDirDown(joypadData)
	--[[ 
		We could add variables to determine when the next step down would move out of this element.
		e.g. `CursorAtBottom` then in the panel, ```if hairmenu.CursorAtBottom then dontsendevent()```
		same applies for `onJoypadDirUp`
	 ]]
end

-- function HairMenuPanel:onJoypadDirUp(joypadData)
-- end