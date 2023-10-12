--[[
	This is the actual menu element.

	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local header_height = FONT_HGT_SMALL + 14

local function predicateAvatarIsSelectable(avatar)
	return avatar and avatar.selectable == true
end

local base = ISPanelJoypad
HairMenuPanel = base:derive("HairMenuPanel")

function HairMenuPanel:render()
	base.render(self)
	local height = getTextManager():MeasureFont(self.font);
	local x_off = self.pageRightButton:getRight()

	x_off = x_off + 10
	self:drawText(self.pageCurrent .. "/" .. self:getNumberOfPages(), x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

	x_off = x_off + 40

	if self.showSelectedName then
		self:drawText(self.selectedHairInfo.display or "error string", x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)
	end
end

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isBeard)
	size_x = size_x or 96
	size_y = size_y or 96
	rows   = rows or 2
	cols   = cols or 4
	gap    = gap or 3

	local o = base.new(self, x, y, (size_x * cols) + (gap * (cols-1)) , (size_y * rows) + (gap * (rows-1)) + header_height)
	o.isHairMenu = true -- Used by panels to determine element type.
	o.gridSizeX = size_x
	o.gridSizeY = size_y
	o.gridRows   = rows
	o.gridCols   = cols
	o.pageSize = (rows * cols)
	o.gap = gap
	o.avatarList = {}
	o.info = {} -- HairInfo stored here
	o.pageCurrent = 1
	o.onSelect = nil -- Callback
	o.isBeard = isBeard
	o.showSelectedName = true
	o.joypadCursor = 1
	o.selectedHairInfo = {id = "", display = ""}
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

	--[[ NOTE:
		Here we create the page, there is only one page of avatars to reduce
		the number of 3d models.
		
		By loading the hairs onto these avatars when switching pages we 
		can save some resources.
	 ]]

	self.offset_y = self.offset_y + 20
	for h=1,self.gridRows do
		for v=1,self.gridCols do
			local idx = ((h-1)*self.gridCols) + v
			
			local x = ((v-1) * self.gridSizeX) + (self.gap*(v-1))
			local y = (self.offset_y + ((h-1) * self.gridSizeY)) + (self.gap*(h-1))
			local hairAvatar = HairAvatar:new(x, y, self.gridSizeX, self.gridSizeY)
			hairAvatar:initialise()
			hairAvatar:instantiate()
			hairAvatar:setVisible(true)
			hairAvatar.panelIndex = idx
			hairAvatar.onSelect = function(hairAvatar)
				self:onAvatarSelect(hairAvatar)
			end

			hairAvatar.onMouseMove = function(avatar, x, y)
				HairAvatar.onMouseMove(avatar, x, y)
				--[[ NOTE:XXX:
					There used to be a `containsPoint` check here. it only worked on the main menu or in-game depending on who called `containsPoint`
					but `onMouseMove` only gets called if the mouse is inside the element anyway so it already fulfilled the purpose of the check.
				 ]]

				--[[ XXX:
					It seems like it's not possible to make dragging not change the tooltip. I think the onMouseMove functions
					aren't being called correctly leading to weird behaviour.
					
					ISUI3DModel has this comment in the onMouseMoveOutside function
					"This shouldn't happen, but the way setCapture() works is broken."
					
					So I don't think this one is on me.
				 ]]

				self:setCursor(avatar.panelIndex)
			end

			-- NOTE: If this avatar is the cursor then it should set let the panel know when it loses focus.
			hairAvatar.onMouseMoveOutside = function(avatar, x, y)
				HairAvatar.onMouseMoveOutside(avatar, x, y)
				if self.joypadFocus then return end
				if self.joypadCursor == avatar.panelIndex then
					self:setCursor(nil)
				end
			end

			self:addChild(hairAvatar)
			self.avatarList[idx] = hairAvatar
		end
	end

	self.offset_y = self.offset_y + (self.gridRows * self.gridSizeY) + (self.gap * (self.gridRows-1))
end

function HairMenuPanel:onAvatarSelect(hairAvatar)
	self:selectInfo(hairAvatar.visualItem)
end

-- Silently updates the hair info selection, avoiding triggering the `onSelect` callback which can cause infinite loops.
function HairMenuPanel:setSelectedInfo(hairInfo)
	-- XXX: This function has to allow for nil as beard menus might be initialized to nil if starting with a female character.
	if self.selectedHairInfo then self.selectedHairInfo.selected = false end
	self.selectedHairInfo = hairInfo
	if self.selectedHairInfo then self.selectedHairInfo.selected = true end
end

function HairMenuPanel:selectInfo(hairInfo)
	if type(hairInfo) == "number" then hairInfo = self.info[hairInfo] end
	if not hairInfo then print("HairMenuPanel:selectInfo(): info shouldn't be nil") return end
	self:setSelectedInfo(hairInfo)
	if self.onSelect then self.onSelect(hairInfo) end
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

function HairMenuPanel:applyVisual(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:applyVisual()
	end
end

function HairMenuPanel:setHairList(list)
	if type(list) ~= "table" then
		print("HairMenuPanel:setHairList() given a non-table value, ignoring and setting to blank table.")
		self.info = {}
	else
		self.info = list
	end
	self:showPage(1)
end

-- #########
-- # Pages #
-- #########

function HairMenuPanel:onChangePageButton(button,x,y)
	if button.internal == "NEXT" then 
		self:changePage(1)
	elseif button.internal == "PREV" then 
		self:changePage(-1)
	end
end

function HairMenuPanel:getNumberOfPages()
	return math.ceil(#self.info / self.pageSize)
end

function HairMenuPanel:getCurrentPageSize()
	-- HACK: Only the last page has less than pageSize elements
	if self:getNumberOfPages() ~= self.pageCurrent then
		return self.pageSize
	else
		return #self.info % self.pageSize
	end
end

function HairMenuPanel:changePage(step)
	self:showPage(ImprovedHairMenu.math.wrap(self.pageCurrent + step, 1, self:getNumberOfPages()))
end

function HairMenuPanel:showPage(page_number)
	self.pageCurrent = page_number
	for i=1,self.pageSize do
		local info = self.info[((page_number-1) * self.pageSize) + i]
		if info then 
			self.avatarList[i].selectable = true
			self.avatarList[i]:setVisualItem(info)
			self.avatarList[i]:applyVisual()
			self.avatarList[i]:setVisible(true)
		else
			self.avatarList[i].selectable = false
			self.avatarList[i]:setVisible(false)
		end
	end

	if self.joypadFocus then
		self:makeCursorValid()
	else
		self:setCursor(nil)
	end
end

-- ##########
-- # Cursor #
-- ##########

function HairMenuPanel:getValidCursor(index)
	-- NOTE: index 1 will always be valid as the page wouldn't exist if there wasn't at least 1 element.
	local cursor = ImprovedHairMenu.math.clamp(index, 1, self.pageSize)
	if not self.avatarList[cursor].selectable == true then 
		for i=0,self.pageSize do
			local new_cursor = ImprovedHairMenu.math.wrap(cursor - i, 1, self.pageSize) -- NOTE: Move downwards as avatars are seqential.
			if self.avatarList[new_cursor].selectable == true then 
				cursor = new_cursor
				break
			end
		end
	end
	return cursor
end

function HairMenuPanel:setCursor(index)
	if self.joypadCursor then
		-- NOTE: Clear old cursor. this should avoid a double cursor as long as everyone uses this function.
		self.avatarList[self.joypadCursor]:setCursor(false)
	end

	if not index then
		self.joypadCursor = nil
		return
	end

	self.joypadCursor = self:getValidCursor(index)
	self.avatarList[self.joypadCursor]:setCursor(true)
end

function HairMenuPanel:makeCursorValid()
	self:setCursor(self:getValidCursor(self.joypadCursor))
end

--##################
--Controller Support
--##################

--[[ NOTE:
	We never actually get the joypad focus onto this element.
	Similar to how vanilla handles this (see `ISPanelJoypad`) we forward events from the panel to the element.
 ]]

function HairMenuPanel:ensureCursor()
	if not self.joypadCursor then
		self:setCursor(1)
	end
end

function HairMenuPanel:stepCursor(direction)
	self:ensureCursor()

	local direction = ImprovedHairMenu.math.sign(direction)

	-- NOTE: `stepCursor` is only called by joypad events we don't need any flags for joypad usage
	if direction ~= 0 then
		if self.joypadCursor + direction > self:getCurrentPageSize() then
			self:changePage(1)
			self:setCursor(1)
			return
		elseif self.joypadCursor + direction < 1 then
			self:changePage(-1)
			self:setCursor(self.pageSize)
			return
		end
	end

	self:setCursor(self.joypadCursor + direction)
end

-- Determines if the next joypad press should move outside the menu
function HairMenuPanel:isNextDownOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor + self.gridCols])
end

-- Determines if the next joypad press should move outside the menu
function HairMenuPanel:isNextUpOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor - self.gridCols])
end

function HairMenuPanel:setJoypadFocused(focused, joypadData)
	-- XXX: This function has to at least exist as vanilla calls it on any element that doesn't directly recieve focus
	self.joypadFocus = focused
	if focused then
		self:setCursor(1)
	else
		self:setCursor(nil)
	end
end

function HairMenuPanel:onJoypadDown(button, joypadData)
	if button == Joypad.RBumper then self:changePage(1) end
	if button == Joypad.LBumper then self:changePage(-1) end
	if button == Joypad.AButton then
		self:ensureCursor()
		if self.avatarList[self.joypadCursor] then self.avatarList[self.joypadCursor]:select() end
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
	self:ensureCursor()
	local i = self.joypadCursor + self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end

function HairMenuPanel:onJoypadDirUp(joypadData)
	self:ensureCursor()
	local i = self.joypadCursor - self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end