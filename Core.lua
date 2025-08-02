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
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")

local function CastBarOnUpdate(self)
        local cd = self.castData
        if not cd then
                self:SetScript("OnUpdate", nil)
                return
        end
        local now = GetTime()
        if now >= cd.endTime then
                self.castBarBG:Hide()
                self.castBar:Hide()
                self.castText:Hide()
                self.castData = nil
                self:SetScript("OnUpdate", nil)
                return
        end
        local duration = cd.endTime - cd.startTime
        local remaining = cd.endTime - now
        local pct
        if cd.isChannel then
                pct = remaining / duration
        else
                pct = 1 - (remaining / duration)
        end
        self.castBar:SetWidth(self.castBarBG:GetWidth() * pct)
        self.castText:SetText(string.format("%.1f", remaining))
end

local function StartCast(unit, isChannel)
        local f = RUF.frames[unit]
        if not f or not f.castBar then return end
        local name, _, _, startTime, endTime
        if isChannel then
                name, _, _, startTime, endTime = UnitChannelInfo(unit)
        else
                name, _, _, startTime, endTime = UnitCastingInfo(unit)
        end
        if not name then return end
        f.castData = {
                startTime = startTime / 1000,
                endTime = endTime / 1000,
                isChannel = isChannel,
        }
        f.castBar:SetWidth(isChannel and f.castBarBG:GetWidth() or 0)
        f.castBarBG:Show()
        f.castBar:Show()
        f.castText:Show()
        f:SetScript("OnUpdate", CastBarOnUpdate)
end

local function StopCast(unit)
        local f = RUF.frames[unit]
        if not f or not f.castBar then return end
        f.castBarBG:Hide()
        f.castBar:Hide()
        f.castText:Hide()
        f.castData = nil
        f:SetScript("OnUpdate", nil)
end

local function UpdateCastTimes(unit, isChannel)
        local f = RUF.frames[unit]
        if not f or not f.castData then return end
        local name, _, _, startTime, endTime
        if isChannel then
                name, _, _, startTime, endTime = UnitChannelInfo(unit)
        else
                name, _, _, startTime, endTime = UnitCastingInfo(unit)
        end
        if not name then
                StopCast(unit)
                return
        end
        f.castData.startTime = startTime / 1000
        f.castData.endTime = endTime / 1000
        f.castData.isChannel = isChannel
end

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
       elseif event == "UNIT_SPELLCAST_START" and unit == "target" then
               StartCast("target", false)
       elseif event == "UNIT_SPELLCAST_STOP" and unit == "target" then
               StopCast("target")
       elseif event == "UNIT_SPELLCAST_INTERRUPTED" and unit == "target" then
               StopCast("target")
       elseif event == "UNIT_SPELLCAST_FAILED" and unit == "target" then
               StopCast("target")
       elseif event == "UNIT_SPELLCAST_DELAYED" and unit == "target" then
               UpdateCastTimes("target", false)
       elseif event == "UNIT_SPELLCAST_CHANNEL_START" and unit == "target" then
               StartCast("target", true)
       elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" and unit == "target" then
               UpdateCastTimes("target", true)
       elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" and unit == "target" then
               StopCast("target")
       elseif event == "PLAYER_REGEN_DISABLED" then
               if RUFDB.player and RUFDB.player.hideInCombat and RUF.frames.player then
                       RUF.frames.player:Hide()
               end
               if RUFDB.target and RUFDB.target.hideInCombat and RUF.frames.target then
                       RUF.frames.target:Hide()
                       UnregisterUnitWatch(RUF.frames.target)
               end
       elseif event == "PLAYER_REGEN_ENABLED" then
               if RUFDB.player and RUFDB.player.hideInCombat and RUF.frames.player then
                       RUF.frames.player:Show()
                       UpdateUnitFrame("player")
               end
               if RUFDB.target and RUFDB.target.hideInCombat and RUF.frames.target then
                       RUF.frames.target:Show()
                       RegisterUnitWatch(RUF.frames.target)
                       UpdateUnitFrame("target")
               end
       end
end)

RUF.UpdateUnitFrame = UpdateUnitFrame
