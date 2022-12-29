--[[
	Add our changes to disableBtn to hide vanilla elements and show our menu.
]]

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local base_CharacterCreationMain_disableBtn = CharacterCreationMain.disableBtn
function CharacterCreationMain:disableBtn()

	--##################
	--Generate Hair List
	--##################

	--[[ NOTE:
		Originally we read this data out of the combobox but this is making things increasingly difficult.
		With this change the menu can become indepenedent of the original UI.
	 ]]
	
	local desc = MainScreen.instance.desc
	if self.female ~= desc:isFemale() or CharacterCreationMain.forceUpdateCombo then
		-- NOTE: We don't do this because the vanilla function will handle it.
		-- CharacterCreationMain.forceUpdateCombo = false;

		-- NOTE: Replaces "self.female" in this block as vanilla also does this same sex switch check. so if we overwrite it here it will break vanilla.
		local female = desc:isFemale()
		
		--#############
		--Get Hair Info
		--#############

		local infoHair = {}
		local hairStyles = getAllHairStyles(desc:isFemale())
		for i=1,hairStyles:size() do
			local styleId = hairStyles:get(i-1)
			local hairStyle = female and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
			local label = styleId
			if label == "" then
				label = getText("IGUI_Hair_Bald")
			else
				label = getText("IGUI_Hair_" .. label);
			end
			if not hairStyle:isNoChoose() then
				table.insert(infoHair, {
					id = hairStyles:get(i-1),
					display = label,
					selected = false,
					getterName = "getHairModel",
					setterName = "setHairModel",
				})
			end
		end

		if self.hairMenu then self.hairMenu:setInfoTable(infoHair) end
		
		--##############
		--Get Beard Info
		--##############

		local infoBeard = {}
		if desc:isFemale() then
			-- no bearded ladies
		else
			local beardStyles = getAllBeardStyles()
			for i=1,beardStyles:size() do
				local label = beardStyles:get(i-1)
				if label == "" then
					label = getText("IGUI_Beard_None")
				else
					label = getText("IGUI_Beard_" .. label);
				end
				table.insert(infoBeard, {
					id = beardStyles:get(i-1),
					display = label,
					selected = false,
					getterName = "getBeardModel",
					setterName = "setBeardModel",
				})
			end
			if self.beardMenu then self.beardMenu:setInfoTable(infoBeard) end
		end
	end

	--#######################
	--Call Vanilla disableBtn
	--#######################

	--[[ NOTE:
		When the game updates disableBtn will break due to elements changing causing calls on nil tables in disableBtn.
		If we catch the error here, it will not propegate and break the whole main menu.
	 ]]
	pcall(base_CharacterCreationMain_disableBtn, self)

	--##############
	--Set Visibility
	--##############

	-- NOTE: Base sets these depending on gender, we don't need them at all.
	if self.beardTypeLbl    then self.beardTypeLbl:setVisible(false)    end
	if self.beardTypeCombo  then self.beardTypeCombo:setVisible(false)  end
	if self.hairStubbleLbl  then self.hairStubbleLbl:setVisible(false)  end
	if self.beardStubbleLbl then self.beardStubbleLbl:setVisible(false) end

	if self.hairMenu then
		-- NOTE: hairMenu's onSelect triggers disableBtn so we need to set the selection silently to avoid an infinite loop
		self.hairMenu:setSelectedInfo(self.hairMenu.info[self.hairTypeCombo.selected])
	end

	if self.beardMenu then
		local vis = not MainScreen.instance.desc:isFemale()
		self.beardMenu:setVisible(vis)
		if self.beardMenuButton then self.beardMenuButton:setVisible(vis) end
		self.beardMenu:setSelectedInfo(self.beardMenu.info[self.beardTypeCombo.selected])
	end

	if self.skinColor then
		self.skinColorButton.attachedPanel:setSelectedInfoIndex(self.skinColor)
	end
end