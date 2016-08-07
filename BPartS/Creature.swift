//
//  Creature.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/3/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

extension Array
{
	var randomElement:Element?
	{
		if count == 0
		{
			return nil
		}
		let pick = Int(arc4random_uniform(UInt32(count)))
		return (self)[pick]
	}
}

struct AttackAnimState
{
	let myFrame:String?
	let theirFrame:String?
	let entryTime:CGFloat
	let holdTime:CGFloat
	let pow:Bool
}

class Special
{
	let type:String
	
	init(type:String)
	{
		self.type = type
	}
	
	//animation values
	var animation:String?
	{
		return DataStore.getString("Specials", type, "animation")
	}
	var effectFromMorphLimb:String?
	{
		return DataStore.getString("Specials", type, "effect from morph limb")
	}
	var effectColor:UIColor?
	{
		return DataStore.getColor("Specials", type, "effect color")
	}
	
	//cost values
	var healthCost:Int?
	{
		return DataStore.getInt("Specials", type, "health cost")
	}
	var energyCost:Int?
	{
		return DataStore.getInt("Specials", type, "energy cost")
	}
	var doubleHealthCostVsHulks:Bool
	{
		return DataStore.getBool("Specials", type, "double health cost vs hulks")
	}
	var tauntSelf:Bool
	{
		return DataStore.getBool("Specials", type, "taunt self")
	}
	
	//stat values
	var damage:Int
	{
		return DataStore.getInt("Specials", type, "damage") ?? 0
	}
	var numShots:Int
	{
		return DataStore.getInt("Specials", type, "shots")!
	}
	var stun:Bool
	{
		return DataStore.getBool("Specials", type, "stun")
	}
	var taunt:Bool
	{
		return DataStore.getBool("Specials", type, "taunt")
	}
	var accuracyBonus:Int
	{
		return DataStore.getInt("Specials", type, "accuracy bonus")!
	}
	var hitLimb:String?
	{
		return DataStore.getString("Specials", type, "hit limb")
	}
	var targetsAllies:Bool
	{
		return DataStore.getBool("Specials", type, "target allies")
	}
	var targetsSelf:Bool
	{
		return DataStore.getBool("Specials", type, "targets self")
	}
}

class Weapon
{
	let type:String
	let level:Int
	
	init(type:String, level:Int)
	{
		self.type = type
		self.level = level
	}
	
	var battleName:String
	{
		//TODO: display a short "in-battle" name
		return type
	}
	var inventoryName:String
	{
		//TODO: display a long name for use in inventory menus
		//this should indicate the level; like "Orric & Sons SMG mk III" or whatever
		return type
	}
	
	//stat values
	var damage:Int
	{
		return DataStore.getInt("Weapons", type, "damage")!
	}
	var accuracyBonus:Int
	{
		return DataStore.getInt("Weapons", type, "accuracy bonus")!
	}
	var numShots:Int
	{
		return DataStore.getInt("Weapons", type, "shots")!
	}
	var targetType:String
	{
		return DataStore.getString("Weapons", type, "type")!
	}
	var melee:Bool
	{
		switch(targetType)
		{
		case "auto": fallthrough
		case "manual":
			return false
		default: return true
		}
	}
	var hitLimb:String
	{
		switch(targetType)
		{
		case "auto": return "torso"
		case "manual": return "head"
		case "high": return "arm"
		case "low": return "leg"
		default: break
		}
		assertionFailure()
		return ""
	}
	var weaponStat:Int
	{
		//TODO: return a reasonable amount of weapon stat for this weapon, based on its level
		//for now I'm just assuming it's half the level
		return level / 2
	}
	
	//animation values
	var sprite:String
	{
		return DataStore.getString("Weapons", type, "sprite")!
	}
	var animation:String
	{
		return DataStore.getString("Weapons", type, "animation")!
	}
	var muzzleX:Int?
	{
		return DataStore.getInt("Weapons", type, "muzzle x")
	}
	var muzzleY:Int?
	{
		return DataStore.getInt("Weapons", type, "muzzle y")
	}
	var effectColor:UIColor?
	{
		return DataStore.getColor("Weapons", type, "effect color")
	}
}

