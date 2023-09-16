local BaseFailChance, PainScream, FatigueMultiplier, FatigueThreshold, SkillMultiplier, HinderChance, BodyPartTargetChance, AwareDuration -- sandbox variable 

local Aware = 0
	
local function SumProduct(list)
	local sum_prod = {}
	local total_chance = 0
	for i, v in pairs(list) do 
		sum_prod[i] = total_chance + v
		total_chance = total_chance + v
	end
	sum_prod["total"] = total_chance
	return sum_prod 
end


local DamageTypeChance = {
	SmallDmg = {Pain = 40, Scratch = 50, Cut = 10},
	MediumDmg = {Pain = 25, Scratch = 40, Cut = 30, DeepWound= 5}, 
	HeavyDmg = {Pain = 30, Scratch = 30, Cut = 30, Fracture= 5, DeepWound= 5},
	Burn = {Pain = 30, Burn = 70},
	}
for i,v in pairs(DamageTypeChance) do DamageTypeChance[i] = SumProduct(v) end 
	
local InjuriesDefinition = {Pain={dmg_min=10, dmg_max=40},
						Scratch={dmg_min=30, dmg_max=80},
						Cut={dmg_min=30, dmg_max=80},
						DeepWound={dmg_min=50, dmg_max=100},
						Fracture={dmg_min=50, dmg_max=100},
						Burn={dmg_min=10, dmg_max=80}
						 }

local DangerousAction = {
	-- Small Damage
	 ISCheckTrapAction={dmg="SmallDmg", location="upper_body", perk = "Trapping"},
	 ISAddItemInRecipe={dmg="SmallDmg", location="upper_body", perk = "Cooking"},
	 ISRepairClothing={dmg="SmallDmg", location="upper_body", perk = "Tailoring"},
	 ISFixGenerator={dmg="SmallDmg", location="upper_body", perk = "Electricity"}, 
	 ISForageAction={dmg="SmallDmg", location="upper_body", perk = "PlantScavenging"}, 
	 ISFishingAction={dmg="SmallDmg", location="upper_body", perk = "Fishing"},
	 ISCheckFishingNetAction={dmg="SmallDmg", location="upper_body", perk = "Fishing"},
	 ISHarvestPlantAction={dmg="SmallDmg", location="upper_body", perk = "Farming"}, 
	 ISInstallVehiclePart={dmg="SmallDmg", location="upper_body", perk = "Mechanics"},
	 ISUninstallVehiclePart={dmg="SmallDmg", location="upper_body", perk = "Mechanics"},
	 ISUpgradeWeapon={dmg="SmallDmg", location="upper_body"},
	 -- Medium Damage
	 ISTakeEngineParts={dmg="MediumDmg", location="upper_body", perk = "Mechanics"},
	 ISAddSheetRope={dmg="MediumDmg", location="upper_body", perk = "Woodwork"},
	 ISBarricadeAction={dmg="MediumDmg", location="upper_body", perk = "Woodwork"},
	 ISUnbarricadeAction={dmg="MediumDmg", location="upper_body", perk = "Woodwork"},
	 ISPlaceTrap={dmg="MediumDmg", location="upper_body", perk = "Trapping"},
	 ISCutHair={dmg="MediumDmg", location="head"}, 
	 ISTrimBeard={dmg="MediumDmg", location="head"}, 
	 ISAddTentAction={dmg="MediumDmg", location="upper_body"},
	 ISRemoveTentAction={dmg="MediumDmg", location="upper_body"},
	 ISMoveablesAction={dmg="MediumDmg"},
	 ISBuryCorpse={dmg="MediumDmg"},
	 -- Heavy Damage
	 ISChopTreeAction={dmg="HeavyDmg", perk = "Woodwork"}, 
	 ISDestroyStuffAction={dmg="HeavyDmg"},
	 ISDismantleAction={dmg="HeavyDmg"},
	 -- Burn Damage
	 ISRemoveBurntVehicle={dmg="Burn", location="upper_body", perk = "Mechanics"}, 
	 ISBBQExtinguish={dmg="Burn", location="upper_body"}, 
	 ISBBQLightFromKindle={dmg="Burn", location="upper_body"},
	 ISBBQLightFromLiterature={dmg="Burn", location="upper_body"},
	 ISBBQLightFromPetrol={dmg="Burn", location="upper_body"},
	 ISFireplaceExtinguish={dmg="Burn", location="upper_body"},
	 ISFireplaceLightFromKindle={dmg="Burn", location="upper_body"},
	 ISFireplaceLightFromLiterature={dmg="Burn", location="upper_body"},
	 ISFireplaceLightFromPetrol={dmg="Burn", location="upper_body"},
	 ISLightFromKindle={dmg="Burn", location="upper_body"},
	 ISLightFromLiterature={dmg="Burn", location="upper_body"},
	 ISLightFromPetrol={dmg="Burn", location="upper_body"}, 
	 ISBurnCorpseAction={dmg="Burn"},
}
 
