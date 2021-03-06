local F, C = unpack(select(2, ...))
local oUF = F.oUF

local RaidDebuffsIgnore, invalidPrio = {}, -1

local DispellPriority = {
	['Magic'] = 4,
	['Curse'] = 3,
	['Disease'] = 2,
	['Poison'] = 1
}

local DispellFilter
do
	local dispellClasses = {
		['DRUID'] = {
			['Magic'] = false,
			['Curse'] = true,
			['Poison'] = true
		},
		['MONK'] = {
			['Magic'] = true,
			['Poison'] = true,
			['Disease'] = true
		},
		['PALADIN'] = {
			['Magic'] = false,
			['Poison'] = true,
			['Disease'] = true
		},
		['PRIEST'] = {
			['Magic'] = true,
			['Disease'] = true
		},
		['SHAMAN'] = {
			['Magic'] = false,
			['Curse'] = true
		},
		['MAGE'] = {
			['Curse'] = true
		}
	}

	DispellFilter = dispellClasses[C.MyClass] or {}
end

local function checkSpecs()
	if C.MyClass == 'DRUID' then
		if GetSpecialization() == 4 then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif C.MyClass == 'MONK' then
		if GetSpecialization() == 2 then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif C.MyClass == 'PALADIN' then
		if GetSpecialization() == 1 then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif C.MyClass == 'SHAMAN' then
		if GetSpecialization() == 3 then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	end
end

local function UpdateDebuffFrame(self, name, icon, count, debuffType, duration, expiration)
	local rd = self.RaidDebuffs
	if name then
		if rd.icon then
			rd.icon:SetTexture(icon)
			rd.icon:Show()
		end

		if rd.count then
			if count and count > 1 then
				rd.count:SetText(count)
				rd.count:Show()
			else
				rd.count:Hide()
			end
		end

		if rd.timer then
			rd.duration = duration
			if duration and duration > 0 then
				rd.expiration = expiration
				rd:SetScript('OnUpdate', F.CooldownOnUpdate)
				rd.timer:Show()
			else
				rd:SetScript('OnUpdate', nil)
				rd.timer:Hide()
			end
		end

		if rd.cd then
			if duration and duration > 0 then
				rd.cd:SetCooldown(expiration - duration, duration)
				rd.cd:Show()
			else
				rd.cd:Hide()
			end
		end

		local c = oUF.colors.debuff[debuffType] or oUF.colors.debuff.none
		if rd.ShowDebuffBorder then
			if rd.bg then
				rd.bg:SetBackdropBorderColor(c[1], c[2], c[3])
			end

			if rd.glow then
				rd.glow:SetBackdropBorderColor(c[1], c[2], c[3], .35)
			end
		end

		rd:Show()
	else
		rd:Hide()
	end
end

local instName
local function checkInstance()
	if IsInInstance() then
		instName = GetInstanceInfo()
	else
		instName = nil
	end
end

local function Update(self, _, unit)
	if unit ~= self.unit then
		return
	end

	local rd = self.RaidDebuffs
	rd.priority = invalidPrio
	rd.filter = 'HARMFUL'

	local _name, _icon, _count, _debuffType, _duration, _expiration
	local debuffs = rd.Debuffs or {}
	local isCharmed = UnitIsCharmed(unit)
	local canAttack = UnitCanAttack('player', unit)
	local prio

	for i = 1, 32 do
		local name, icon, count, debuffType, duration, expiration, _, _, _, spellId = UnitAura(unit, i, rd.filter)
		if not name then
			break
		end

		if rd.ShowDispellableDebuff and debuffType and (not isCharmed) and (not canAttack) then
			if rd.FilterDispellableDebuff then
				prio = DispellFilter[debuffType] and (DispellPriority[debuffType] + 6) or invalidPrio
				if prio == invalidPrio then
					debuffType = nil
				end
			else
				prio = DispellPriority[debuffType]
			end

			if prio and prio > rd.priority then
				rd.priority, rd.index = prio, i
				_name, _icon, _count, _debuffType, _duration, _expiration = name, icon, count, debuffType, duration, expiration
			end
		end

		local instPrio
		if instName and debuffs[instName] then
			instPrio = debuffs[instName][spellId]
		end

		if not RaidDebuffsIgnore[spellId] and instPrio and (instPrio == 6 or instPrio > rd.priority) then
			rd.priority, rd.index = instPrio, i
			_name, _icon, _count, _debuffType, _duration, _expiration = name, icon, count, debuffType, duration, expiration
		end
	end

	if rd.priority == invalidPrio then
		rd.index, _name = nil, nil
	end

	UpdateDebuffFrame(self, _name, _icon, _count, _debuffType, _duration, _expiration)
end

local function Path(self, ...)
	return (self.RaidDebuffs.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local rd = self.RaidDebuffs
	if rd then
		self:RegisterEvent('UNIT_AURA', Path)
		rd.ForceUpdate = ForceUpdate
		rd.__owner = self
		return true
	end

	checkSpecs()
	self:RegisterEvent('PLAYER_TALENT_UPDATE', checkSpecs, true)
	checkInstance()
	self:RegisterEvent('PLAYER_ENTERING_WORLD', checkInstance, true)
end

local function Disable(self)
	if self.RaidDebuffs then
		self:UnregisterEvent('UNIT_AURA', Path)
		self.RaidDebuffs:Hide()
		self.RaidDebuffs.__owner = nil
	end

	self:UnregisterEvent('PLAYER_TALENT_UPDATE', checkSpecs)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD', checkInstance)
end

oUF:AddElement('RaidDebuffs', Update, Enable, Disable)
