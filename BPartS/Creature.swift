//
//  Creature.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/3/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class CreatureLimb
{
	//constants
	let name:String
	let type:String
	let baseMaxStrain:Int
	
	//variables
	var strain:Int
	var armor:String?
	
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
		self.baseMaxStrain = intWithName("max strain")!
		self.strain = 0
	}
	
	var maxStrain:Int
	{
		//TODO: account for armor
		return baseMaxStrain
	}
}

let levelFactor:CGFloat = 0.1
let biggerLevelFactor:CGFloat = 0.15 //roughly 1.5x level factor
let baseStat = 20

class Creature
{
	//identity
	let race:String
	var limbs = [CreatureLimb]()
	
	//variables
	var health:Int
	var action:Bool
	
	//stats
	var strength:Int
	var perception:Int
	var intellect:Int
	var endurance:Int
	
	//derived
	var maxHealth:Int
	{
		//TODO: account for armor
		return Int(300 * (1 + biggerLevelFactor * CGFloat(endurance - baseStat)))
	}
	var defendChance:Int
	{
		//TODO: account for armor
		return 30
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
			limbs.append(CreatureLimb(name: name, limbDict: limbDict))
		}
		
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
	
	func takeHit(baseDamage:Int, accuracyBonus:Int, hitLimb:String)
	{
		let finalDefendChance = defendChance - accuracyBonus
		let defended = Int(arc4random_uniform(100)) <= finalDefendChance
		
		//take strain
		var limbsCanHit = [CreatureLimb]()
		for limb in limbs
		{
			if limb.type == hitLimb && limb.strain < limb.maxStrain
			{
				limbsCanHit.append(limb)
			}
		}
		if limbsCanHit.count > 0
		{
			let pick = limbsCanHit[Int(arc4random_uniform(UInt32(limbsCanHit.count)))]
			
			//apply strain to that limb
			pick.strain += 1
			
			if pick.strain >= pick.maxStrain
			{
				//TODO: break the limb's armor, replacing it with another depending on its current armor
				//IE a broken helmet turns into "no helmet"
				//a broken body armor turns into "no armor"
				//and a broken arm turns into nil
				
				//raise the limb's strain to 9999 to ensure it will still be broken when replaced (in case the broken state is better I guess?)
				pick.strain = 9999
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
	}
}