class CreatureLimb
{
	//constants
	let name:String
	let type:String
	let baseMaxStrain:Int
	let prefix:String?
	
	//variables
	var strain:Int
	var armor:String?
	var weapon:Weapon?
	
	init(name:String, limbDict:[String:AnyObject])
	{
		func intWithName(name:String) -> Int?
		{
			if let num = limbDict[name] as? NSNumber
			{
				return Int(num.intValue)
			}
			return nil
		}
		
		self.name = name
		self.type = limbDict["type"] as! String
		self.prefix = limbDict["prefix"] as? String
		self.baseMaxStrain = intWithName("max strain")!
		self.strain = 0
	}
	
	var maxStrain:Int
	{
		if let armor = armor
		{
			return DataStore.getInt("Armors", armor, "bonus strain")! + baseMaxStrain
		}
		return baseMaxStrain
	}
	
	var broken:Bool
	{
		return strain >= maxStrain
	}
}

let baseMaxHealth:CGFloat = 350
let levelFactor:CGFloat = 0.034
let biggerLevelFactor:CGFloat = 0.05 //roughly 1.5x level factor
let baseStat = 20
let maxDefendChance = 90
let baseDefendChance = 60

class Creature
{
	//identity
	let creatureType:String
	let player:Bool
	let race:String
	var limbs = [String : CreatureLimb]()
	var specials = [Special]()
	
	//appearance data
	let morph:String
	let personality:Int
	let coloration:Int
	
	//variables
	var health:Int
	var action:Bool
	var energy:Int
	
	//statuses
	weak var tauntedBy:Creature?
	
	//stats
	var strength:Int
	var perception:Int
	var intellect:Int
	var endurance:Int
	
	//attack variables
	var activeAttack:Special?
	var activeWeapon:Weapon?
	var shotNumber:Int = 0
	var shotHit:Bool = false
	
	//derived
	var maxEnergy:Int
	{
		return DataStore.getInt("CreatureTypes", creatureType, "energy")!
	}
	var maxHealth:Int
	{
		//you only get health bonuses from non-broken limbs
		var limbBonus = 100
		for limb in limbs.values
		{
			if !limb.broken
			{
				if let armor = limb.armor
				{
					limbBonus += DataStore.getInt("Armors", armor, "bonus health")!
				}
			}
		}
		return Int(baseMaxHealth * (1 + biggerLevelFactor * CGFloat(endurance - baseStat))) * limbBonus / 100
	}
	var defendChance:Int
	{
		//you get defend penalties/bonuses from ALL armor, even broken pieces
		var dC = baseDefendChance
		for limb in limbs.values
		{
			if let armor = limb.armor
			{
				dC += DataStore.getInt("Armors", armor, "bonus defend")!
			}
		}
		return dC
	}
	
	init(creatureType:String, player:Bool)
	{
		self.creatureType = creatureType
		self.player = player
		self.race = DataStore.getString("CreatureTypes", creatureType, "race")!
		self.health = 0
		self.energy = 0
		self.action = false
		
		//load stats
		strength = DataStore.getInt("CreatureTypes", creatureType, "strength")!
		perception = DataStore.getInt("CreatureTypes", creatureType, "perception")!
		intellect = DataStore.getInt("CreatureTypes", creatureType, "intellect")!
		endurance = DataStore.getInt("CreatureTypes", creatureType, "endurance")!
		
		//load limbs
		let limbDicts = DataStore.getDictionary("Races", race, "limbs") as! [String : [String : AnyObject]]
		for (name, limbDict) in limbDicts
		{
			limbs[name] = (CreatureLimb(name: name, limbDict: limbDict))
		}
		
		//load equipment
		let armors = DataStore.getDictionary("CreatureTypes", creatureType, "armors") as! [String : String]
		for (limb, armor) in armors
		{
			limbs[limb]!.armor = armor
		}
		
		let weapons = DataStore.getDictionary("CreatureTypes", creatureType, "weapons") as! [String : String]
		for (limb, weapon) in weapons
		{
			//TODO: weapons should be leveled to the creature type, not just level 1
			limbs[limb]!.weapon = Weapon(type: weapon, level: 1)
		}
		
		if let startingSpecial = DataStore.getString("CreatureTypes", creatureType, "starting special")
		{
			specials.append(Special(type: startingSpecial))
		}
		
		//pick morph and personality
		let morphs = DataStore.getArray("Races", race, "morphs") as! [String]
		morph = morphs.randomElement!
		let personalities = DataStore.getArray("Races", race, "personalities") as! [NSNumber]
		personality = Int(personalities.randomElement!.intValue)
		let colorations = DataStore.getArray("Races", race, "colorations")!.count
		coloration = Int(arc4random_uniform(UInt32(colorations)))
		
		//fill up health
		self.health = maxHealth
		self.energy = maxEnergy
		
		//pick an initial active weapon
		pickActiveWeapon()
	}
	
