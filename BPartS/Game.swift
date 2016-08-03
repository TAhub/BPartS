//
//  Game.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/3/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class Game
{
	var players = [Creature]()
	var enemies = [Creature]()
	
	var playersActive:Bool = true
	var creatureOn:Int = 0
	
	var attackAnimStateSet:[AttackAnimState]?
	var attackAnimStateSetProgress:Int = 0
	var attackTarget:Creature!
	
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
				activeCreature.executeAttack(attackTarget)
			}
		}
	}
	
	func chooseAttack(target:Creature)
	{
		if attackAnimStateSet == nil
		{
			//TODO: tell the player what the active attack is
			activeCreature.pickEngagement(Weapon())
			attackTarget = target
			
			if let aASS = activeCreature.attackAnimationStateSet
			{
				attackAnimStateSet = aASS
				attackAnimStateSetProgress = -1
				animComplete()
			}
			else
			{
				//just instantly execute the effect of the attack and call it a day
				activeCreature.executeAttack(attackTarget)
				actionOver()
			}
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