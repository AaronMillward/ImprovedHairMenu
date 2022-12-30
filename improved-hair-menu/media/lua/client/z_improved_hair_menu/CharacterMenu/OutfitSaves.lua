
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
