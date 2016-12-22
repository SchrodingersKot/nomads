# T1 gunship

local NomadEffectTemplate = import('/lua/nomadeffecttemplate.lua')
local SupportingArtilleryAbility = import('/lua/nomadutils.lua').SupportingArtilleryAbility
local NAirTransportUnit = import('/lua/nomadunits.lua').NAirTransportUnit
local DarkMatterWeapon1 = import('/lua/nomadweapons.lua').DarkMatterWeapon1

NAirTransportUnit = SupportingArtilleryAbility( NAirTransportUnit )

INA1004 = Class(NAirTransportUnit) {
    Weapons = {
        Gun1 = Class(DarkMatterWeapon1) {},
        Gun2 = Class(DarkMatterWeapon1) {},
    },

    ArtillerySupportFxBone = 'Dome',
    BeamHoverExhaustCruise = NomadEffectTemplate.AirThrusterLargeCruisingBeam,
    BeamHoverExhaustIdle = NomadEffectTemplate.AirThrusterLargeIdlingBeam,

    OnCreate = function(self)
        NAirTransportUnit.OnCreate(self)
        self.HoverEmitterEffectTrashBag = TrashBag()
        self.BarrelAnim = CreateAnimator(self):PlayAnim('/units/INA1004/INA1004_Retract.sca'):SetRate(0)
        self.BarrelAnim:SetAnimationFraction(1)
        self.Trash:Add(self.BarrelAnim)
    end,

    OnDestroy = function(self)
        self:DestroyHoverEmitterEffects()
        NAirTransportUnit.OnDestroy(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        NAirTransportUnit.OnStopBeingBuilt(self, builder, layer)
        self.BarrelAnim:SetRate(-0.5)
        self:ForkThread(self.WatchBarrelAnim, 0.65)
    end,

    OnMotionVertEventChange = function( self, new, old )
        NAirTransportUnit.OnMotionVertEventChange( self, new, old )
        self:UpdateHoverEmitter(new, old)

        # special abilities only available when on cruising height
        if new == 'Top' then
            # unit reaching target altitude, coming from surface
            self:EnableArtillerySupport(true)

        elseif new == 'Down' then
            # unit starts landing
            self:EnableArtillerySupport(false)
        end
    end,

    WatchBarrelAnim = function(self, fraction)
        while self and not self:IsDead() and self.BarrelAnim do
            local r = self.BarrelAnim:GetRate()
            local f = self.BarrelAnim:GetAnimationFraction()
            if r == 0 then
                #LOG('INA1004: Not watching barrel anim because animation rate is 0')
                return
            elseif (r > 0 and f >= fraction) or (r < 0 and f <= fraction) then
                self.BarrelAnim:SetRate(0)
                return
            else
                WaitTicks(1)
            end
        end
    end,

    UpdateHoverEmitter = function(self, new, old)
        if new == 'Down' then
            self:DestroyHoverEmitterEffects()
            self:PlayHoverEmitterEffects(false)
        elseif new == 'Bottom' then
            self:DestroyHoverEmitterEffects()
        elseif new == 'Up' or new == 'Top' then
            self:DestroyHoverEmitterEffects()
            self:PlayHoverEmitterEffects(true)
        end
    end,

    PlayHoverEmitterEffects = function(self, large)
        local bone, army, beam, beamBP = 'Thrust_Bottom', self:GetArmy()
        if large then
            beam = CreateBeamEmitterOnEntity(self, bone, army, self.BeamHoverExhaustCruise )
        else
            beam = CreateBeamEmitterOnEntity(self, bone, army, self.BeamHoverExhaustIdle )
        end
        self.HoverEmitterEffectTrashBag:Add(beam)
        self.Trash:Add(beam)
    end,

    DestroyHoverEmitterEffects = function(self)
        self.HoverEmitterEffectTrashBag:Destroy()
    end,
}

TypeClass = INA1004