local function getValidCloth(player, part_type) 
	local cloth = {}
	local worn_items = player:getWornItems()
	for i = 0, worn_items:size() - 1 do
		local item = worn_items:get(i):getItem()
		if item and instanceof(item, "Clothing") then
			local covered_parts = item:getCoveredParts()
			for j = 0, covered_parts:size() - 1 do
				if covered_parts:get(j) == part_type then
					table.insert(cloth, worn_items:get(i):getItem())
				end
			end
		end
	end
	return cloth
end

function getFail(player, perk) 
	local fatigue = player:getStats():getFatigue() 
	if fatigue < FatigueThreshold then fatigue = FatigueThreshold end
	local player_level = 0
	if perk then player_level = player:getPerkLevel(Perks[perk]) end
	local fail_chance = BaseFailChance - SkillMultiplier * (0.2 * player_level) + FatigueMultiplier * ((fatigue - FatigueThreshold) / (1 - FatigueThreshold))
	if ZombRand(0, 100) < fail_chance then return true
	else return false
	end
end  

function getMultiBuildDamage(toolName)
	if type(toolName) ~= "string" or toolName == "" then return nil; end 
	if toolName == "Base.BlowTorch" or toolName == "BlowTorch" then return "Burn"; end 
	local tool = InventoryItemFactory.CreateItem(toolName)
	if tool == nil then return nil; end  
	if instanceof(tool, "HandWeapon") then return "MediumDmg"; end
	return nil
end

function getCraftDamage(toolName)
	if type(toolName) ~= "string" or toolName == "" then return nil; end
	
	if toolName == "Base.BlowTorch" or toolName == "BlowTorch" then return "Burn"; end
	local tool = InventoryItemFactory.CreateItem(toolName)
	if tool == nil then return nil; end
	if tool:hasTag("Saw") then return "SmallDmg";end
	  
	if instanceof(tool, "HandWeapon") then
		if tool:getCategories():contains("SmallBlade") then return "SmallDmg" 
		elseif tool:getCategories():contains("Axe") then return "MediumDmg" 
		elseif tool:getCategories():contains("Blunt") then return "MediumDmg" 
		elseif tool:getCategories():contains("SmallBlunt") then return "SmallDmg" 
		elseif tool:getCategories():contains("LongBlade") then return "MediumDmg" 
		elseif tool:getCategories():contains("Spear") then return "MediumDmg" 
		end
	end 
	return nil
end

local function TryDamage(player, target_type, dmg_category, perk)
	if not getFail(player, perk) then return; end
	if Aware > 0 then 
		return
	end; -- Cancel if Aware timer not at 0
	-- Pick Random Body Part
	local part_type = false
	local body_part = false
	local rand = ZombRand(BodyPartTargetChance[target_type].total) + 1
	for i, v in pairs(BodyPartTargetChance[target_type]) do
		if rand <= v then
			part_type = BodyPartType[i]
			body_part = player:getBodyDamage():getBodyPart(part_type)
			break
		end
	end
	-- Pick random damage type
	local dmg_type = false
	local rand = ZombRand(DamageTypeChance[dmg_category].total) + 1
	for i, v in pairs(DamageTypeChance[dmg_category]) do
		if rand <= v then 
			dmg_type = i 
			break
		end
	end 
	-- Damage cloth
	local injury_info = InjuriesDefinition[dmg_type]
	local dmg = ZombRand(injury_info.dmg_min, injury_info.dmg_max)
	local harm_player = true
	if dmg_type ~= "Pain" then -- Pain ignore cloth defense 
		local valid_cloth = getValidCloth(player, part_type)
		for i = #valid_cloth, 1, -1 do
			local cloth_def = 0
			if dmg_type == "Burn" then cloth_def = valid_cloth[i]:getInsulation() * 0.33
			else cloth_def = valid_cloth[i]:getSratchDefense() 
			end
			if dmg >= cloth_def then
				character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(body_part)))	
			end
			dmg = dmg - cloth_def
			if dmg <= 0 then
				harm_player = false
				break
			end
		end 
	end
	if not harm_player then return end;
	
	if PainScream then 
		local rand = ZombRand(7)
		local text = getText("IGUI_PlayerText_Damage"..tostring(rand))
		if rand < 2 then player:SayWhisper(text)
		elseif rand < 4 then player:Say(text)
		else player:SayShout(text)
		end
	end
	-- Damage player
	if dmg_type == "Pain" then body_part:setAdditionalPain(body_part:getAdditionalPain() + dmg)
	elseif dmg_type == "Scratch" then body_part:SetScratchedWeapon(true)
	elseif dmg_type == "Cut" then body_part:setCut(true)
	elseif dmg_type == "DeepWound" then body_part:generateDeepWound()
	elseif dmg_type == "Burn" then body_part:setBurned()
	elseif dmg_type == "Fracture" then body_part:setFractureTime(body_part:getFractureTime() + 21)
	end
	Aware = AwareDuration -- Set up timer if character has been hurt 
