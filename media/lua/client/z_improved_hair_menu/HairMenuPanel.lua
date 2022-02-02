--[[
	This is where a bulk of the menu resides.
	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]


require("HairAvatar")

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
	self:drawText(self.page_current .. "/" .. #self.pages, x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

	x_off = x_off + 40
	self:drawText(self.selected_display, x_off, height/2, 0.9, 0.9, 0.9, 0.9, UIFont.Small)

end

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isBeard)
	size_x = size_x or 96
	size_y = size_y or 96
	rows   = rows or 2
	cols   = cols or 4
	gap    = gap or 3

	local o = base.new(self, x, y, (size_x * cols) + (gap * (cols-1)) , (size_y * rows) + (gap * (rows-1)) + header_height)
	o.hair_size_x = size_x
	o.hair_size_y = size_y
	o.hair_rows   = rows
	o.hair_cols   = cols
	o.hair_page_size = (rows * cols)
	o.gap = gap
	o.avatarList = {}
	o.pages = {}
	o.page_current = 1
	o.onSelect = nil
	o.selected_display = ""
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
	for h=1,self.hair_rows do
		for v=1,self.hair_cols do
			local idx = ((h-1)*self.hair_cols) + v
			
			local x = ((v-1) * self.hair_size_x) + (self.gap*(v-1))
			local y = (self.offset_y + ((h-1) * self.hair_size_y)) + (self.gap*(h-1))
			local hairAvatar = HairAvatar:new(x, y, self.hair_size_x, self.hair_size_y, self.isBeard)
			hairAvatar:initialise()
			hairAvatar:instantiate()
			hairAvatar:setVisible(true)
			hairAvatar.onSelect = function(hairAvatar)
				self.selected_display = hairAvatar.hair_display
				if self.onSelect then self.onSelect(hairAvatar.hair_id) end
			end
			local old_onMouseMove = hairAvatar.onMouseMove
			hairAvatar.onMouseMove = function(avatar, x, y)
				old_onMouseMove(avatar, x, y)

				if self.showNameOnHover then
					local x = self:getMouseX()
					local y = self:getMouseY()
					if avatar:containsPoint(x,y) then
						self.selected_display = avatar.hair_display
					end
				end
			end

			self:addChild(hairAvatar)
			self.avatarList[idx] = hairAvatar
		end
	end

	self.offset_y = self.offset_y + (self.hair_rows * self.hair_size_y) + (self.gap * (self.hair_rows-1))
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
		adj_i = i - ((page_no-1) * self.hair_page_size)
		
		if adj_i > self.hair_page_size then
			page_no = page_no + 1
			self.pages[page_no] = {}
			adj_i = i - ((page_no-1) * self.hair_page_size)
		end
		
		self.pages[page_no][adj_i] = list[i]
	end

	if #self.pages[page_no] < self.hair_page_size then
		for i=#self.pages[page_no]+1,self.hair_page_size do
			self.pages[page_no][i] = "DISABLED"
		end
	end

	if self.page_current > #self.pages then 
		self.page_current = #self.pages
	end
	self:showPage(self.page_current)
end

function HairMenuPanel:onChangePage(button,x,y)
	if button.internal == "NEXT" then 
		self.page_current = self.page_current + 1
	elseif button.internal == "PREV" then 
		self.page_current = self.page_current - 1
	end

	if self.page_current > #self.pages then self.page_current = #self.pages end
	if self.page_current < 1 then self.page_current = 1 end

	self:showPage(self.page_current)
end

function HairMenuPanel:showPage(page_number)
	if #self.pages < 1 then return end

	for i=1,self.hair_page_size do
		if self.pages[page_number][i] == "DISABLED" then 
			self.avatarList[i]:setVisible(false)
		else
			self.avatarList[i]:setHair(self.pages[page_number][i].id, self.pages[page_number][i].display)
			self.avatarList[i]:applyHair()
			self.avatarList[i]:setVisible(true)
		end
	end
end