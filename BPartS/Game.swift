//
//  Game.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/3/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

protocol GameDelegate
{
	func attackAnim(number:Int?, hitLimb:CreatureLimb)
}

class Game
{
	var delegate:GameDelegate?
	
	var players = [Creature]()
	var enemies = [Creature]()
	
	var playersActive:Bool = false
	var creatureOn:Int = 0
	var personCouldAct:Bool = false
	var playersCouldActFailRounds:Int = 10
	var enemiesCouldActFailRounds:Int = 10
	
	var attackAnimStateSet:[AttackAnimState]?
	var attackAnimStateSetProgress:Int = 0
	var attackTarget:Creature!
	var canCounter:Bool = false
	
	var swapActive:Bool?
	var swapOn:Int?
	
	var activeArray:[Creature]
	{
		return playersActive ? players : enemies
	}
	var activeCreature:Creature
	{
		return activeArray[creatureOn]
	}
	
	
	func start()
	{
		//do end turn for EVERYONE, to make sure everyone starts with actions
		for cr in players + enemies
		{
			cr.endTurn()
		}
		
		//and then use actionOver to start the turn more specifically
		creatureOn = enemies.count - 1
		playersActive = false
		actionOver()
	}
	
	private func actionOver()
	{
		//check to see if there's a living enemy
		var enemyAlive:Bool = false
		for enemy in enemies
		{
			if !enemy.dead
			{
				enemyAlive = true
				break
			}
		}
		if !enemyAlive
		{
			//TODO: the players win!
			print("VICTORY!")
			return
		}
		
		//check to see if there's a living player
		var playerAlive:Bool = false
		for player in players
		{
			if !player.dead
			{
				playerAlive = true
				break
			}
		}
		if !playerAlive
		{
			//TODO: the players lose!
			print("DEFEAT!")
			return
		}
		
		if canCounter && attackTarget.canCounter
		{
			//save the current active person so you can revert to them later
			swapActive = playersActive
			swapOn = creatureOn
			
			//figure out the creature number for the target
			var newOn:Int?
			var newPlayer:Bool?
			for (i, player) in players.enumerate()
			{
				if player === attackTarget
				{
					newPlayer = true
					newOn = i
					break
				}
			}
			if newOn == nil
			{
				for (i, enemy) in enemies.enumerate()
				{
					if enemy === attackTarget
					{
						newPlayer = false
						newOn = i
						break
					}
				}
			}
			if let newOn = newOn, let newPlayer = newPlayer
			{
				attackTarget = activeCreature
				creatureOn = newOn
				playersActive = newPlayer
			}
			else
			{
				//if you couldn't find the target, it's some horrible error
				assertionFailure()
			}
			
			//the attack target will counter-attack
			canCounter = false
			activeCreature.pickEngagement(activeCreature.activeWeapon!)
			setAASS()
			return
		}
		
		if let swapActive = swapActive, let swapOn = swapOn
		{
			playersActive = swapActive
			creatureOn = swapOn
			self.swapActive = nil
			self.swapOn = nil
		}
		
		if creatureOn == activeArray.count - 1
		{
			//check the player defeat counter
			if !personCouldAct
			{
				if playersActive
				{
					//you have to fail the check a number of rounds, to be absolutely sure you can't act
					playersCouldActFailRounds -= 1
				}
				else
				{
					//same for the enemies check
					enemiesCouldActFailRounds -= 1
				}
				if playersCouldActFailRounds <= 0 && enemiesCouldActFailRounds <= 0
				{
					//TODO: nobody can act, so the players lose!
					print("DEFEAT!")
					return
				}
			}
			
			//start the next turn
			for cr in activeArray
			{
				cr.endTurn()
			}
			playersActive = !playersActive
			creatureOn = 0
			for cr in activeArray
			{
				cr.startTurn()
			}
			
			//reset the player defeat counter
			personCouldAct = false
		}
		else
		{
			creatureOn += 1
		}
		
		if activeCreature.dead
		{
			actionOver()
			return
		}
		
		//skip turns for "parmanent" reasons (no enemies are valid targets of your weapons, 
		let weapons = activeCreature.validWeapons
		let specials = activeCreature.validSpecials
		var anyActions = false
		for weapon in weapons
		{
			if validTargetsFor(special: nil, weapon: weapon).count > 0
			{
				anyActions = true
				break
			}
		}
		if !anyActions
		{
			for special in specials
			{
				if validTargetsFor(special: special, weapon: nil).count > 0
				{
					anyActions = true
					break
				}
			}
		}
		if !anyActions
		{
			actionOver()
			return
		}
		
		
		//personCouldAct is set if you can attack anyone, AND if you're not dead
		//it ignores if you have an action or not
		//if you have no possible attacks to make, the battle should be ended now to avoid any infinite loops of armlessness
		personCouldAct = true
		
		
		//skip turn for temporal reasons (status effects, lack of actions, etc)
		if !activeCreature.action
		{
			actionOver()
			return
		}
		
		if playersActive
		{
			//select a weapon in the beginning
			if let activeWeapon = activeCreature.activeWeapon
			{
				activeCreature.pickEngagement(activeWeapon)
			}
		}
	}
	
