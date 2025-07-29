local _, RUF = ...

function RUF:CreateTargetFrame()
    local cfg = RUFDB.target
    if not cfg then return end

    local f = CreateFrame("Button", "RaphTargetFrame", UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
    f:SetSize(cfg.width, cfg.height)
    f:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)

    -- Health bar background
    local healthBarBG = CreateFrame("Frame", nil, f)
    healthBarBG:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    healthBarBG:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    local bgTexture = healthBarBG:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(0, 0, 0, 0.5)

    -- Health bar & text
    local healthBar = healthBarBG:CreateTexture(nil, "ARTWORK")
    healthBar:SetPoint("LEFT", healthBarBG, "LEFT", 0, 0)
    healthBar:SetPoint("TOP", healthBarBG, "TOP", 0, 0)
    healthBar:SetPoint("BOTTOM", healthBarBG, "BOTTOM", 0, 0)

    local healthText = healthBarBG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local offset = cfg.healthTextOffset or { x = 0, y = 0 }
    healthText:SetPoint("CENTER", healthBarBG, "CENTER", offset.x, offset.y)

    -- Name text
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local nameOffset = cfg.nameTextOffset or { x = 0, y = 4 }
    nameText:SetPoint("BOTTOM", healthBarBG, "TOP", nameOffset.x, nameOffset.y)
    nameText:SetText(UnitName("target") or "Target")

    -- Store refs
    f.healthBarBG = healthBarBG
    f.healthBar   = healthBar
    f.healthText  = healthText
    f.nameText    = nameText

    -- Show/hide health bar
    if cfg.hideHealthBar then
        healthBar:Hide(); healthBarBG:Hide(); healthText:Hide()
    else
        healthBar:Show(); healthBarBG:Show();
        if cfg.showHealthText then healthText:Show() end
    end

    local poffset = cfg.portraitOffset or { x = -64, y = 0 }

    -- 2D Portrait Frame
    local portrait2DFrame = CreateFrame("Button", nil, f, "SecureUnitButtonTemplate")
    portrait2DFrame:SetSize(64, 64)
    portrait2DFrame:SetPoint("LEFT", f, poffset.x, poffset.y)
    portrait2DFrame:SetAttribute("unit", "target")
    portrait2DFrame:SetAttribute("*type1", "target")
    portrait2DFrame:SetAttribute("*type2", "togglemenu")
    portrait2DFrame:EnableMouse(true)
    portrait2DFrame:RegisterForClicks("AnyUp")
    -- Safe tooltip handling
    portrait2DFrame:SetScript("OnEnter", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not cfg.hideHealthBar and UnitExists(unit) then
            UnitFrame_OnEnter(self)
        end
    end)
    portrait2DFrame:SetScript("OnLeave", UnitFrame_OnLeave)

    local portrait2D = portrait2DFrame:CreateTexture(nil, "ARTWORK")
    portrait2D:SetAllPoints()

    local portrait2DBG = f:CreateTexture(nil, "BORDER")
    portrait2DBG:SetSize(80, 80)
    portrait2DBG:SetPoint("CENTER", portrait2D)
    portrait2DBG:SetTexture("interface/garrison/adventuremissionsframe")
    portrait2DBG:SetTexCoord(0.103515625, 0.1953125, 0.76513671875, 0.81201171875)

    -- 3D Portrait Container
    local portraitContainer = CreateFrame("Button", nil, f, "SecureUnitButtonTemplate,BackdropTemplate")
    portraitContainer:SetSize(80, 80)
    portraitContainer:SetPoint("LEFT", f, poffset.x, poffset.y)
    portraitContainer:SetAttribute("unit", "target")
    portraitContainer:SetAttribute("*type1", "target")
    portraitContainer:SetAttribute("*type2", "togglemenu")
    portraitContainer:EnableMouse(true)
    portraitContainer:RegisterForClicks("AnyUp")
    -- Safe tooltip handling
    portraitContainer:SetScript("OnEnter", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not cfg.hideHealthBar and UnitExists(unit) then
            UnitFrame_OnEnter(self)
        end
    end)
    portraitContainer:SetScript("OnLeave", UnitFrame_OnLeave)
    portraitContainer:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local portrait3D = CreateFrame("PlayerModel", nil, portraitContainer)
    portrait3D:SetSize(64, 64)
    portrait3D:SetPoint("CENTER")
    portrait3D:SetPortraitZoom(1)
    portrait3D:SetCamDistanceScale(1.25)
    portrait3D:SetRotation(0)

    -- Reference
    f.portrait2D      = portrait2D
    f.portrait2DBG    = portrait2DBG
    f.portrait2DFrame = portrait2DFrame
    f.portrait3D      = portrait3D
    f.portraitContainer = portraitContainer

    -- Portrait display
    if cfg.use2DPortrait then
        SetPortraitTexture(portrait2D, "target")
        portrait2D:Show(); portrait2DBG:Show(); portraitContainer:Hide()
    else
        portrait3D:SetUnit("target")
        portrait2D:Hide(); portrait2DBG:Hide(); portraitContainer:Show()
    end

    -- Events
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_PORTRAIT_UPDATE" and unit ~= "target" then return end
        if cfg.use2DPortrait then
            SetPortraitTexture(self.portrait2D, "target")
            self.portrait2D:Show(); self.portrait2DBG:Show(); self.portraitContainer:Hide()
        else
            self.portrait3D:SetUnit("target")
            self.portrait2D:Hide(); self.portrait2DBG:Hide(); self.portraitContainer:Show()
        end
        if event == "PLAYER_TARGET_CHANGED" then
            self.nameText:SetText(UnitName("target") or "Target")
        end
    end)

    -- Final setup
    RUF.frames.target = f
    RegisterUnitWatch(f)
    if not UnitExists("target") and not InCombatLockdown() then f:Hide() end

    -- Attributes and menu
    f:SetAttribute("unit", "target")
    f:EnableMouse(true)
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    f.menu = function() ToggleDropDownMenu(1, nil, TargetFrameDropDown, f, 0, 0) end

    -- Unified click toggle
    local isHidden = cfg.hideHealthBar
    f:EnableMouse(not isHidden)
    portrait2DFrame:EnableMouse(not isHidden)
    portraitContainer:EnableMouse(not isHidden)

    if not isHidden then
        f:RegisterForClicks("AnyUp")
        portrait2DFrame:RegisterForClicks("AnyUp")
        portraitContainer:RegisterForClicks("AnyUp")
    else
        -- Clear click registrations when hidden to avoid API errors
        f:RegisterForClicks()
        portrait2DFrame:RegisterForClicks()
        portraitContainer:RegisterForClicks()
    end
end