	private func pickActiveWeapon()
	{
		let vW = validWeapons
		if validWeapons.count > 0
		{
			let pick = vW.randomElement!
			activeWeapon = pick
		}
		else
		{
			activeWeapon = nil
		}
	}
	
	var dead:Bool
	{
		return health == 0
	}
	
	func startTurn()
	{
		//TODO: apply DOT from broken limbs, poison, whatever
		
		//taunts are canceled if the person you are taunted by is dead
		if tauntedBy != nil && tauntedBy!.dead
		{
			tauntedBy = nil
		}
	}
	
	func endTurn()
	{
		//fill up your action, so that it can potentially be lost due to engagements
		action = true
		
		//clear all hostile one-round effects
	}
	
	func pickAttack(attack:Special)
	{
		action = false
		activeAttack = attack
		shotNumber = 0
	}
	
	func pickEngagement(weapon:Weapon)
	{
		action = false
		activeAttack = nil
		activeWeapon = weapon
		shotNumber = 0
	}
	
	var canCounter:Bool
	{
		//TODO: return false if you have a trait that prevents you from countering
		return activeWeapon != nil && !dead
	}
	
	func executeAttack(target:Creature) -> (Int?, CreatureLimb)
	{
		shotNumber += 1
		
		if let activeAttack = activeAttack
		{
			//pay costs
			if let healthCost = activeAttack.healthCost
			{
				var finalCost = healthCost * maxHealth / 100
				if activeAttack.doubleHealthCostVsHulks && false //TODO: if they're a hulk
				{
					finalCost *= 2
				}
				health = max(0, health - finalCost)
			}
			if let energyCost = activeAttack.energyCost
			{
				energy = max(0, energy - energyCost)
			}
			if activeAttack.tauntSelf
			{
				tauntedBy = target
			}
			
			
			//special effects
			if activeAttack.stun
			{
				target.action = false
			}
			if activeAttack.taunt
			{
				target.tauntedBy = self
			}
			
			
			let baseDamage = activeAttack.damage
			let hitLimb = activeAttack.hitLimb
			let accuracyBonus = activeAttack.accuracyBonus
			let numShots = activeAttack.numShots
			
			let damage = Int(CGFloat(baseDamage) * (1 + biggerLevelFactor * CGFloat(intellect - baseStat))) / numShots
			if damage < 0
			{
				//it's a healing ability, so just do it here
				target.health = min(target.health - damage, target.maxHealth)
				return (damage, target.limbs["torso"]!)
			}
			else
			{
				return target.takeHit(damage, accuracyBonus: accuracyBonus, hitLimb: hitLimb, initialHit: shotNumber == 1)
			}
		}
		else if let activeWeapon = activeWeapon
		{
			let baseDamage = activeWeapon.damage
			let hitLimb = activeWeapon.hitLimb
			let accuracyBonus = activeWeapon.accuracyBonus
			let damageStat = activeWeapon.melee ? strength : perception
			let weaponStat = activeWeapon.weaponStat
			let numShots = activeWeapon.numShots
			
			if shotNumber > numShots
			{
				//this is a pretty serious problem, heh
				assertionFailure()
			}
			
			let damage = Int(CGFloat(baseDamage) + (1 + levelFactor * CGFloat(damageStat + weaponStat - baseStat))) / numShots
			return target.takeHit(damage, accuracyBonus: accuracyBonus, hitLimb: hitLimb, initialHit: shotNumber == 1)
		}
		assertionFailure()
		return (0, limbs.first!.1)
	}
	
