local _, RUF = ...

function RUF:CreatePlayerFrame()
	local f = CreateFrame("Button", "RaphPlayerFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
	local cfg = RUFDB.player
	f:SetSize(cfg.width, cfg.height)
	f:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)

	-- Health bar background
	local healthBarBG = CreateFrame("Frame", nil, f)
	healthBarBG:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	healthBarBG:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
	local bgTexture = healthBarBG:CreateTexture(nil, "BACKGROUND")
	bgTexture:SetAllPoints()
	bgTexture:SetColorTexture(0, 0, 0, 0.5)
	healthBarBG.bg = bgTexture

	-- Health bar
	local healthBar = healthBarBG:CreateTexture(nil, "ARTWORK")
	healthBar:SetPoint("LEFT", healthBarBG, "LEFT", 0, 0)
	healthBar:SetPoint("TOP", healthBarBG, "TOP", 0, 0)
	healthBar:SetPoint("BOTTOM", healthBarBG, "BOTTOM", 0, 0)

	-- Health text
	local healthText = healthBarBG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	local offset = cfg.healthTextOffset or { x = 0, y = 0 }
	healthText:SetPoint("CENTER", healthBarBG, "CENTER", offset.x, offset.y)

	-- Apply visibility based on config
	f.healthBar = healthBar
	f.healthText = healthText
	f.healthBarBG = healthBarBG

	if cfg.hideHealthBar then
		healthBar:Hide()
		healthBarBG:Hide()
		healthText:Hide()
	else
		healthBar:Show()
		healthBarBG:Show()
		if cfg.showHealthText then healthText:Show() end
	end

	-- Name text
	local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	local nameOffset = cfg.nameTextOffset or { x = 0, y = 4 }
	nameText:SetPoint("BOTTOM", healthBarBG, "TOP", nameOffset.x, nameOffset.y)
	nameText:SetText(UnitName("player") or "Player")
	f.nameText = nameText

	local poffset = cfg.portraitOffset or { x = -64, y = 0 }

	-- 2D Portrait Frame
	local portrait2DFrame = CreateFrame("Button", nil, f, "SecureUnitButtonTemplate")
	portrait2DFrame.unit = "player"
	portrait2DFrame:SetSize(64, 64)
	portrait2DFrame:SetPoint("LEFT", f, poffset.x, poffset.y)
	portrait2DFrame:SetAttribute("unit", "player")
	portrait2DFrame:SetAttribute("*type1", "target")
	portrait2DFrame:SetAttribute("*type2", "togglemenu")
	portrait2DFrame:EnableMouse(true)
	portrait2DFrame:RegisterForClicks("AnyUp")
	portrait2DFrame:SetScript("OnEnter", UnitFrame_OnEnter)
	portrait2DFrame:SetScript("OnLeave", UnitFrame_OnLeave)

	-- portrait2DFrame:SetScript("OnEnter", function(self)
	-- 	local unit = self:GetAttribute("unit")
	-- 	if unit and UnitExists(unit) then
	-- 		UnitFrame_OnEnter(self)
	-- 	end
	-- end)



	local portrait2D = portrait2DFrame:CreateTexture(nil, "ARTWORK")
	portrait2D:SetAllPoints()

	local portrait2DBG = f:CreateTexture(nil, "BORDER")
	portrait2DBG:SetSize(80, 80)
	portrait2DBG:SetPoint("CENTER", portrait2D)
	portrait2DBG:SetTexture("interface/garrison/adventuremissionsframe")
	portrait2DBG:SetTexCoord(0.103515625, 0.1953125, 0.76513671875, 0.81201171875)

	-- 3D Portrait Frame (secure + backdrop)
	local portraitContainer = CreateFrame("Button", nil, f, "SecureUnitButtonTemplate,BackdropTemplate")
	portraitContainer.unit = "player"
	portraitContainer:SetSize(80, 80)
	portraitContainer:SetPoint("LEFT", f, poffset.x, poffset.y)
	portraitContainer:SetAttribute("unit", "player")
	portraitContainer:SetAttribute("*type1", "target")
	portraitContainer:SetAttribute("*type2", "togglemenu")
	portraitContainer:EnableMouse(true)
	portraitContainer:RegisterForClicks("AnyUp")
	portraitContainer:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	portraitContainer:SetScript("OnEnter", UnitFrame_OnEnter)
	portraitContainer:SetScript("OnLeave", UnitFrame_OnLeave)


	local portrait3D = CreateFrame("PlayerModel", nil, portraitContainer)
	portrait3D:SetSize(64, 64)
	portrait3D:SetPoint("CENTER")
	portrait3D:SetPortraitZoom(1)
	portrait3D:SetCamDistanceScale(1.25)
	portrait3D:SetRotation(0)

	-- Attach to frame
	f.portrait2D = portrait2D
	f.portrait2DFrame = portrait2DFrame
	f.portrait2DBG = portrait2DBG
	f.portrait3D = portrait3D
	f.portraitContainer = portraitContainer

	-- enforce click enable/disable based on hideHealthBar config
	if cfg.hideHealthBar then
		-- only disable clicks on the main health‑bar frame
		f:EnableMouse(false)
	else
		-- restore clicks
		f:EnableMouse(true)
		f:RegisterForClicks("AnyUp")
	end

	-- Display logic
	if cfg.use2DPortrait then
		SetPortraitTexture(portrait2D, "player")
		portrait2DFrame:Show()
		portrait2D:Show()
		portrait2DBG:Show()
		portraitContainer:Hide()
	else
		portrait3D:SetUnit("player")
		portrait2DFrame:Hide()
		portrait2D:Hide()
		portrait2DBG:Hide()
		portraitContainer:Show()
	end

	-- Events
	f:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self, event)
		if event == "UNIT_PORTRAIT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
			local cfg = RUFDB.player
			if cfg.use2DPortrait then
				SetPortraitTexture(self.portrait2D, "player")
				self.portrait2DFrame:Show()
				self.portrait2D:Show()
				self.portrait2DBG:Show()
				self.portraitContainer:Hide()
			else
				self.portrait3D:SetUnit("player")
				self.portraitContainer:Show()
				self.portrait2DFrame:Hide()
				self.portrait2D:Hide()
				self.portrait2DBG:Hide()
			end
		end
	end)

	-- Final setup
	RUF.frames.player = f
	f:SetAttribute("unit", "player")
	f:EnableMouse(true)
	f:RegisterForClicks("AnyUp")
	f:SetAttribute("*type1", "target")
	f:SetAttribute("*type2", "togglemenu")
	f.menu = function()
		ToggleDropDownMenu(1, nil, PlayerFrameDropDown, f, 0, 0)
	end
	-- now do one unified mouse/click toggle:
	local isHidden = cfg.hideHealthBar

	-- enable or disable mouse on the main frame
	f:EnableMouse(not isHidden)

	-- only register click handlers if the health bar is shown
	if not isHidden then
		f:RegisterForClicks("AnyUp")
		portrait2DFrame:RegisterForClicks("AnyUp")
		portraitContainer:RegisterForClicks("AnyUp")
	end
end
