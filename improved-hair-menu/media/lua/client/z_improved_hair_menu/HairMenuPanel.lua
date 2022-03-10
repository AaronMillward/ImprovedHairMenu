--[[
	This is where a bulk of the menu resides.
	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local header_height = FONT_HGT_SMALL + 14

local base = ISPanel
HairMenuPanel = base:derive("HairMenuPanel")

function HairMenuPanel:render()
	base.render(self)
	local height = getTextManager():MeasureFont(self.font);
	local x_off = self.pageRightButton:getRight()

	x_off = x_off + 10
	self:drawText(self.pageCurrent .. "/" .. #self.pages, x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

	x_off = x_off + 40
	self:drawText(self.selectedDisplay, x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

end

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isBeard)
	size_x = size_x or 96
	size_y = size_y or 96
	rows   = rows or 2
	cols   = cols or 4
	gap    = gap or 3

	local o = base.new(self, x, y, (size_x * cols) + (gap * (cols-1)) , (size_y * rows) + (gap * (rows-1)) + header_height)
	o.gridSizeX = size_x
	o.gridSizeY = size_y
	o.gridRows   = rows
	o.gridCols   = cols
	o.pageSize = (rows * cols)
	o.gap = gap
	o.avatarList = {}
	o.pages = {}
	o.pageCurrent = 1
	o.onSelect = nil
	o.selectedDisplay = ""
	o.isBeard = isBeard
	o.showNameOnHover = false
	return o
end

function HairMenuPanel:initialise()
	local fnt_height = getTextManager():MeasureFont(self.font);

	self.offset_x = 0
	self.offset_y = fnt_height/2

	self.pageLeftButton = ISButton:new(5, self.offset_y, 15, 15, "", self, self.onChangePage)
	self.pageLeftButton.internal = "PREV"
	self.pageLeftButton:initialise()
	self.pageLeftButton:instantiate()
	self.pageLeftButton:setImage(getTexture("media/ui/ArrowLeft.png"))
	self:addChild(self.pageLeftButton)
	
	self.pageRightButton = ISButton:new(self.pageLeftButton:getRight() + 5, self.offset_y, 15, 15, "", self, self.onChangePage)
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
				self.selectedDisplay = hairAvatar.hairInfo.display
				if self.onSelect then self.onSelect(hairAvatar.hairInfo.id) end
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
end

function HairMenuPanel:onChangePage(button,x,y)
	if button.internal == "NEXT" then 
		self.pageCurrent = self.pageCurrent + 1
	elseif button.internal == "PREV" then 
		self.pageCurrent = self.pageCurrent - 1
	end

	if self.pageCurrent > #self.pages then self.pageCurrent = #self.pages end
	if self.pageCurrent < 1 then self.pageCurrent = 1 end

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