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
		
		//TODO: pick an active weapon from your weapons
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
let baseDefendChance = 30

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
		return Int(300 * (1 + biggerLevelFactor * CGFloat(endurance - baseStat))) * limbBonus / 100
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
		limbs["left leg"]!.armor = "light robot leg"
		limbs["right arm"]!.weapon = Weapon()
		limbs["left arm"]!.weapon = Weapon()
		
		//fill up health
		self.health = maxHealth
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
		activeAttack = attack
	}
	
	func pickEngagement(weapon:Weapon)
	{
		activeAttack = nil
		activeWeapon = weapon
	}
	
	func executeAttack(target:Creature)
	{
		print("POW!")
		
		if let activeAttack = activeAttack
		{
			//TODO: get the actual data values for the special attack
			let baseDamage = 100
			let hitLimb = "torso"
			let accuracyBonus = 0
			
			let damage = Int(CGFloat(baseDamage) * (1 + biggerLevelFactor * CGFloat(intellect - baseStat)))
			target.takeHit(damage, accuracyBonus: accuracyBonus, hitLimb: hitLimb)
		}
		else if let activeWeapon = activeWeapon
		{
			//TODO: get the actual data values for the weapon
			let baseDamage = 100
			let hitLimb = "torso"
			let accuracyBonus = 0
			let damageStat = strength
			let weaponStat = 20 //TODO: weapon stats start at 0, NOT at 20 like creature stats!
			
			let damage = Int(CGFloat(baseDamage) + (1 + levelFactor * CGFloat(damageStat + weaponStat - baseStat)))
			target.takeHit(damage, accuracyBonus: accuracyBonus, hitLimb: hitLimb)
			
			//TODO: remember that they might also get to attack you in return
			//if so, remove their action too and whatnot
		}
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
	
	func takeHit(baseDamage:Int, accuracyBonus:Int, hitLimb:String)
	{
		let finalDefendChance = defendChance - accuracyBonus
		let defended = Int(arc4random_uniform(100)) <= finalDefendChance
		
		//take strain
		var limbsCanHit = [CreatureLimb]()
		for limb in limbs.values
		{
			if limb.type == hitLimb && !limb.broken
			{
				limbsCanHit.append(limb)
			}
		}
		if limbsCanHit.count > 0
		{
			let pick = limbsCanHit[Int(arc4random_uniform(UInt32(limbsCanHit.count)))]
			
			//apply strain to that limb
			pick.strain += 1
			
			print("\(pick.name) has \(pick.strain) strain!")
			
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
		}
		
		//just in case, adjust health to max health, because if a limb is broken your max health might be different not
		health = min(maxHealth, health)
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
		//TODO: get the actual animation state set for the active attack or weapon
		let stateOne = AttackAnimState(myFrame: "neutral", theirFrame: nil, entryTime: 0.4, holdTime: 0.3, pow: false)
		let stateTwo = AttackAnimState(myFrame: "fencing", theirFrame: nil, entryTime: 0.4, holdTime: 0.3, pow: false)
		let stateThree = AttackAnimState(myFrame: "bow", theirFrame: "flinch", entryTime: 0.2, holdTime: 0.4, pow: true)
		let stateFour = AttackAnimState(myFrame: "fencing", theirFrame: "neutral", entryTime: 0.4, holdTime: 0.3, pow: false)
	
		return [stateOne, stateTwo, stateThree, stateFour]
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