	func validTargetCheck(target:Creature, special:Special?, weapon:Weapon?) -> Bool
	{
		if let special = special
		{
			if !target.canBeTargetedWith(special, by: self)
			{
				return false
			}
		}
		else if let weapon = weapon
		{
			//TODO: check if you have enough ammo, and return false if you don't
			
			if target.player == player || target.dead
			{
				//no, you can't shoot your allies, nor can you shoot corpses
				return false
			}
		}
		else
		{
			assertionFailure()
		}
		
		//when you're taunted, you can only target the enemy, or use self-targeting attacks
		if special == nil || !special!.targetsSelf
		{
			if let tauntedBy = tauntedBy
			{
				if !(tauntedBy === target)
				{
					return false
				}
			}
		}
		return true
	}
	
	private func canBeTargetedWith(special:Special, by:Creature) -> Bool
	{
		if special.targetsSelf
		{
			if !(by === self)
			{
				return false
			}
		}
		else if special.targetsAllies
		{
			if player != by.player || by === self //ally-targeting attacks cannot target yourself, to prevent animation weirdness
			{
				return false
			}
		}
		else
		{
			if player == by.player
			{
				return false
			}
		}
		
		//TODO: maybe healing abilities should be able to target dead people? eh, maybe not
		//can't target dead people
		if self.dead
		{
			return false
		}
		
		
		if let animation = special.animation
		{
			let frames = DataStore.getArray("Animations", animation, "frames") as! [[String : AnyObject]]
			let states = DataStore.getString("Races", race, "states")!
			for frame in frames
			{
				if let myFrame = frame["their frame"] as? String
				{
					if DataStore.getDictionary("BodyStates", states, myFrame) == nil
					{
						//you don't have that body state!
						return false
					}
				}
			}
		}
		return true
	}
	
	var validSpecials:[Special]
	{
		var s = [Special]()
		for special in specials
		{
			//can you pay the costs?
			let canPayEnergy = special.energyCost == nil || special.energyCost! <= energy
			let canPayTaunt = !special.tauntSelf || tauntedBy == nil
			if canPayEnergy && canPayTaunt
			{
				//do you have the body parts required to use this special?
				var valid = true
				if let animation = special.animation
				{
					let requiredLimbs = DataStore.getArray("Animations", animation, "required limbs") as! [String]
					for limb in requiredLimbs
					{
						if self.limbs[limb] == nil || self.limbs[limb]!.broken
						{
							valid = false
							break
						}
					}
				}
				
				if valid
				{
					s.append(special)
				}
			}
		}
		return s
	}
	
	var validWeapons:[Weapon]
	{
		var w = [Weapon]()
		for limb in limbs.values
		{
			if !limb.broken
			{
				if let weapon = limb.weapon
				{
					w.append(weapon)
				}
			}
		}
		return w
	}
	
