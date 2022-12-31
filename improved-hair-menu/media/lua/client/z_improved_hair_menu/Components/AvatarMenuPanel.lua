--[[
	Base menu element for showing visual avatars.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local header_height = FONT_HGT_SMALL + 14

local function predicateAvatarIsSelectable(avatar)
	return avatar and avatar.selectable == true
end

local base = ISPanelJoypad
AvatarMenuPanel = base:derive("AvatarMenuPanel")

function AvatarMenuPanel:render()
	base.render(self)
	local height = getTextManager():MeasureFont(self.font);
	local x_off = self.pageRightButton:getRight()

	x_off = x_off + 10
	self:drawText(self.pageCurrent .. "/" .. self:getNumberOfPages(), x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

	x_off = x_off + 40

	if self.showSelectedName then
		self:drawText(self.selectedInfo.display or "error string", x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)
	end

	if self.joyfocus then
		self:drawRectBorder(0, -self:getYScroll(), self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0);
		self:drawRectBorder(1, 1-self:getYScroll(), self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
	end
end

function AvatarMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isModal)
	size_x = size_x or 96
	size_y = size_y or 96
	rows   = rows or 2
	cols   = cols or 3
	gap    = gap or 3
	isModal = isModal or false

	local o = base.new(self, x, y, (size_x * cols) + (gap * (cols-1)) , (size_y * rows) + (gap * (rows-1)) + header_height)
	o.isAvatarMenu = true -- Used by panels to determine element type.
	o.gridSizeX = size_x
	o.gridSizeY = size_y
	o.gridRows   = rows
	o.gridCols   = cols
	o.pageSize = (rows * cols)
	o.gap = gap
	o.isModal = isModal
	o.avatarList = {}
	o.info = {} -- HairInfo stored here
	o.pageCurrent = 1
	o.onSelect = nil -- Callback
	o.onClose = nil -- Callback
	o.showSelectedName = true
	o.joypadCursor = 1
	o.selectedInfo = {id = "", display = ""}
	o.avatarElementType = VisualAvatar
	return o
end

function AvatarMenuPanel:initialise()
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
		
		By loading the visual onto these avatars when switching pages we 
		can save some resources.
	 ]]

	self.offset_y = self.offset_y + 20
	for h=1,self.gridRows do
		for v=1,self.gridCols do
			local idx = ((h-1)*self.gridCols) + v
			
			local x = ((v-1) * self.gridSizeX) + (self.gap*(v-1))
			local y = (self.offset_y + ((h-1) * self.gridSizeY)) + (self.gap*(h-1))
			local avatar = self.avatarElementType:new(x, y, self.gridSizeX, self.gridSizeY)
			avatar:initialise()
			avatar:instantiate()
			avatar:setVisible(true)
			avatar.panelIndex = idx
			avatar.onSelect = function(inAvatar)
				self:onAvatarSelect(inAvatar)
			end

			avatar.onMouseMove = function(inAvatar, x, y)
				self.avatarElementType.onMouseMove(inAvatar, x, y)
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

				self:setCursor(inAvatar.panelIndex)
			end

			-- NOTE: If this avatar is the cursor then it should set let the panel know when it loses focus.
			avatar.onMouseMoveOutside = function(inAvatar, x, y)
				self.avatarElementType.onMouseMoveOutside(inAvatar, x, y)
				if self.joypadFocus then return end
				if self.joypadCursor == inAvatar.panelIndex then
					self:setCursor(nil)
				end
			end

			self:addChild(avatar)
			self.avatarList[idx] = avatar
		end
	end

	self.offset_y = self.offset_y + (self.gridRows * self.gridSizeY) + (self.gap * (self.gridRows-1))
end

function AvatarMenuPanel:onAvatarSelect(avatar)
	self:selectInfo(avatar.visualItem)
end

-- Silently updates the info selection, avoiding triggering the `onSelect` callback which can cause infinite loops.
function AvatarMenuPanel:setSelectedInfoIndex(index)
	self:setSelectedInfo(self.info[index])
end

-- Silently updates the info selection, avoiding triggering the `onSelect` callback which can cause infinite loops.
function AvatarMenuPanel:setSelectedInfo(info)
	-- XXX: This function has to allow for nil as beard menus might be initialized to nil if starting with a female character.
	if self.selectedInfo then self.selectedInfo.selected = false end
	self.selectedInfo = info
	if self.selectedInfo then self.selectedInfo.selected = true end
end

function AvatarMenuPanel:selectInfo(info)
	if type(info) == "number" then info = self.info[info] end
	if not info then print("AvatarMenuPanel:selectInfo(): info shouldn't be nil") return end
	self:setSelectedInfo(info)
	if self.onSelect then self.onSelect(info) end
end

function AvatarMenuPanel:setDesc(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setDesc(desc)
	end
end

function AvatarMenuPanel:setChar(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setChar(desc)
	end
end

function AvatarMenuPanel:applyVisual(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:applyVisual()
	end
end

function AvatarMenuPanel:setInfoTable(table)
	if type(table) ~= "table" then
		print("AvatarMenuPanel:setInfoTable() given a non-table value, ignoring and setting to blank table.")
		self.info = {}
	else
		self.info = table
	end
	self:showPage(1)
end

-- ##################
-- # Mouse Handling #
-- ##################

function AvatarMenuPanel:onMouseUp(x, y)
	if self.parentBtn then
		if self.parentBtn.disabled then return end
	end

	if self.joypadFocus then -- Don't use the mouse if we have joypad
		return
	end

	if self.isModal and not self:isMouseOver() then -- due to setCapture()
		self:close()
	end
end

function AvatarMenuPanel:close()
	if self.joyfocus then
		self.joyfocus.focus = self.resetFocusTo
	end
	if not self.parent then
		self:removeFromUIManager()
	end
	if self.onClose then self.onClose() end
end

-- #########
-- # Pages #
-- #########

function AvatarMenuPanel:onChangePageButton(button,x,y)
	if button.internal == "NEXT" then 
		self:changePage(1)
	elseif button.internal == "PREV" then 
		self:changePage(-1)
	end
end

function AvatarMenuPanel:getNumberOfPages()
	return math.ceil(#self.info / self.pageSize)
end

function AvatarMenuPanel:getCurrentPageSize()
	-- HACK: Only the last page has less than pageSize elements
	if self:getNumberOfPages() ~= self.pageCurrent then
		return self.pageSize
	else
		local s = #self.info % self.pageSize
		-- XXX: It can't actually be 0 or the page wouldn't exist. the page is just full.
		if s == 0 then s = self.pageSize end
		return s
	end
end

function AvatarMenuPanel:changePage(step)
	self:showPage(ImprovedHairMenu.math.wrap(self.pageCurrent + step, 1, self:getNumberOfPages()))
end

function AvatarMenuPanel:showPage(page_number)
	-- if page_number < 1 or page_number > self.pageCurrent then 
	-- 	return
	-- end

	-- if #self.avatarList == 0 then
	-- 	return
	-- end

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

function AvatarMenuPanel:getValidCursor(index)
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

function AvatarMenuPanel:setCursor(index)
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

function AvatarMenuPanel:makeCursorValid()
	self:setCursor(self:getValidCursor(self.joypadCursor))
end

--##################
--Controller Support
--##################

--[[ NOTE:
	We never actually get the joypad focus onto this element.
	Similar to how vanilla handles this (see `ISPanelJoypad`) we forward events from the panel to the element.
 ]]

function AvatarMenuPanel:ensureCursor()
	if not self.joypadCursor then
		self:setCursor(1)
	end
end

function AvatarMenuPanel:stepCursor(direction)
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
function AvatarMenuPanel:isNextDownOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor + self.gridCols])
end

-- Determines if the next joypad press should move outside the menu
function AvatarMenuPanel:isNextUpOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor - self.gridCols])
end

function AvatarMenuPanel:setJoypadFocused(focused, joypadData)
	-- XXX: This function has to at least exist as vanilla calls it on any element that doesn't directly recieve focus
	self.joypadFocus = focused
	if focused then
		self:setCursor(1)
	else
		self:setCursor(nil)
	end
end

function AvatarMenuPanel:onJoypadDown(button, joypadData)
	if button == Joypad.RBumper then self:changePage(1) end
	if button == Joypad.LBumper then self:changePage(-1) end
	if button == Joypad.AButton then
		self:ensureCursor()
		if self.avatarList[self.joypadCursor] then self.avatarList[self.joypadCursor]:select() end
	end
	if button == Joypad.BButton then
		self:close()
	end
end

function AvatarMenuPanel:onJoypadDirLeft(joypadData)  self:stepCursor(-1) end
function AvatarMenuPanel:onJoypadDirRight(joypadData) self:stepCursor(1)  end

function AvatarMenuPanel:onJoypadDirDown(joypadData)
	self:ensureCursor()
	local i = self.joypadCursor + self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end

function AvatarMenuPanel:onJoypadDirUp(joypadData)
	self:ensureCursor()
	local i = self.joypadCursor - self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end