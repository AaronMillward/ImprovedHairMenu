--[[ 
	Adds settings for the mod.

	Optionally provides support for ModOptions to allow users to change these settings.
 ]]

ImprovedHairMenu = ImprovedHairMenu or {}
ImprovedHairMenu.settings = ImprovedHairMenu.SETTINGS or {}

-- Defaults if ModOptions isn't installed.
ImprovedHairMenu.settings.use_modal = false
ImprovedHairMenu.settings.avatar_size = 5
ImprovedHairMenu.settings.hair_rows = 3
ImprovedHairMenu.settings.hair_cols = 2
ImprovedHairMenu.settings.beard_rows = 3
ImprovedHairMenu.settings.beard_cols = 1
ImprovedHairMenu.settings.modal_rows = 8
ImprovedHairMenu.settings.modal_cols = 6


if ModOptions and ModOptions.getInstance then
	--[[ FIXME:
		Applying the modal option sometimes crashes the game. however the `OnApply` function doesn't seem to get called
		so I don't know if this is even my fault.
	 ]]

	local function OnApply(option)
		-- XXX: Reloading all mods might be too slow but I think it's the only way to reload the UI?
		option:resetLua()
	end

	local option_data = {}
	
	option_data.use_modal = {
		name = "IGUI_IHM_use_modal",
		tooltip = "IGUI_IHM_use_modal_tooltip",
		default = ImprovedHairMenu.settings.use_modal,
		OnApplyMainMenu = OnApply,
	}
	option_data.avatar_size = {
		"32", "48", "64", "80", "96", "112", "128",
		name = "IGUI_IHM_avatar_size",
		tooltip = "IGUI_IHM_avatar_size_tooltip",
		default = ImprovedHairMenu.settings.avatar_size,
		OnApplyMainMenu = OnApply,
	}
	local number_options =  {"modal_rows", "modal_cols", "hair_rows", "hair_cols", "beard_rows", "beard_cols"}
	for k,name in pairs(number_options) do
		option_data[name] = {
			"1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
			name = "IGUI_IHM_" .. name,
			default = ImprovedHairMenu.settings[name],
			OnApplyMainMenu = OnApply,
		}
	end

	local SETTINGS = {
		options_data = option_data,
		mod_id = 'ImprovedHairMenu',
		mod_shortname = 'IHM',
		mod_fullname = 'Improved Hair Menu',
	}
	ModOptions:getInstance(SETTINGS)
	ModOptions:loadFile()
	ImprovedHairMenu.settings = SETTINGS.options
end

-- NOTE: We put these after so they apply to both with and without ModOptions tables

function ImprovedHairMenu.settings:get_avatar_size()
	return 32 + ((self.avatar_size-1) * 16)
end

function ImprovedHairMenu.settings:get_menu_size(isBeard)
	local size = {rows = 1, cols = 1}
	if self.use_modal then
		size.rows = self.modal_rows
		size.cols = self.modal_cols
	else
		if isBeard then
			size.rows = self.beard_rows
			size.cols = self.beard_cols
		else
			size.rows = self.hair_rows
			size.cols = self.hair_cols
		end
	end
	return size
end