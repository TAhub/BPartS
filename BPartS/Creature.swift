//
//  Creature.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/3/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

struct AttackAnimState
{
	let myFrame:String?
	let theirFrame:String?
	let entryTime:CGFloat
	let holdTime:CGFloat
	let pow:Bool
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
	var animation:String
	{
		return DataStore.getString("Weapons", type, "animation")!
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
	var sprite:String
	{
		return DataStore.getString("Weapons", type, "sprite")!
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

let levelFactor:CGFloat = 0.1
let biggerLevelFactor:CGFloat = 0.15 //roughly 1.5x level factor
let baseStat = 20
let maxDefendChance = 90
let baseDefendChance = 50

class Creature
{
	//identity
	let race:String
	var limbs = [String : CreatureLimb]()
	
	//variables
	var health:Int
	var action:Bool
	
	//stats
	var strength:Int
	var perception:Int
	var intellect:Int
	var endurance:Int
	
	//attack variables
	var activeAttack:String?
	var activeWeapon:Weapon?
	var shotNumber:Int = 0
	var shotHit:Bool = false
	
	//derived
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
		return Int(400 * (1 + biggerLevelFactor * CGFloat(endurance - baseStat))) * limbBonus / 100
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
	
	init(race:String)
	{
		self.race = race
		self.health = 0
		self.action = false
		
		//load stats
		strength = baseStat
		perception = baseStat
		intellect = baseStat
		endurance = baseStat
		
		//load limbs
		let limbDicts = DataStore.getDictionary("Races", race, "limbs") as! [String : [String : AnyObject]]
		for (name, limbDict) in limbDicts
		{
			limbs[name] = (CreatureLimb(name: name, limbDict: limbDict))
		}
		
		//stick some temp armor on
		limbs["torso"]!.armor = "uniform"
		limbs["right arm"]!.armor = "light robot arm"
		limbs["left arm"]!.armor = "natural arm"
		limbs["right leg"]!.armor = "natural leg"
		limbs["left leg"]!.armor = "heavy robot leg"
		limbs["head"]!.armor = "helmet"
		limbs["right arm"]!.weapon = Weapon(type: "smg", level: 1)
		limbs["left arm"]!.weapon = Weapon(type: "knuckle", level: 1)
		
		//fill up health
		self.health = maxHealth
		
		//pick an initial active weapon
		pickActiveWeapon()
	}
	
	private func pickActiveWeapon()
	{
		let vW = validWeapons
		if validWeapons.count > 0
		{
			let pick = vW[Int(arc4random_uniform(UInt32(vW.count)))]
			activeWeapon = pick
		}
	}
	
	var dead:Bool
	{
		return health == 0
	}
	
	func startTurn()
	{
		//TODO: apply DOT from broken limbs, poison, whatever
	}
	
	func endTurn()
	{
		//fill up your action, so that it can potentially be lost due to engagements
		action = true
	}
	
	func pickAttack(attack:String)
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
	
	func executeAttack(target:Creature) -> Int
	{
		shotNumber += 1
		
		if let activeAttack = activeAttack
		{
			//TODO: get the actual data values for the special attack
			let baseDamage = 100
			let hitLimb = "torso"
			let accuracyBonus = 0
			
			let damage = Int(CGFloat(baseDamage) * (1 + biggerLevelFactor * CGFloat(intellect - baseStat)))
			return target.takeHit(damage, accuracyBonus: accuracyBonus, hitLimb: hitLimb, initialHit: shotNumber == 1)
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
		return 0
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
	
	func takeHit(baseDamage:Int, accuracyBonus:Int, hitLimb:String, initialHit:Bool) -> Int
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
		var limbsCanHit = [CreatureLimb]()
		for limb in limbs.values
		{
			if limb.type == hitLimb && !limb.broken
			{
				limbsCanHit.append(limb)
			}
		}
		if limbsCanHit.count > 0 && initialHit	//inflictStain is so that multi-hit attacks don't inflict multiple strain
		{
			let pick = limbsCanHit[Int(arc4random_uniform(UInt32(limbsCanHit.count)))]
			
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
						activeWeapon = nil
					}
				}
			}
		}
		
		var displayDamage:Int = 0
		
		if !defended
		{
			var finalDamage = baseDamage
			
			if limbsCanHit.count == 0
			{
				//it's a critical!
				finalDamage *= 2
			}
			
			//take damage
			health = max(0, health - finalDamage)
			
			displayDamage = finalDamage
		}
		
		//just in case, adjust health to max health, because if a limb is broken your max health might be different not
		health = min(maxHealth, health)
		
		return displayDamage
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
			anim = "" //TODO: get the animation for that attack
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