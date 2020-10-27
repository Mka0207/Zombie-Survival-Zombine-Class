--Zombie Survival Zombine Class by Mka0207 : http://steamcommunity.com/id/mka0207/
--Zombine Model from Half-Life 2 : Episode 1 by VALVE.

CLASS.Name = "Zombine"
CLASS.TranslationName = "class_zombine"
CLASS.Description = "description_zombine"
CLASS.Help = "controls_zombine"

CLASS.Wave = 6 / 6

CLASS.Health = 380
CLASS.Speed = 140
CLASS.Mass = DEFAULT_MASS

CLASS.CanTaunt = false
CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true

CLASS.Points = CLASS.Health/GM.PoisonZombiePointRatio

CLASS.SWEP = "weapon_zs_zombine"

CLASS.Model = Model("models/zombie/zombie_soldier.mdl")

CLASS.DeathSounds = {"weapons/npc/zombine/zombine_die"..math.random(1, 2)..".wav"}

CLASS.PainSounds = {"weapons/npc/zombine/zombine_pain"..math.random(1, 4)..".wav"}

CLASS.VoicePitch = 0.6

CLASS.CanFeignDeath = false

CLASS.BloodColor = BLOOD_COLOR_YELLOW

sound.Add({
	name = "fatty.footstep",
    channel = CHAN_BODY,
    volume = 0.8,
    soundlevel = 65,
    pitchstart = 75,
    pitchend = 75,
    sound = {"npc/combine_soldier/gear1.wav", "npc/combine_soldier/gear2.wav", "npc/combine_soldier/gear3.wav"}
})

sound.Add({
	name = "fatty.footscuff",
    channel = CHAN_BODY,
    volume = 0.8,
    soundlevel = 65,
    pitchstart = 75,
    pitchend = 75,
    sound = {"npc/combine_soldier/gear4.wav", "npc/combine_soldier/gear5.wav", "npc/combine_soldier/gear6.wav"}
})

local mathrandom = math.random
local math_max = math.max

local StepSounds = {

	"npc/combine_soldier/gear1.wav",
	"npc/combine_soldier/gear2.wav",
	"npc/combine_soldier/gear3.wav"
	
}
local ScuffSounds = {

	"npc/combine_soldier/gear4.wav",
	"npc/combine_soldier/gear5.wav",
	"npc/combine_soldier/gear6.wav"
}

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if mathrandom() < 0.15 then
		pl:EmitSound(ScuffSounds[mathrandom(#ScuffSounds)], 70, 75)
	else
		pl:EmitSound(StepSounds[mathrandom(#StepSounds)], 70, 75)
	end

	return true
end

function CLASS:Move(pl, mv)

	local wep = pl:GetActiveWeapon()
	
	if IsValid(wep) then
		if wep.IsInAttackAnim && wep:IsInAttackAnim() || wep.GetGrenadingEndTime and CurTime() <= wep:GetGrenadingEndTime() then
			--mv:SetForwardSpeed( 0 )
			--mv:SetSideSpeed( 0 )
			mv:SetMaxClientSpeed( 0 )
			mv:SetMaxSpeed( 0 )
		end
		
		if wep.IsMoaning and wep:IsMoaning() then
			if mv:GetForwardSpeed() < 0 then
				mv:SetForwardSpeed( 0 )
			end
			mv:SetSideSpeed( 0 )
		end
	end
	
end

function CLASS:CalcMainActivity(pl, velocity)

	local wep = pl:GetActiveWeapon()
	
	if IsValid(wep) then
		if wep.IsInAttackAnim and wep:IsInAttackAnim() then
			return 1, pl:LookupSequence("FastAttack")
		elseif wep.IsMoaning and wep:IsMoaning() then
			if velocity:Length2D() > 0.5 then
				if not wep:IsGrenading() then
					return ACT_RUN, -1
				else
					return 1, pl:LookupSequence("Run_All_grenade")
				end	
			else	
				if not wep:IsGrenading() then
					return ACT_IDLE, -1
				else
					return 1, pl:LookupSequence("Idle_Grenade")
				end	
			end
		else
			if wep.IsGrenading and wep:IsGrenading() then
				if wep.GetGrenadingEndTime and CurTime() <= wep:GetGrenadingEndTime() then
					--pl:SetPlaybackRate(0)
					return 1, pl:LookupSequence("pullGrenade")
				else
					if velocity:Length2D() > 0.5 then
						return 1, pl:LookupSequence("walk_All_Grenade")
					else	
						--pl:SetPlaybackRate(0)
						return 1, pl:LookupSequence("Idle_Grenade")
					end	
				end
			end
		end
	end	
	
	if pl:OnGround() then
		if velocity:Length2D() > 0.5 then
			return ACT_WALK, -1
		else
			return ACT_IDLE, -1
		end
	elseif pl:WaterLevel() >= 3 then
		return ACT_RUN, -1
	else
		return ACT_RUN, -1
	end

	return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)

	pl:FixModelAngles(velocity)
	
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
			pl:SetPlaybackRate(0)
			pl:SetCycle((1 - (wep:GetAttackAnimTime() - CurTime()) / wep.Primary.Delay))

			return true
		end
	end	

	local len2d = velocity:Length2D()
	if len2d > 1 then
		local wep = pl:GetActiveWeapon()
		if IsValid(wep) then
			if wep.GetGrenadingEndTime and CurTime() <= wep:GetGrenadingEndTime() then
				pl:SetCycle(1-math_max(wep:GetGrenadingEndTime() - CurTime(), 0) * 0.666)
				pl:SetPlaybackRate(math.min(len2d / maxseqgroundspeed * 0.555, 3))
			else
				if wep.IsMoaning and wep:IsMoaning() then
					pl:SetPlaybackRate(math.min(len2d / maxseqgroundspeed, 3))	
				else
					pl:SetPlaybackRate(math.min(len2d / maxseqgroundspeed * 0.555, 3))
				end
			end
		end	
	else
		if wep and wep:IsValid() then 
			if wep.IsGrenading and wep:IsGrenading() and wep.GetGrenadingEndTime then
				pl:SetCycle(1-math_max(wep:GetGrenadingEndTime() - CurTime(), 0) * 0.666)
				pl:SetPlaybackRate(0)
			else
				pl:SetPlaybackRate(1)
			end
		end
		pl:SetPlaybackRate(1)
	end
	
	if !pl:IsOnGround() || pl:WaterLevel() >= 3 then
	
		pl:SetPlaybackRate(1)

		return true
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		return ACT_INVALID
	end
end

--[[function CLASS:ProcessDamage(pl, dmginfo)
	local attacker = dmginfo:GetAttacker()
	local wep = pl:GetActiveWeapon()
	if attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN then
		if wep:IsValid() and wep:IsMoaning() and wep.IsMoaning then
			wep:StopMoaning()
		end	
	end
end]]

function CLASS:DoesntGiveFear(pl)
	return IsValid(pl.FeignDeath)
end

if SERVER then
	function CLASS:OnSpawned(pl)
		--pl:SetSkin( math.Rand( 0, 3 ) )
		pl:SetBodygroup( 1, 1 )
	end
	
	function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
		pl:SetBodygroup( 1, 0 )
	end
end	

if CLIENT then
	CLASS.Icon = "zombiesurvival/killicons/zs_zombine"
	CLASS.Image = "fwkzt/class_icons/zombine.png"
end