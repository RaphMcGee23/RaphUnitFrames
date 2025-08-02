-- RaphUnitFrames: Options Menu with Tabs, Persistent Settings, and Color Override + Picker + Swatch + Health Text Toggle

local addonName, RUF = ...
RUF.frames = RUF.frames or {}
RUF.options = RUF.options or {}

-- Default config
local defaultConfig = {
	player = {
		x = -250,
		y = -200,
		width = 200,
		height = 50,
		useCustomColor = false,
		color = { r = 1, g = 1, b = 1 },
		showHealthText = true,
		use2DPortrait = true,
                healthTextOffset = { x = 0, y = 0 },
                portraitOffset = { x = 0, y = 0 },
                hideHealthBar = false,
                hideInCombat = false,
                nameTextOffset = { x = 0, y = 0 },
        },
        target = {
                x = 250,
                y = -200,
		width = 200,
		height = 50,
		useCustomColor = false,
		color = { r = 1, g = 1, b = 1 },
		showHealthText = true,
		use2DPortrait = true,
                healthTextOffset = { x = 0, y = 0 },
                portraitOffset = { x = 0, y = 0 },
                hideHealthBar = false,
                hideInCombat = false,
                nameTextOffset = { x = 0, y = 0 },
                castBarOffset = { x = 0, y = -10 },
                castTextOffset = { x = 0, y = 0 },
        },
}

-- Initialize SavedVariables
local function DeepCopyDefaults(src, dest)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dest[k]) ~= "table" then dest[k] = {} end
			DeepCopyDefaults(v, dest[k])
		elseif dest[k] == nil then
			dest[k] = v
		end
	end
end

RUFDB = RUFDB or {}
DeepCopyDefaults(defaultConfig, RUFDB)

-- Slash command
SLASH_RUF1 = "/ruf"
SlashCmdList.RUF = function()
	if not RUF.options.frame then RUF:CreateOptionsMenu() end
	if RUF.options.frame:IsShown() then
		RUF.options.frame:Hide()
	else
		RUF.options.frame:Show()
	end
end

