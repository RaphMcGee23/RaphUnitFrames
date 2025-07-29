-- core.lua

-- Hide default frames
PlayerFrame:UnregisterAllEvents()
PlayerFrame:Hide()

TargetFrame:UnregisterAllEvents()
TargetFrame:Hide()


local addonName, RUF = ...
_G[addonName] = RUF

RUF.frames = RUF.frames or {}
RUF.utils = RUF.utils or {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Reusable health bar update logic
local function UpdateUnitFrame(unit)
	local f = RUF.frames[unit]
	local cfg = RUFDB[unit]
	if not f or not cfg then return end

	local hp = UnitHealth(unit)
	local hpMax = UnitHealthMax(unit)
	local pct = (hpMax > 0) and (hp / hpMax) or 0

	-- Determine color
	local r, g, b
	if cfg.useCustomColor and cfg.color then
		r = tonumber(cfg.color.r) or 255
		g = tonumber(cfg.color.g) or 255
		b = tonumber(cfg.color.b) or 255
		r = math.max(0, math.min(1, r > 1 and r / 255 or r))
		g = math.max(0, math.min(1, g > 1 and g / 255 or g))
		b = math.max(0, math.min(1, b > 1 and b / 255 or b))
	else
		local _, class = UnitClass(unit)
		local classColor = class and RAID_CLASS_COLORS[class] or { r = 0.8, g = 0.8, b = 0.8 }
		r, g, b = classColor.r, classColor.g, classColor.b
	end

	-- Update health bar
	if f.healthBar and f.healthBarBG then
		f.healthBar:SetColorTexture(r, g, b)
		local barWidth = f.healthBarBG:GetWidth() * pct
		f.healthBar:SetWidth(barWidth)
	end

	if f.nameText then
		f.nameText:SetText(UnitName(unit) or unit)
	end

	-- If the unit is dead, override name text and gray out health bar
	if UnitIsDead(unit) or UnitIsGhost(unit) or UnitIsFeignDeath(unit) then
		if f.nameText then
			f.nameText:SetText(UnitName(unit) .. " (Dead)")
		end
		if f.healthBar then
			f.healthBar:SetColorTexture(0.3, 0.3, 0.3)  -- Gray
			f.healthBar:SetWidth(f.healthBarBG:GetWidth()) -- full bar
		end
		if f.healthText then
			f.healthText:Hide()
		end
		return -- skip normal update
	end

	-- Show or hide health text
	if f.healthText then
		if cfg.showHealthText then
			f.healthText:Show()
			f.healthText:SetText(string.format("%d%%", pct * 100))
		else
			f.healthText:Hide()
		end
	end
end

eventFrame:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		if not RUF.frames.player then
			RUF:CreatePlayerFrame()
		end
		UpdateUnitFrame("player")

		if not RUF.frames.target then
			RUF:CreateTargetFrame()
		end
		UpdateUnitFrame("target")
	end

	if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and (unit == "target" or unit == "player") then
		UpdateUnitFrame(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		if not RUF.frames.target then
			RUF:CreateTargetFrame()
		end
		UpdateUnitFrame("target")
	end
end)

RUF.UpdateUnitFrame = UpdateUnitFrame
