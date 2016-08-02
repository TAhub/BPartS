//
//  CreatureController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

class BodyLimb
{
	//information/identity variables
	let name:String
	let parentName:String?
	weak var parent:BodyLimb?
	let spriteNode:SKSpriteNode
	let limbTag:String?
	let centerX:Int
	let centerY:Int
	let connectX:Int
	let connectY:Int
	
	//animation variables
	var rotateFrom:CGFloat = 0
	var rotateTo:CGFloat = 0
	
	//misc flags
	var startFlag = false
	
	init(limbDict:[String : NSObject])
	{
		func intWithName(name:String) -> Int?
		{
			if let num = limbDict[name] as? NSNumber
			{
				return Int(num.intValue)
			}
			return nil
		}
		
		name = limbDict["name"] as! String
		parentName = limbDict["parent"] as? String
		let spriteName = limbDict["sprite name"] as! String
		spriteNode = SKSpriteNode(imageNamed: spriteName)
		limbTag = limbDict["limb tag"] as? String
		centerX = intWithName("center x")!
		centerY = intWithName("center y")!
		connectX = intWithName("connect x")!
		connectY = intWithName("connect y")!
		
		//set sprite node values
		spriteNode.anchorPoint = CGPoint(x: CGFloat(centerX) / spriteNode.size.width, y: CGFloat(centerY) / spriteNode.size.height)
		spriteNode.colorBlendFactor = 1
		
		let h = CGFloat(arc4random_uniform(100)) * 0.01
		let s = CGFloat(arc4random_uniform(50)) * 0.01 + 0.5
		spriteNode.color = UIColor(hue: h, saturation: s, brightness: 1.0, alpha: 1.0)
	}
}

class CreatureController
{
	private var lastBS:String?
	private var creatureNode:SKNode
	
	private let morph:String
	private let states = "human"
	
	private var limbs = [String : BodyLimb]()
	private var masterLimb:BodyLimb!
	
	init(rootNode:SKNode, morph:String, position:CGPoint)
	{
		self.morph = morph
		
		creatureNode = SKNode()
		rootNode.addChild(creatureNode)
		constructBody()
		setBodyState("neutral")
		
		creatureNode.position = position
	}
	
	private func constructBody()
	{
		//clear the limb data in case you are re-constructing the body
		limbs.removeAll()
		creatureNode.removeAllChildren()
		
		//first, read all of the limb data into memory
		let limbArray = DataStore.getArray("BodyMorphs", morph, "limbs") as! [[String : NSObject]]
		for limbDict in limbArray
		{
			let limb = BodyLimb(limbDict: limbDict)
			limbs[limb.name] = limb
			creatureNode.addChild(limb.spriteNode)
		}
		
		//link the limbs to their parents
		for limb in limbs.values
		{
			if let parentName = limb.parentName
			{
				limb.parent = limbs[parentName]
			}
			else
			{
				masterLimb = limb
			}
		}
	}
	
	func animate()
	{
		//TODO: animate smoothly between the body states
	}
	
	func setBodyState(bs:String)
	{
		//TODO: if lastBS isn't nil, transition between the two states over a series of frames
		//don't use built-in animations, because that is a guaranteed way to get horrible problems
		//since I have to just the positions of the nodes manually
		
		//set up the animation variables
		for limb in limbs.values
		{
			limb.rotateFrom = limb.spriteNode.zRotation
			limb.rotateTo = limb.spriteNode.zRotation
		}
		if let state = DataStore.getDictionary("BodyStates", states, bs) as? [String : NSNumber]
		{
			for (limbName, degreeNumber) in state
			{
				if let limb = limbs[limbName]
				{
					limb.rotateTo = CGFloat(M_PI) * CGFloat(degreeNumber.floatValue) / 180
				}
			}
			
			
			//set all of the start flags up
			for limb in limbs.values
			{
				limb.startFlag = true
			}
			
			//set up recursive angle adding algorithm
			func recursiveLimbAngle(limb:BodyLimb)
			{
				if limb.startFlag
				{
					limb.startFlag = false
					if let parent = limb.parent
					{
						recursiveLimbAngle(parent)
						limb.rotateTo += parent.rotateTo
						while limb.rotateTo > CGFloat(M_PI)
						{
							limb.rotateTo -= CGFloat(M_PI) * 2
						}
						while limb.rotateTo < -CGFloat(M_PI)
						{
							limb.rotateTo += CGFloat(M_PI) * 2
						}
					}
				}
			}
			for limb in limbs.values
			{
				recursiveLimbAngle(limb)
			}
		}
		else
		{
			return
		}
		
		//TODO: remove this later; for now I'm just instantly going to the rotateTo positions
		for limb in limbs.values
		{
			limb.spriteNode.zRotation = limb.rotateTo
		}
		
		setPositions()
		
		lastBS = bs
	}
	
	private func setPositions()
	{
		//set all of the start flags up
		for limb in limbs.values
		{
			limb.startFlag = true
		}
		
		//position limbs recursively, using a dynamic programming-esque algorithm
		func recursiveLimbPosition(limb:BodyLimb)
		{
			if limb.startFlag
			{
				limb.startFlag = false
				var x:CGFloat = 0
				var y:CGFloat = 0
				if let parent = limb.parent
				{
					recursiveLimbPosition(parent)
					
					//convert connectX, connectY to a coordinate space based on their center
					let connectX = limb.connectX - parent.centerX
					let connectY = limb.connectY - parent.centerY
					
					//add them to the position, rotated
					let dirAngle = parent.spriteNode.zRotation// + CGFloat(M_PI) / 2
					x += cos(dirAngle) * CGFloat(connectX) - sin(dirAngle) * CGFloat(connectY)
					y += cos(dirAngle) * CGFloat(connectY) + sin(dirAngle) * CGFloat(connectX)
					
					//also add their position
					x += parent.spriteNode.position.x
					y += parent.spriteNode.position.y
				}
				
//				print("\(limb.name): \(x), \(y)")
				limb.spriteNode.position = CGPoint(x: x, y: y)
			}
			
		}
		for limb in limbs.values
		{
			recursiveLimbPosition(limb)
		}
		
		//estimate how far below (0, 0) you are, then adjust accordingly
		var heightAdj:CGFloat = 0
		for limb in limbs.values
		{
			let adj = limb.spriteNode.position.y + limb.spriteNode.size.height - limb.spriteNode.anchorPoint.y
			print("adj \(limb.name): \(adj)")
			heightAdj = max(heightAdj, adj)
		}
		for limb in limbs.values
		{
			limb.spriteNode.position = CGPoint(x: limb.spriteNode.position.x, y: limb.spriteNode.position.y - heightAdj)
		}
	}
}