	private func animComplete()
	{
		if let aASS = attackAnimStateSet
		{
			attackAnimStateSetProgress += 1
			
			if aASS.count == attackAnimStateSetProgress
			{
				attackAnimStateSet = nil
				actionOver()
			}
			else if aASS[attackAnimStateSetProgress].pow
			{
				let (dNum, hitLimb) = activeCreature.executeAttack(attackTarget)
				delegate?.attackAnim(dNum, hitLimb: hitLimb)
			}
		}
	}
	
	func chooseAttack(target:Creature) -> Bool
	{
		if attackAnimStateSet == nil && activeCreature.validTargetCheck(target, special: activeCreature.activeAttack, weapon: activeCreature.activeWeapon)
		{
			canCounter = activeCreature.activeAttack == nil
			attackTarget = target
			
			setAASS()
			return true
		}
		return false
	}
	
	private func setAASS()
	{
		if let aASS = activeCreature.attackAnimationStateSet
		{
			attackAnimStateSet = aASS
			attackAnimStateSetProgress = -1
			animComplete()
		}
		else
		{
			//just instantly execute the effect of the attack and call it a day
			let (dNum, hitLimb) = activeCreature.executeAttack(attackTarget)
			delegate?.attackAnim(dNum, hitLimb: hitLimb)
			actionOver()
		}
	}
	
	func update(elapsed:CGFloat, animating:Bool)
	{
		if !animating
		{
			animComplete()
		}
	}
	
	private func validTargetsFor(special special:Special?, weapon:Weapon?) -> [Creature]
	{
		var targets = [Creature]()
		
		for player in players
		{
			if activeCreature.validTargetCheck(player, special: special, weapon: weapon)
			{
				targets.append(player)
			}
		}
		for enemy in enemies
		{
			if activeCreature.validTargetCheck(enemy, special: special, weapon: weapon)
			{
				targets.append(enemy)
			}
		}
		return targets
	}
	
	//MARK: AI
	
	private func aiTrySpecial()->Bool
	{
		let specials = activeCreature.validSpecials
		var validSpecials = [Special]()
		for special in specials
		{
			if validTargetsFor(special: special, weapon: nil).count > 0
			{
				validSpecials.append(special)
			}
		}
		if let pick = validSpecials.randomElement
		{
			activeCreature.pickAttack(pick)
			let targets = validTargetsFor(special: pick, weapon: nil)
			chooseAttack(targets.randomElement!)
			return true
		}
		return false
	}
	
	private func aiTryEngagement()->Bool
	{
		let weapons = activeCreature.validWeapons
		var validWeapons = [Weapon]()
		for weapon in weapons
		{
			if validTargetsFor(special: nil, weapon: weapon).count > 0
			{
				validWeapons.append(weapon)
			}
		}
		if let pick = validWeapons.randomElement
		{
			activeCreature.pickEngagement(pick)
			let targets = validTargetsFor(special: nil, weapon: pick)
			chooseAttack(targets.randomElement!)
			return true
		}
		return false
	}
	
	func aiAction()
	{
		let specialFirst = arc4random_uniform(100) < 30
		
		if specialFirst
		{
			if !aiTrySpecial()
			{
				if !aiTryEngagement()
				{
					//it shouldn't get to this point
					assertionFailure()
				}
			}
		}
		else
		{
			if !aiTryEngagement()
			{
				if !aiTrySpecial()
				{
					//it shouldn't get to this point
					assertionFailure()
				}
			}
		}
	}
}