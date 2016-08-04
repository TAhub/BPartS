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
	func damageNumber(number:Int)
}

class Game
{
	var delegate:GameDelegate?
	
	var players = [Creature]()
	var enemies = [Creature]()
	
	var playersActive:Bool = true
	var creatureOn:Int = 0
	
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
		//start the turn for the active people specifically
		for cr in activeArray
		{
			cr.startTurn()
		}
	}
	
	private func actionOver()
	{
		//TODO: check for victory and defeat
		
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
		}
		else
		{
			creatureOn += 1
		}
		
		//skip turns if you can't act
		if activeCreature.dead || !activeCreature.action
		{
			actionOver()
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
				let dNum = activeCreature.executeAttack(attackTarget)
				delegate?.damageNumber(dNum)
			}
		}
	}
	
	func aiAction()
	{
		//TODO: a more sophisticated AI
		//choosing to use specials
		//ideally it should be capable of aiming buff and healing specials
		//choosing WHICH weapon to use (and not using any weapons if it has none!)
		//etc
		
		var targets = [Creature]()
		for player in players
		{
			if !player.dead
			{
				targets.append(player)
			}
		}
		
		if targets.count == 0
		{
			//TODO: if all players are dead, that means the battle SHOULD be over
			assertionFailure()
		}
		
		let pick = targets[Int(arc4random_uniform(UInt32(players.count)))]
		
		chooseAttack(pick)
	}
	
	func chooseAttack(target:Creature)
	{
		if attackAnimStateSet == nil && !target.dead
		{
			//TODO: tell the player what the active attack is, instead of just picking something at random
			
			let w = activeCreature.validWeapons
			let pick = w[Int(arc4random_uniform(UInt32(w.count)))]
			activeCreature.pickEngagement(pick)
			attackTarget = target
			canCounter = true //TODO: only set to false if it's not an engagement
			
			setAASS()
		}
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
			let dNum = activeCreature.executeAttack(attackTarget)
			delegate?.damageNumber(dNum)
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
}