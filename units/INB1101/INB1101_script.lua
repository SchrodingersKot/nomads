# T1 pgen

local NEnergyCreationUnit = import('/lua/nomadunits.lua').NEnergyCreationUnit

INB1101 = Class(NEnergyCreationUnit) {
    ActiveEffectBone = 'exhaust',
    ActiveEffectTemplateName = 'T1PGAmbient',
}

TypeClass = INB1101