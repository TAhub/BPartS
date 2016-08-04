//
//  GameScene.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

//TODO: select distance, aura size, and player spacing should probably all be based on the single variable
let returnToNeutralTime:CGFloat = 0.4
let selectDistance:CGFloat = 75

class GameScene: SKScene
{
	private var lastTime:NSTimeInterval?
	var creatureControllers = [CreatureController]()
	var game:Game!
	
	private func controllerFor(creature:Creature) -> CreatureController
	{
		for cc in creatureControllers
		{
			if cc.creature === creature
			{
				return cc
			}
		}
		assertionFailure()
		return creatureControllers[0]
	}
	override func update(currentTime: NSTimeInterval)
	{
		if let lastTime = lastTime
		{
			let elapsed = CGFloat(currentTime - lastTime)
			var anyoneAnimating = false
			for cc in creatureControllers
			{
				cc.animate(elapsed, active: game.activeCreature === cc.creature)
				anyoneAnimating = anyoneAnimating || cc.animating
			}
			
			game.update(elapsed, animating: anyoneAnimating)
			
			//apply animations to people
			if let attackAnimStateSet = game.attackAnimStateSet
			{
				//you're doing an attack animation!
				let state = attackAnimStateSet[game.attackAnimStateSetProgress]
				if let myFrame = state.myFrame
				{
					controllerFor(game.activeCreature).setBodyState(myFrame, length: state.entryTime, hold: state.holdTime)
				}
				if let theirFrame = state.theirFrame
				{
					//TODO: if the game reports a "defend" from the most recent pow, and this is "flinch"
					//set it to "defend"
					
					controllerFor(game.attackTarget).setBodyState(theirFrame, length: state.entryTime, hold: state.holdTime)
				}
				
				//TODO: temporarily apply flips to people to ensure that are facing the right direction during these animations
				//so that if you use a healing ability on an ally, they turn to you
				//etc
			}
			else
			{
				for creature in game.players + game.enemies
				{
					controllerFor(creature).setBodyState(creature.restingState, length: returnToNeutralTime, hold: 0)
				}
			}
			
			//pick attacks, if appropriate
			if game.attackAnimStateSet == nil
			{
				if game.playersActive
				{
					//TODO: wait for orders
				}
				else
				{
					game.aiAction()
				}
			}
		}
		lastTime = currentTime
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
	{
		let touch = touches.first!
		let location = touch.locationInNode(self)
		
		//find the closest enemy
		var closestDistance:CGFloat = selectDistance
		var closest:Creature!
		var closestPlayer:Bool = false
		for (i, cc) in self.creatureControllers.enumerate()
		{
			let xD = location.x - cc.creatureNode.position.x
			let yD = location.y - cc.creatureNode.position.y
			let distance = sqrt(xD*xD+yD*yD)
			if distance < closestDistance
			{
				closestDistance = distance
				closest = cc.creature
				closestPlayer = i < game.players.count
			}
		}
		
		if closestDistance < selectDistance
		{
			print("Targeted a \(closestPlayer ? "player" : "enemy")!")
			game.chooseAttack(closest)
		}
	}
}