-- T1 mobile AntiAir / artillery Script

local NLandUnit = import('/lua/nomadsunits.lua').NLandUnit
local RocketWeapon1 = import('/lua/nomadsweapons.lua').RocketWeapon1
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaserInvisible

XNL0103 = Class(NLandUnit) {
    Weapons = {
        TargetPainter = Class(TargetingLaser) {
            OnWeaponFired = function(self)
                self.unit:SetWeaponAAMode(self.unit:DetermineTargetLayer(self))
                TargetingLaser.OnWeaponFired(self)
            end,
        },
        AAGun = Class(RocketWeapon1) {},
        ArtilleryGun = Class(RocketWeapon1) {},
    },
    
    OnCreate = function(self)
        NLandUnit.OnCreate(self)
        self:SetScriptBit('RULEUTC_SpecialToggle', true)
        self:SetWeaponAAMode(false)
        --the AA and artillery weapons share the same unpack animation, so when switching between them things dont go wrong
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self):PlayAnim('/units/XNL0103/XNL0103_Unpack.sca'):SetRate(0)
            self.Trash:Add(self.AnimationManipulator)
        end
    end,
    
    OnGotTarget = function(self, Weapon)
        if Weapon:GetBlueprint().Label ~= 'TargetPainter' and self.AnimationManipulator then
                self.AnimationManipulator:SetRate(1.5)
        end
        NLandUnit.OnGotTarget(self, Weapon)
    end,
    
    OnLostTarget = function(self, Weapon)
        if self.AnimationManipulator and not (self:GetWeapon(2):WeaponHasTarget() or self:GetWeapon(3):WeaponHasTarget()) then
            self.AnimationManipulator:SetRate(-1.5)
        end
        NLandUnit.OnLostTarget(self, Weapon)
    end,
    
    --TODO:make these more refined
    ArtilleryModePriorities = {
        'SPECIALHIGHPRI',
        'STRUCTURE DEFENSE',
        'LAND',
        'SPECIALLOWPRI',
        'ALLUNITS',
    },
    
    --the toggles switch target priorities on the painter, which in turn disables and enables AA/artillery as needed
    DisableSpecialToggle = function(self)
        local weapon = self:GetWeaponByLabel('TargetPainter')
        weapon:SetWeaponPriorities(self.ArtilleryModePriorities)
        weapon:ResetTarget()
    end,

    EnableSpecialToggle = function(self)
        local weapon = self:GetWeaponByLabel('TargetPainter')
        local bp = weapon:GetBlueprint()
        weapon:SetWeaponPriorities(bp.TargetPriorities)
        weapon:ResetTarget()
    end,
    
    DetermineTargetLayer = function(unit, weapon)
        local target = weapon:GetCurrentTarget()
        local AAMode = false --default to false so that we can always attack land targets, such as groundfire which isnt a target
        if target then
            if not IsUnit(target) then target = target:GetSource() end --sometimes we target blips instead, which breaks getting their layer
            AAMode = target:GetCurrentLayer() == 'Air'
        end
        return AAMode
    end,
    
    SetWeaponAAMode = function(self, ModeEnable)
        local weaponEnable,weaponDisable = 'ArtilleryGun', 'AAGun'
        if self.AA == ModeEnable then return end --only toggle if we arent already toggled
        if ModeEnable then --swap the weapons
            weaponEnable,weaponDisable = weaponDisable,weaponEnable
        end
        
        self:SetWeaponEnabledByLabel(weaponEnable, true)
        self:SetWeaponEnabledByLabel(weaponDisable, false)
        self:GetWeaponManipulatorByLabel(weaponEnable):SetHeadingPitch(self:GetWeaponManipulatorByLabel(weaponDisable):GetHeadingPitch())
        self.AA = ModeEnable
    end,
}

TypeClass = XNL0103