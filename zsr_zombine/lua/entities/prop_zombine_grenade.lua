AddCSLuaFile()

ENT.Type = "anim"

ENT.Model = Model("models/weapons/fwkzt/zombine/z_grenade.mdl")

function ENT:Initialize()
   self:SetModel(self.Model)

   self:DrawShadow(false)

   self:SetMoveType(MOVETYPE_NONE)
   self:SetSolid(SOLID_NONE)
   self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

   if SERVER then
      self:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
   end
end