-- Create options UI
function RUF:CreateOptionsMenu()
	local f = CreateFrame("Frame", "RUFOptionsMenu", UIParent, "BackdropTemplate")
	f:SetSize(400, 500)
	f:SetPoint("CENTER", 0, 200)
	f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
	f:Hide()
	RUF.options.frame = f

	-- Close Button
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

	-- Draggable
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	-- Tabs
	local tabs = { "player", "target" }
	local selectedTab = "player"
	for i, key in ipairs(tabs) do
		local tab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		tab:SetSize(100, 24)
		tab:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10 - (i - 1) * 30)
		tab:SetText(key:sub(1, 1):upper() .. key:sub(2))
		tab:SetScript("OnClick", function()
			selectedTab = key
			RUF:UpdateOptionsPanel()
		end)
		tab.key = key
	end

	-- Inputs
	local inputs = {}
	local labels = {
		{ key = "x",      label = "Health bar position X" },
		{ key = "y",      label = "Health bar position Y" },
		{ key = "width",  label = "Bar Width" },
		{ key = "height", label = "Bar Height" },
	}

	for i, entry in ipairs(labels) do
		local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		l:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -20 - (i - 1) * 30)
		l:SetText(entry.label)
		local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
		box:SetSize(60, 20)
		box:SetPoint("LEFT", l, "RIGHT", 10, 0)
		box:SetAutoFocus(false)
		inputs[entry.key] = box -- ✅ GOOD
	end

	-- Checkboxes
	local use2DCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	use2DCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -250)
	use2DCheck.text = use2DCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	use2DCheck.text:SetPoint("LEFT", use2DCheck, "RIGHT", 5, 0)
	use2DCheck.text:SetText("Use 2D Portrait")
        local useColorCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        useColorCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -190)
        useColorCheck.text = useColorCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        useColorCheck.text:SetPoint("LEFT", useColorCheck, "RIGHT", 5, 0)
        useColorCheck.text:SetText("Use Custom Color")
        -- Hide health bar
        local hideHealthCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        hideHealthCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -335)
        hideHealthCheck.text = hideHealthCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hideHealthCheck.text:SetPoint("LEFT", hideHealthCheck, "RIGHT", 5, 0)
        hideHealthCheck.text:SetText("Hide Health Bar")

        -- Hide entire frame in combat
        local hideCombatCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        hideCombatCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -365)
        hideCombatCheck.text = hideCombatCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hideCombatCheck.text:SetPoint("LEFT", hideCombatCheck, "RIGHT", 5, 0)
        hideCombatCheck.text:SetText("Hide In Combat")

	local showTextCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	showTextCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -160)
	showTextCheck.text = showTextCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	showTextCheck.text:SetPoint("LEFT", showTextCheck, "RIGHT", 5, 0)
	showTextCheck.text:SetText("Show Health Text")

	-- Color picker and swatch
	local colorSwatch = f:CreateTexture(nil, "OVERLAY")
	colorSwatch:SetSize(20, 20)
	local colorButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	colorButton:SetSize(120, 24)
	colorButton:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -220)
	colorButton:SetText("Pick Color")
	colorButton:SetScript("OnClick", function()
		local cfg = RUFDB[selectedTab]
		local cur = cfg.color or { r = 1, g = 1, b = 1 }
		RUF.tempColor = { r = cur.r, g = cur.g, b = cur.b }
		ShowColorPicker(cur.r, cur.g, cur.b, function(r, g, b)
			colorSwatch:SetColorTexture(r, g, b)
			RUF.tempColor = { r = r, g = g, b = b }
		end)
	end)
	colorSwatch:SetPoint("LEFT", colorButton, "RIGHT", 10, 0)
	colorSwatch:SetColorTexture(1, 1, 1)

	-- Health Text Offsets
	local healthTextX = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	healthTextX:SetSize(40, 20)
	healthTextX:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -280)
	healthTextX:SetAutoFocus(false)
	local healthTextY = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	healthTextY:SetSize(40, 20)
	healthTextY:SetPoint("LEFT", healthTextX, "RIGHT", 10, 0)

	local healthLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	healthLabel:SetPoint("RIGHT", healthTextX, "RIGHT", 204, 0)
	healthLabel:SetText("Health Text Offset (x,y)")

	-- Name Text Offsets
	local nameTextX = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	nameTextX:SetSize(40, 20)
	nameTextX:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -370)
	nameTextX:SetAutoFocus(false)
	local nameTextY = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	nameTextY:SetSize(40, 20)
	nameTextY:SetPoint("LEFT", nameTextX, "RIGHT", 10, 0)
	nameTextY:SetAutoFocus(false)
	local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameLabel:SetPoint("RIGHT", nameTextX, "RIGHT", 200, 0)
	nameLabel:SetText("Name Text Offset (x,y)")

	-- Portrait Offsets
	local portraitX = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	portraitX:SetSize(40, 20)
	portraitX:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -310)
	portraitX:SetAutoFocus(false)
	local portraitY = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	portraitY:SetSize(40, 20)
	portraitY:SetPoint("LEFT", portraitX, "RIGHT", 10, 0)
	portraitY:SetAutoFocus(false)

        local portraitLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        portraitLabel:SetPoint("RIGHT", portraitY, "RIGHT", 130, 0)
        portraitLabel:SetText("Portrait Offset (x,y)")

        -- Cast Bar Offset
        local castBarX = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        castBarX:SetSize(40, 20)
        castBarX:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -400)
        castBarX:SetAutoFocus(false)
        local castBarY = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        castBarY:SetSize(40, 20)
        castBarY:SetPoint("LEFT", castBarX, "RIGHT", 10, 0)
        castBarY:SetAutoFocus(false)
        local castBarLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        castBarLabel:SetPoint("RIGHT", castBarX, "RIGHT", 190, 0)
        castBarLabel:SetText("Cast Bar Offset (x,y)")

        -- Cast Text Offset
        local castTextX = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        castTextX:SetSize(40, 20)
        castTextX:SetPoint("TOPLEFT", f, "TOPLEFT", 140, -430)
        castTextX:SetAutoFocus(false)
        local castTextY = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        castTextY:SetSize(40, 20)
        castTextY:SetPoint("LEFT", castTextX, "RIGHT", 10, 0)
        castTextY:SetAutoFocus(false)
        local castTextLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        castTextLabel:SetPoint("RIGHT", castTextX, "RIGHT", 197, 0)
        castTextLabel:SetText("Cast Text Offset (x,y)")

	-- Apply
	local apply = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	apply:SetSize(100, 24)
	apply:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	apply:SetText("Apply")

	-- ONCLICK
	apply:SetScript("OnClick", function()
		local cfg = RUFDB[selectedTab]
		cfg.use2DPortrait = use2DCheck:GetChecked()
		cfg.x = tonumber(inputs.x:GetText()) or cfg.x
		cfg.y = tonumber(inputs.y:GetText()) or cfg.y
		cfg.width = tonumber(inputs.width:GetText()) or cfg.width
		cfg.height = tonumber(inputs.height:GetText()) or cfg.height
		cfg.useCustomColor = useColorCheck:GetChecked()
		cfg.showHealthText = showTextCheck:GetChecked()
		cfg.healthTextOffset = {
			x = tonumber(inputs.healthTextX:GetText()) or 0,
			y = tonumber(inputs.healthTextY:GetText()) or 0,
		}
		cfg.portraitOffset = {
			x = tonumber(inputs.portraitX:GetText()) or 0,
			y = tonumber(inputs.portraitY:GetText()) or 0,
		}
                cfg.nameTextOffset = {
                        x = tonumber(nameTextX:GetText()) or 0,
                        y = tonumber(nameTextY:GetText()) or 0,
                }
                cfg.castBarOffset = {
                        x = tonumber(castBarX:GetText()) or 0,
                        y = tonumber(castBarY:GetText()) or 0,
                }
                cfg.castTextOffset = {
                        x = tonumber(castTextX:GetText()) or 0,
                        y = tonumber(castTextY:GetText()) or 0,
                }
                cfg.hideHealthBar = hideHealthCheck:GetChecked()
                cfg.hideInCombat = hideCombatCheck:GetChecked()
                -- Move health text and portrait on the actual unit frame
                local frame = RUF.frames[selectedTab]
		if frame then
			if frame.healthText and frame.healthBarBG and cfg.healthTextOffset then
				frame.healthText:ClearAllPoints()
				frame.healthText:SetPoint("CENTER", frame.healthBarBG, "CENTER", cfg.healthTextOffset.x, cfg.healthTextOffset.y)
			end

			if cfg.portraitOffset then
				if frame.portrait2D then
					frame.portrait2D:ClearAllPoints()
					frame.portrait2D:SetPoint("LEFT", frame, "LEFT", cfg.portraitOffset.x, cfg.portraitOffset.y)
				end
				if frame.portraitContainer then
					frame.portraitContainer:ClearAllPoints()
					frame.portraitContainer:SetPoint("LEFT", frame, "LEFT", cfg.portraitOffset.x, cfg.portraitOffset.y)
				end
			end
		end
		if frame and cfg.x and cfg.y then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
		end
                if frame and frame.healthBar then
                        if cfg.hideHealthBar then
                                frame.healthBar:Hide()
                                frame.healthBarBG:Hide()
                                frame.healthText:Hide()

				-- disable clicks
                                frame:EnableMouse(false)
                                if frame.portrait2DFrame then
                                        frame.portrait2DFrame:EnableMouse(false)
                                end
                                if frame.portraitContainer then
                                        frame.portraitContainer:EnableMouse(false)
                                end
			else
				frame.healthBar:Show()
				frame.healthBarBG:Show()
				if cfg.showHealthText then frame.healthText:Show() end

				-- re‑enable clicks
				frame:EnableMouse(true)
				frame:RegisterForClicks("AnyUp")

				frame.portrait2DFrame:EnableMouse(true)
				frame.portrait2DFrame:RegisterForClicks("AnyUp")

                                frame.portraitContainer:EnableMouse(true)
                                frame.portraitContainer:RegisterForClicks("AnyUp")
                        end
                end
                -- Hide or show entire frame based on combat option
                if frame then
                        if cfg.hideInCombat and InCombatLockdown() then
                                frame:Hide()
                                if selectedTab == "target" then
                                        UnregisterUnitWatch(frame)
                                end
                        else
                                frame:Show()
                                if selectedTab == "target" then
                                        RegisterUnitWatch(frame)
                                end
                        end
                end
                -- Move name
                if frame.nameText and cfg.nameTextOffset then
                        frame.nameText:ClearAllPoints()
                        frame.nameText:SetPoint("BOTTOM", frame.healthBarBG, "TOP", cfg.nameTextOffset.x, cfg.nameTextOffset.y)
                end
		-- Move portrait
		if frame.portrait2D and cfg.portraitOffset then
			frame.portrait2D:ClearAllPoints()
			frame.portrait2D:SetPoint("LEFT", frame, "LEFT", cfg.portraitOffset.x, cfg.portraitOffset.y)
		end
                if frame.portraitContainer and cfg.portraitOffset then
                        frame.portraitContainer:ClearAllPoints()
                        frame.portraitContainer:SetPoint("LEFT", frame, "LEFT", cfg.portraitOffset.x, cfg.portraitOffset.y)
                end
                if frame.portraitContainer and cfg.portraitOffset then
                        frame.portraitContainer:ClearAllPoints()
                        frame.portraitContainer:SetPoint("LEFT", frame, "LEFT", cfg.portraitOffset.x, cfg.portraitOffset.y)
                end
                if frame.castBarBG and cfg.castBarOffset then
                        frame.castBarBG:ClearAllPoints()
                        frame.castBarBG:SetPoint("TOP", frame.healthBarBG, "BOTTOM", cfg.castBarOffset.x, cfg.castBarOffset.y)
                end
                if frame.castText and cfg.castTextOffset then
                        frame.castText:ClearAllPoints()
                        frame.castText:SetPoint("CENTER", frame.castBarBG, "CENTER", cfg.castTextOffset.x, cfg.castTextOffset.y)
                end
                -- Resize unit frame and its health bar
		if frame then
			frame:SetSize(cfg.width, cfg.height)

			if frame.healthBar then
				frame.healthBar:SetSize(cfg.width, cfg.height)
			end

                        if frame.healthBarBG then
                                frame.healthBarBG:SetSize(cfg.width, cfg.height)
                        end
                        if frame.castBarBG then
                                frame.castBarBG:SetSize(cfg.width, 16)
                        end
		end
		if RUF.tempColor then
			cfg.color = { r = RUF.tempColor.r, g = RUF.tempColor.g, b = RUF.tempColor.b }
		end
		-- ensure custom color enabled when tempColor used
		if RUF.tempColor then cfg.useCustomColor = true end
		-- apply update via core function
		if RUF.UpdateUnitFrame then
			RUF.UpdateUnitFrame(selectedTab)
		end
		if RUF.frames[selectedTab] then
			local frame = RUF.frames[selectedTab]
			local unit = selectedTab
			local cfg = RUFDB[unit]

			if cfg.use2DPortrait then
				SetPortraitTexture(frame.portrait2D, unit)
				frame.portrait2D:ClearAllPoints()
				frame.portrait2D:SetAllPoints(frame.portrait2DFrame)
				frame.portrait2D:SetSize(64, 64)
				frame.portrait2D:Show()

				if frame.portrait2DFrame then
					frame.portrait2DFrame:SetAttribute("unit", unit) -- ✅ IMPORTANT
				end
				if frame.portrait2DBG then frame.portrait2DBG:Show() end
				if frame.portraitContainer then frame.portraitContainer:Hide() end
				frame.portrait3D:Hide()
			else
				frame.portrait3D:SetUnit(unit)
				frame.portrait3D:Show()
				frame.portrait2D:Hide()
				if frame.portrait2DBG then frame.portrait2DBG:Hide() end
				if frame.portraitContainer then
					frame.portraitContainer:SetAttribute("unit", unit) -- ✅ IMPORTANT
					frame.portraitContainer:Show()
				end
			end
		end
		-- clear temp
		RUF.tempColor = nil
	end)

	-- Save refs and panel updater
        inputs.healthTextX = healthTextX
        inputs.healthTextY = healthTextY
        inputs.portraitX = portraitX
        inputs.portraitY = portraitY
        inputs.nameTextX = nameTextX
        inputs.nameTextY = nameTextY
        inputs.castBarX = castBarX
        inputs.castBarY = castBarY
        inputs.castTextX = castTextX
        inputs.castTextY = castTextY

	RUF.options.inputs = inputs
	RUF.options.checks = {
		useColor = useColorCheck,
		showText = showTextCheck,
		hideHealth = hideHealthCheck,
	}
	RUF.options.selectedTab = function() return selectedTab end

	function RUF:UpdateOptionsPanel()
		local cfg = RUFDB[selectedTab]
		cfg.nameTextOffset = cfg.nameTextOffset or { x = 0, y = 0 }
		inputs.nameTextX:SetText(cfg.nameTextOffset.x)
		inputs.nameTextY:SetText(cfg.nameTextOffset.y)
		cfg.healthTextOffset = cfg.healthTextOffset or { x = 0, y = 0 }
		cfg.portraitOffset = cfg.portraitOffset or { x = 0, y = 0 }
		cfg.color = cfg.color or { r = 1, g = 1, b = 1 }
		inputs.x:SetText(cfg.x)
		inputs.y:SetText(cfg.y)
		use2DCheck:SetChecked(cfg.use2DPortrait)
		cfg.color = cfg.color or { r = 1, g = 1, b = 1 }
		inputs.x:SetText(cfg.x)
		inputs.y:SetText(cfg.y)
		inputs.width:SetText(cfg.width)
                inputs.height:SetText(cfg.height)
                hideHealthCheck:SetChecked(cfg.hideHealthBar)
                hideCombatCheck:SetChecked(cfg.hideInCombat)
                inputs.healthTextX:SetText(cfg.healthTextOffset.x)
                inputs.healthTextY:SetText(cfg.healthTextOffset.y)
                inputs.portraitX:SetText(cfg.portraitOffset.x)
                inputs.portraitY:SetText(cfg.portraitOffset.y)
                cfg.castBarOffset = cfg.castBarOffset or { x = 0, y = 0 }
                cfg.castTextOffset = cfg.castTextOffset or { x = 0, y = 0 }
                inputs.castBarX:SetText(cfg.castBarOffset.x)
                inputs.castBarY:SetText(cfg.castBarOffset.y)
                inputs.castTextX:SetText(cfg.castTextOffset.x)
                inputs.castTextY:SetText(cfg.castTextOffset.y)
                useColorCheck:SetChecked(cfg.useCustomColor)
		showTextCheck:SetChecked(cfg.showHealthText)
		colorSwatch:SetColorTexture(cfg.color.r, cfg.color.g, cfg.color.b)
		RUF.tempColor = nil
		RUF.options.checks.use2DPortrait = use2DCheck
	end

	RUF:UpdateOptionsPanel()
end

-- Classic-compatible ShowColorPicker with new API fallback
function ShowColorPicker(r, g, b, callback)
	if not ColorPickerFrame then return end
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow({
			r = r,
			g = g,
			b = b,
			hasOpacity = false,
			callback = function(col) callback(col.r, col.g, col.b) end,
			cancelCallback = function() callback(r, g, b) end,
			swatchFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB(); callback(nr, ng, nb)
			end,
		})
	else
		ColorPickerFrame.func = function()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB(); callback(nr, ng, nb)
		end
		ColorPickerFrame.cancelFunc = function() callback(r, g, b) end
		ColorPickerFrame.previousValues = { r = r, g = g, b = b }
		ColorPickerFrame.hasOpacity = false
		if ColorPickerFrame.SetColorRGB then ColorPickerFrame:SetColorRGB(r, g, b) end
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end
end
