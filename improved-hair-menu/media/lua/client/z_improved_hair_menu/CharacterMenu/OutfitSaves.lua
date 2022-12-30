
-- NOTE: Vanilla unless comments says otherwise
function CharacterCreationMain:loadOutfit(box)
	local name = box.options[box.selected];
	if name == nil then return end;

	local desc = MainScreen.instance.desc;
	
	local saved_builds = CharacterCreationMain.readSavedOutfitFile();
	local build = saved_builds[name];
	if build == nil then return end;
	
	desc:getWornItems():clear();

	local items = luautils.split(build, ";");
	for i,v in pairs(items) do
		local location = luautils.split(v, "=");
		local options = nil;
		if location[2] then
			options = luautils.split(location[2], "|");
		end
		if location[1] == "gender" then
			MainScreen.instance.charCreationHeader.genderCombo.selected = tonumber(options[1]);
			MainScreen.instance.charCreationHeader:onGenderSelected(MainScreen.instance.charCreationHeader.genderCombo);
			desc:getWornItems():clear();
		elseif location[1] == "skincolor" then --Modified
			local color = luautils.split(options[1], ",");
			local index = self:ICSGetSkinRGBAsIndex(
				{ r = tonumber(color[1]), g = tonumber(color[2]), b = tonumber(color[3]) }
			)
			self:ICSonSkinColorSelected(index, true)
		elseif location[1] == "name" then
			desc:setForename(options[1]);
			MainScreen.instance.charCreationHeader.forenameEntry:setText(options[1]);
			desc:setSurname(options[2]);
			MainScreen.instance.charCreationHeader.surnameEntry:setText(options[2]);
		elseif location[1] == "hair" then
			local color = luautils.split(options[2], ",")
			local colorRGB = {
				r = tonumber(color[1]),
				g = tonumber(color[2]),
				b = tonumber(color[3]),
			};
			self:onHairColorPicked(colorRGB, true)
			self:onHairTypeSelected(options[1])
		elseif location[1] == "chesthair" then
			local chestHair = tonumber(options[1]) == 1
			self.chestHairTickBox:setSelected(1, chestHair);
			self:onChestHairSelected(1, chestHair);
		elseif location[1] == "beard" then
			self:onBeardTypeSelected(options and options[1] or "");
		elseif self.clothingCombo[location[1]]  then
--			print("dress on ", location[1], "with", options[1])
			local bodyLocation = location[1];
			local itemType = options[1];
			self.clothingCombo[bodyLocation].selected = 1;
			self.clothingCombo[bodyLocation]:selectData(itemType);
			self:onClothingComboSelected(self.clothingCombo[bodyLocation], bodyLocation);
			if options[2] then
				local comboTexture = self.clothingTextureCombo[bodyLocation]
				local color = luautils.split(options[2], ",");
				-- is it a color or a texture choice
				if (#color == 3) and self.clothingColorBtn[bodyLocation] then -- it's a color
					local colorRGB = {};
					colorRGB.r = tonumber(color[1]);
					colorRGB.g = tonumber(color[2]);
					colorRGB.b = tonumber(color[3]);
					self:onClothingColorPicked(colorRGB, true, bodyLocation);
				elseif comboTexture and comboTexture.options[tonumber(color[1])] then -- texture
					comboTexture.selected = tonumber(color[1]);
					self:onClothingTextureComboSelected(comboTexture, bodyLocation);
				end
			end
		end
	end
end

function CharacterCreationMain:saveBuildStep2(button, joypadData, param2)
	if joypadData then
		joypadData.focus = self.presetPanel
		updateJoypadFocus(joypadData)
	end
	
	if button.internal == "CANCEL" then
		return
	end
	
	local savename = button.parent.entry:getText()
	if savename == '' then return end
	
	local desc = MainScreen.instance.desc;
	
	local builds = CharacterCreationMain.readSavedOutfitFile();
	local savestring = "gender=" .. MainScreen.instance.charCreationHeader.genderCombo.selected .. ";";
	savestring = savestring .. "skincolor=" .. self.skinColorButton.backgroundColor.r .. "," .. self.skinColorButton.backgroundColor.g .. "," .. self.skinColorButton.backgroundColor.b .. ";";
	savestring = savestring .. "name=" .. MainScreen.instance.charCreationHeader.forenameEntry:getText() .. "|" .. MainScreen.instance.charCreationHeader.surnameEntry:getText() .. ";";
	local hairStyle = self.hairMenu.selectedInfo.id
	savestring = savestring .. "hair=" .. hairStyle .. "|" .. self.hairColorButton.backgroundColor.r .. "," .. self.hairColorButton.backgroundColor.g .. "," .. self.hairColorButton.backgroundColor.b .. ";";
	if not desc:isFemale() then
		savestring = savestring .. "chesthair=" .. (self.chestHairTickBox:isSelected(1) and "1" or "2") .. ";";
		local beardStyle = self.beardMenu.selectedInfo.id
		savestring = savestring .. "beard=" .. beardStyle .. ";";
	end
	for i,v in pairs(self.clothingCombo) do
		if v:getOptionData(v.selected) ~= nil then
			savestring = savestring ..  i .. "=" .. v:getOptionData(v.selected);
			if self.clothingColorBtn[i] and self.clothingColorBtn[i]:isVisible() then
				savestring = savestring .. "|" .. self.clothingColorBtn[i].backgroundColor.r .. "," .. self.clothingColorBtn[i].backgroundColor.g  .. "," .. self.clothingColorBtn[i].backgroundColor.b;
			end
			if self.clothingTextureCombo[i] and self.clothingTextureCombo[i]:isVisible() then
				savestring = savestring .. "|" .. self.clothingTextureCombo[i].selected;
			end
			savestring = savestring .. ";";
		end
	end
	builds[savename] = savestring;
	
	local options = {};
	CharacterCreationMain.writeSaveFile(builds);
	for key,val in pairs(builds) do
		options[key] = 1;
	end
	
	self.savedBuilds.options = {};
	local i = 1;
	for key,val in pairs(options) do
		table.insert(self.savedBuilds.options, key);
		if key == savename then
			self.savedBuilds.selected = i;
		end
		i = i + 1;
	end
end