	func takeHit(baseDamage:Int, accuracyBonus:Int, hitLimb:String?, initialHit:Bool) -> (Int?, CreatureLimb)
	{
		//the entire attack either hits or misses, just to make the animations tidier
		let defended:Bool
		if !initialHit
		{
			defended = shotHit
		}
		else
		{
			let finalDefendChance = min(defendChance - accuracyBonus, maxDefendChance)
			defended = Int(arc4random_uniform(100)) <= finalDefendChance
			shotHit = defended
		}
		
		//take strain
		var critical:Bool = false
		var displayLimb:CreatureLimb = limbs["torso"]!
		if let hitLimb = hitLimb
		{
			var limbsCanHit = [CreatureLimb]()
			var limbsCouldHit = [CreatureLimb]()
			for limb in limbs.values
			{
				if limb.type == hitLimb
				{
					if !limb.broken
					{
						limbsCanHit.append(limb)
					}
					limbsCouldHit.append(limb)
				}
			}
			
			if limbsCanHit.count == 0 && limbsCouldHit.count > 0
			{
				//it's a critical hit!
				//"target" a totally random limb that you could have hit, and do double damage
				//no, you don't get critical hits by shooting a body part the enemy never had to begin with
				displayLimb = limbsCouldHit.randomElement!
				critical = true
			}
			if limbsCanHit.count > 0 && initialHit	//inflictStain is so that multi-hit attacks don't inflict multiple strain
			{
				let pick = limbsCanHit.randomElement!
				displayLimb = pick
				
				//apply strain to that limb
				pick.strain += 1
				
				if pick.broken
				{
					//some armors turn into other armors when broken, instead of just turning into nil
					if let armor = pick.armor, let breaksInto = DataStore.getString("Armors", armor, "breaks into")
					{
						pick.armor = breaksInto
					}
					else
					{
						pick.armor = nil
					}
					
					//raise the limb's strain to 9999 to ensure it will still be broken when replaced (in case the broken state is better I guess?)
					pick.strain = 9999
					
					//check to see if your active weapon's hand was destroyed
					if activeWeapon != nil
					{
						if !weaponInValidLimb(activeWeapon!)
						{
							pickActiveWeapon()
						}
					}
				}
			}
		}
		
		var displayDamage:Int = 0
		
		if !defended
		{
			var finalDamage = baseDamage
			
			if critical
			{
				finalDamage *= 2
			}
			
			//take damage
			health = max(0, health - finalDamage)
			
			displayDamage = finalDamage
		}
		
		//just in case, adjust health to max health, because if a limb is broken your max health might be different not
		health = min(maxHealth, health)
		
		return (baseDamage == 0 ? nil : displayDamage, displayLimb)
	}
	
	private func weaponInValidLimb(weapon:Weapon) -> Bool
	{
		for limb in limbs.values
		{
			if !limb.broken
			{
				if let wp = limb.weapon
				{
					if weapon === wp
					{
						return true
					}
				}
			}
		}
		return false
	}
	
	//MARK: animation data
	var attackAnimationStateSet:[AttackAnimState]?
	{
		var anim:String
		if let activeAttack = activeAttack
		{
			if let animation = activeAttack.animation
			{
				anim = animation
			}
			else
			{
				return nil
			}
		}
		else if let activeWeapon = activeWeapon
		{
			anim = activeWeapon.animation
		}
		else
		{
			return nil
		}
		
		var states = [AttackAnimState]()
		let frames = DataStore.getArray("Animations", anim, "frames") as! [[String : AnyObject]]
		for frame in frames
		{
			var mF:String?
			var tF:String?
			if let myFrame = frame["my frame"] as? String
			{
				//replace * in the frame with the limb prefix of the limb holding the active weapon
				var limbPrefix = ""
				for limb in limbs.values
				{
					if let lWeapon = limb.weapon, let aWeapon = activeWeapon, let lPrefix = limb.prefix
					{
						if lWeapon === aWeapon
						{
							limbPrefix = lPrefix
							break
						}
					}
				}
				mF = myFrame.stringByReplacingOccurrencesOfString("*", withString: limbPrefix)
			}
			if let theirFrame = frame["their frame"] as? String
			{
				tF = theirFrame
			}
			let eT:CGFloat = CGFloat((frame["enter time"] as! NSNumber).floatValue)
			let hT:CGFloat = CGFloat((frame["hold time"] as! NSNumber).floatValue)
			let pow = frame["pow"] != nil
			
			states.append(AttackAnimState(myFrame: mF, theirFrame: tF, entryTime: eT, holdTime: hT, pow: pow))
		}
		
		return states
	}
	var restingState:String
	{
		if dead
		{
			return "disabled"
		}
		
		if let activeWeapon = activeWeapon
		{
			for limb in limbs.values
			{
				if let weapon = limb.weapon, let prefix = limb.prefix
				{
					if weapon === activeWeapon
					{
						return "\(prefix) neutral"
					}
				}
			}
		}
		return "neutral"
	}
}