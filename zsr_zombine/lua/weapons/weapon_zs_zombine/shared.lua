if not gamemode.Get("zombiesurvival") then return end

AddCSLuaFile()

SWEP.Base = "weapon_zs_zombie"

SWEP.MeleeDelay = 0.3
SWEP.MeleeReach = 48
SWEP.MeleeDamage = 45
SWEP.MeleeForceScale = 1
SWEP.MeleeSize = 4.5
SWEP.MeleeDamageType = DMG_SLASH
SWEP.Primary.Delay = 1.3
SWEP.Primary.Automatic = false

SWEP.Secondary.Delay = 10
SWEP.Secondary.Ammo = "pistol"
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.RequiredClip = 1


SWEP.ViewModel = Model("models/weapons/zombine/v_zombine.mdl")
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

AccessorFuncDT(SWEP, "AttackAnimTime", "Float", 3)

SWEP.GrenadeDamage = 32
SWEP.GrenadeRadius = 128
SWEP.GrenadeAnimTime = 1.16
SWEP.GrenadeExplosionTime = 4
SWEP.GrenadeNextTickSound = 0

function SWEP:Think()
	--self:CheckIdleAnimation()
	self:CheckAttackAnimation()
	--self:CheckMoaning()
	self:CheckMeleeAttack()
	
	if self:GetGrenade() >= self.GrenadeExplosionTime then
		local owner = self:GetOwner()
		local pos = owner:GetPos()
		if ( IsFirstTimePredicted() ) then
			local effectdata = EffectData()
				effectdata:SetOrigin(pos)
			util.Effect("explosion_zombine", effectdata)
		end
		if SERVER then
			util.BlastDamageEx(self, owner, pos, self.GrenadeRadius, self.GrenadeDamage, DMG_ALWAYSGIB)
			owner:Kill()
		end
	end
	
	if self:IsGrenading() then
		if CurTime() > self.GrenadeNextTickSound then
			local delta = ( self:GetGrenadeStart() + self.GrenadeExplosionTime ) - CurTime()
			self.GrenadeNextTickSound = CurTime() + math.max(0.2, delta * 0.25)
			local owner = self:GetOwner()
			if CLIENT then
				owner:EmitSound("weapons/grenade/tick1.wav", 75, math.Clamp( (1 - delta / 4 ) * 160, 100, 160))
			end
		end
	end

	self:NextThink(CurTime())
	return true
end

util.PrecacheModel("models/weapons/fwkzt/zombine/z_grenade.mdl")
function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not owner:OnGround() or self:IsGrenading() then return end
	
	self:DoAlert()
	
	if owner:IsValid() then
		if SERVER then
			if not IsValid(owner.GrenadeENT) then
				owner.GrenadeENT = ents.Create("prop_zombine_grenade")
				owner.GrenadeENT:SetParent(owner)
				owner.GrenadeENT:Spawn()
			end
		end
		
		if self:GetGrenadeStart() == 0 then
			self:SetGrenadeStart(CurTime())
			self.m_ViewAngles = self:GetOwner():EyeAngles()
		end
	end	
	
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	timer.Simple(0.5,function()
		if not ( self and self:IsValid() ) then return end
		
		self:SendWeaponAnim(ACT_VM_THROW)
	end )
	self:StopMoaning()
end

function SWEP:PrimaryAttack()
	if self:IsGrenading() then return end

	self.BaseClass.PrimaryAttack(self)
	
	if self:IsSwinging() then
		self:SetAttackAnimTime(CurTime() + self.Primary.Delay)
	end
end

function SWEP:SendAttackAnim()
	local owner = self:GetOwner()
	local armdelay = self.MeleeAnimationMul
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	
	if self.SwingAnimSpeed then
		owner:GetViewModel():SetPlaybackRate(self.SwingAnimSpeed * armdelay)
	else
		owner:GetViewModel():SetPlaybackRate(1 * armdelay)
	end
end


function SWEP:StopMoaning()
	if not self:IsMoaning() then return end
	self:SetMoaning(false)
	self:GetOwner():ResetSpeed()

	--elf:StopMoaningSound()
end

function SWEP:StartMoaning()

	if self:IsMoaning() then return end
	
	self:SetMoaning(true)
	
	self:GetOwner():SetWalkSpeed( self:GetOwner():GetMaxSpeed() * 1.7 ) 

	self:StartMoaningSound()
end

function SWEP:IsInAttackAnim()
	return self:GetAttackAnimTime() > 0 and CurTime() < self:GetAttackAnimTime()
end

function SWEP:OnRemove()
	local owner = self:GetOwner()
	if IsValid(owner) then
		self:StopMoaning()
		if SERVER then
			if IsValid(owner.GrenadeENT) then
				for _, child in ipairs( owner:GetChildren() ) do
					if child:GetClass() == "prop_zombine_grenade" then
						child:Remove()
					end
				end
			end
		end
	end
end
SWEP.Holster = SWEP.OnRemove

function SWEP:StartMoaningSound()
	self:GetOwner():EmitSound("weapons/npc/zombine/zombie_voice_idle"..math.random(1, 10)..".wav")
end

function SWEP:PlayHitSound()
	self:GetOwner():EmitSound("npc/zombie/claw_strike"..math.random(3)..".wav")
end

function SWEP:PlayMissSound()
	self:GetOwner():EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav")
end

function SWEP:PlayAttackSound()
	self:GetOwner():EmitSound("weapons/npc/zombine/zo_attack"..math.random(1, 2)..".wav")
end

function SWEP:PlayAlertSound()
	self:GetOwner():EmitSound("weapons/npc/zombine/zombie_voice_idle"..math.random(1, 10)..".wav")
end

function SWEP:PlayIdleSound()
	self:GetOwner():EmitSound("weapons/npc/zombine/zombie_voice_idle"..math.random(1, 10)..".wav")
end

function SWEP:SetMoaning(moaning)
	self:SetDTBool(0, moaning)
end

function SWEP:GetMoaning()
	return self:GetDTBool(0)
end
SWEP.IsMoaning = SWEP.GetMoaning

function SWEP:TakeAmmo()
	self:TakeSecondaryAmmo(self.RequiredClip)
end

function SWEP:SetMoanHealth(health)
	self:SetDTInt(0, health)
end

function SWEP:GetMoanHealth()
	return self:GetDTInt(0)
end

function SWEP:SetGrenadeStart(time)
	self:SetDTFloat(1, time)
end

function SWEP:GetGrenadeStart()
	return self:GetDTFloat(1)
end

function SWEP:GetGrenade()
	if self:GetGrenadeStart() == 0 then return 0 end
	
	return math.Clamp((CurTime() - self:GetGrenadeStart()) / self.GrenadeAnimTime, 0, self.GrenadeExplosionTime)
end

function SWEP:GetGrenadingEndTime()
	return ( self:GetGrenadeStart() + self.GrenadeAnimTime )
end

function SWEP:IsGrenading()
	return self:GetGrenadeStart() > 0
end