end

local original_perform = ISBaseTimedAction.perform
function ISBaseTimedAction:perform()
	original_perform(self)
	local action_type = self.Type 
	local action_info = DangerousAction[action_type]
	if action_info then -- Action except craft and build
		local location = action_info.location
		if not location then location = "default" end 
		TryDamage(self.character, location, action_info.dmg, action_info.perk)
	elseif action_type == "ISCraftAction" then -- Craft Action
		local recipe = self.recipe
		local dmg_type = false
		for i = 0, recipe:getSource():size() - 1 do
			local source = recipe:getSource():get(i)
			if source:isKeep() then 
				local keep = source:getItems()
				for j = 0, keep:size() - 1 do
					dmg_type = getCraftDamage(keep:get(j))
					if dmg_type then break; end
				end
			end
			if dmg_type then break; end
		end 
		if not dmg_type then return; end
		local perk = false 
		local category = recipe:getCategory()
		local location = "upper_body"
		if category == "Survivalist" or category == "Carpentry" then 
			perk = "Woodwork"
			location = "default"
		elseif category == "Trapper" then  perk = "Trapping" 
		elseif category == "Electrical" then  perk = "Electricity"  
		elseif category == "Cooking" then  perk =  "Cooking" 
		elseif category == "Smithing" then 
			perk = "Blacksmith" 
			location = "default" 
		end
		TryDamage(self.character, location, dmg_type, perk)
	elseif action_type == "ISBuildAction" then -- Build Action 
		local perk = false
		local item = self.item 
		if item.firstItem == "BlowTorch" then
			perk = "MetalWelding" 
			dmg_type = "Burn" 
		elseif not item.noNeedHammer then
			perk = "Woodwork" 
			dmg_type = "MediumDmg"
		else dmg_type = "SmallDmg"
		end
		TryDamage(self.character, "default", dmg_type, perk)
	elseif action_type == "ISMultiStageBuild" then -- MultiStageBuild
		local perk = false 
		local lua_perks = self.stage:getPerksLua()
		if lua_perks[1] == 7 then perk = "Woodwork"
		else perk = "MetalWelding"
		end
		local keep = self.stage:getItemsToKeep()
		for i = 0, keep:size() - 1 do
			dmg_type = getMultiBuildDamage(keep:get(i))
			if dmg_type then break; end
		end   
		if not dmg_type then return; end
		TryDamage(self.character, "default", dmg_type, perk)
	end  
end 

local function OnLoad() -- Load sandbox options
	BaseFailChance = SandboxVars.CommonInjuries.BaseFailChance
	PainScream = SandboxVars.CommonInjuries.PainScream
	FatigueMultiplier = SandboxVars.CommonInjuries.FatigueMultiplier 
	FatigueThreshold = SandboxVars.CommonInjuries.FatigueThreshold / 100
	SkillMultiplier = SandboxVars.CommonInjuries.SkillMultiplier
	AwareDuration = SandboxVars.CommonInjuries.AwareDuration
	
	HinderChance = SandboxVars.CommonInjuries.HinderChance - 1
	
	BodyPartTargetChance = {
		default = {
			Hand_L = 12,
			ForeArm_L = 8,
			UpperArm_L = 8,
			Hand_R = 4*HinderChance,
			ForeArm_R = 2*HinderChance,
			UpperArm_R = 2*HinderChance,
			Torso_Upper = 14,
			Torso_Lower = 14,
			Groin = 6,
			UpperLeg_L = 1*HinderChance,
			LowerLeg_L = 1*HinderChance,
			UpperLeg_R = 1*HinderChance,
			LowerLeg_R = 1*HinderChance,
			Foot_L = 1*HinderChance,
			Foot_R = 1*HinderChance,
			},
		upper_body = {
			Hand_L = 12,
			ForeArm_L = 8,
			UpperArm_L = 8,
			Hand_R = 6*HinderChance,
			ForeArm_R = 3*HinderChance,
			UpperArm_R = 3*HinderChance,
			Torso_Upper = 14,
			Torso_Lower = 14,
			},
		head = {
			Head = 2,
			Neck = 2,
			}
		}
		
	for i,v in pairs(BodyPartTargetChance) do BodyPartTargetChance[i] = SumProduct(v) end 
end
Events.OnLoad.Add(OnLoad)

local function DecreaseAwareTimer() -- Decrease timer every hour
	if Aware > 0 then Aware = Aware - 1 end
end
Events.EveryHours.Add(DecreaseAwareTimer)
