//
//  GameScene.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

//TODO: select distance, aura size, and player spacing should probably all be based on some single variable
let returnToNeutralTime:CGFloat = 0.4
let selectDistance:CGFloat = 75
let textDistance:CGFloat = 150
let textTime:Double = 0.75
let effectTime:Double = 0.15

class UILabelNode:SKLabelNode
{
	var weapon:Weapon?
	var special:Special?
	
	init(text:String)
	{
		super.init()
		self.text = text
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class GameScene: SKScene, GameDelegate
{
	private var lastTime:NSTimeInterval?
	var creatureControllers = [CreatureController]()
	var game:Game!
	var lastPow:Int = 0
	var flipNode:SKNode!
	var attackSelectNode:SKNode?
	
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
		//should you regenerate the attack select node?
		if attackSelectNode == nil && game.playersActive && game.attackAnimStateSet == nil
		{
			generateAttackSelect()
		}
		
		
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
			
			applyAnimations()
			
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
			
			applyAnimations()
		}
		lastTime = currentTime
	}
	
	private func applyAnimations()
	{
		if let attackAnimStateSet = game.attackAnimStateSet
		{
			//you're doing an attack animation!
			let state = attackAnimStateSet[game.attackAnimStateSetProgress]
			if let myFrame = state.myFrame
			{
				controllerFor(game.activeCreature).setBodyState(myFrame, length: state.entryTime, hold: state.holdTime)
			}
			if var theirFrame = state.theirFrame
			{
				//switch flinches to defend if the person defended
				if theirFrame == "flinch" && lastPow == 0
				{
					theirFrame = "defend"
				}
				
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
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
	{
		//can you give orders?
		if !game.playersActive || game.attackAnimStateSet != nil
		{
			return
		}
		
		let touch = touches.first!
		
		let buttonPosition = touch.locationInNode(self)
		if let node = self.nodeAtPoint(buttonPosition) as? UILabelNode, let attackSelectNode = attackSelectNode
		{
			//is it a direct child of attackSelectNode?
			if node.parent === attackSelectNode
			{
				print("Selected \(node.text!)")
				if let weapon = node.weapon
				{
					game.activeCreature.pickEngagement(weapon)
					generateAttackSelect()
				}
				else if let special = node.special
				{
					game.activeCreature.pickAttack(special)
					generateAttackSelect()
				}
				return
			}
		}
		
		let location = touch.locationInNode(flipNode)
		
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
			if game.chooseAttack(closest)
			{
				//remove the attack select node
				attackSelectNode?.removeFromParent()
				attackSelectNode = nil
				
				//apply animations
				applyAnimations()
			}
		}
	}
	
	private func generateAttackSelect()
	{
		//remove the attack select node if it exists
		self.attackSelectNode?.removeFromParent()
		self.attackSelectNode = nil
		
		let attackSelectNode = SKNode()
		self.attackSelectNode = attackSelectNode
		self.addChild(attackSelectNode)
		
		let startHeight:CGFloat = 420
		let widthDivider:CGFloat = 30
		
		var nextWidth:CGFloat = 0
		var widthAt:CGFloat = 0
		var heightAt:CGFloat = 0
		func addNode(text: String, weapon:Weapon?, special:Special?)
		{
			let node = UILabelNode(text: text)
			attackSelectNode.addChild(node)
			node.position = CGPoint(x: widthAt + node.frame.size.width / 2, y: heightAt - node.frame.size.height / 2)
			heightAt -= node.frame.size.height
			nextWidth = max(node.frame.size.width, nextWidth)
			
			var selected:Bool = false
			if let weapon = weapon
			{
				node.weapon = weapon
				selected = game.activeCreature.activeAttack == nil && game.activeCreature.activeWeapon != nil && weapon === game.activeCreature.activeWeapon!
			}
			else if let special = special
			{
				node.special = special
				selected = game.activeCreature.activeAttack != nil && special === game.activeCreature.activeAttack!
			}
			
			node.fontColor = selected ? UIColor.whiteColor() : UIColor.lightGrayColor()
		}
		
		heightAt = startHeight
		addNode("WEAPONS", weapon: nil, special: nil)
		for weapon in game.activeCreature.validWeapons
		{
			addNode(weapon.battleName, weapon: weapon, special: nil)
		}
		
		heightAt = startHeight
		widthAt += nextWidth + widthDivider
		nextWidth = 0
		addNode("SPECIALS", weapon: nil, special: nil)
		for special in game.activeCreature.validSpecials
		{
			addNode(special.type, weapon: nil, special: special)
		}
	}
	
	//MARK: delegate actions
	func attackAnim(number:Int, hitLimb:CreatureLimb)
	{
		let attackerController = controllerFor(game.activeCreature)
		let targetController = controllerFor(game.attackTarget)
		
		lastPow = number
		
		//display damage number
		let tNode = SKLabelNode(text: "\(number)")
		
		let position = flipNode.convertPoint(targetController.creatureNode.position, toNode: self)
		tNode.position = CGPoint(x: position.x, y: position.y)
		self.addChild(tNode)
		
		let moveAnim = SKAction.moveTo(CGPoint(x: position.x, y: position.y + textDistance), duration: textTime)
		let fadeAnim = SKAction.fadeAlphaTo(0.1, duration: textTime)
		tNode.runAction(SKAction.group([moveAnim, fadeAnim]))
		{
			tNode.removeFromParent()
		}
		
		//make bullet effect
		var effect:SKShapeNode?
		if let special = game.activeCreature.activeAttack
		{
			effect = attackerController.makeEffectForSpecial(special, toController: targetController, toLimb: hitLimb)
		}
		else if let weapon = game.activeCreature.activeWeapon
		{
			effect = attackerController.makeEffectForWeapon(weapon, toController: targetController, toLimb: hitLimb)
		}
		if let effect = effect
		{
			let effectFadeAnim = SKAction.fadeAlphaTo(0.5, duration: effectTime)
			flipNode.addChild(effect)
			effect.runAction(effectFadeAnim)
			{
				effect.removeFromParent()
			}
		}
	}
}