//
//  CreatureController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

class Undulation
{
	let magnitude:CGFloat
	let wavelength:CGFloat
	var timer:CGFloat
	
	init(undulateDict:[String : NSNumber])
	{
		magnitude = CGFloat(undulateDict["magnitude"]!.floatValue) * 0.01
		wavelength = CGFloat(undulateDict["wavelength"]!.floatValue) * 0.01
		
		//set up undulation data
		let phase = CGFloat(undulateDict["phase"]!.floatValue) * 0.01
		timer = wavelength * phase
	}
	
	func animate(elapsed:CGFloat)
	{
		if magnitude > 0
		{
			timer += elapsed
			if timer > wavelength
			{
				timer -= wavelength
			}
		}
	}
	
	var offset:CGFloat
	{
		let progress = timer * 4 / wavelength
		var mult:CGFloat
		if progress < 1
		{
			mult = progress
		}
		else if progress < 2
		{
			mult = 1 - (progress - 1)
		}
		else if progress < 3
		{
			mult = -(progress - 2)
		}
		else
		{
			mult = (progress - 3) - 1
		}
		
		return magnitude * mult
	}
}

class BodyLimb
{
	//information/identity variables
	let name:String
	let parentName:String?
	weak var parent:BodyLimb?
	let undulationName:String?
	weak var undulation:Undulation?
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
		
		//get constants
		name = limbDict["name"] as! String
		parentName = limbDict["parent"] as? String
		undulationName = limbDict["undulation"] as? String
		let spriteName = limbDict["sprite name"] as! String
		limbTag = limbDict["limb tag"] as? String
		centerX = intWithName("center x")!
		centerY = intWithName("center y")!
		connectX = intWithName("connect x")!
		connectY = intWithName("connect y")!
		
		//set sprite node data
		spriteNode = SKSpriteNode(imageNamed: spriteName)
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
	private var animationLength:CGFloat?
	private var animationProgress:CGFloat?
	
	private let creatureNode:SKNode
	private let morph:String
	private let states = "human"
	
	private var limbs = [String : BodyLimb]()
	private var undulations = [String : Undulation]()
	private var masterLimb:BodyLimb!
	
	init(rootNode:SKNode, morph:String, position:CGPoint)
	{
		self.morph = morph
		
		creatureNode = SKNode()
		rootNode.addChild(creatureNode)
		constructUndulations()
		constructBody()
		setBodyState("neutral")
		setPositions()
		
		creatureNode.position = position
	}
	
	private func constructUndulations()
	{
		let undulationDict = DataStore.getDictionary("BodyMorphs", morph, "undulations") as! [String : [String : NSNumber]]
		for (name, dict) in undulationDict
		{
			undulations[name] = Undulation(undulateDict: dict)
		}
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
		
		//link the limbs to their parents and undulations
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
			if let undulationName = limb.undulationName
			{
				limb.undulation = undulations[undulationName]
			}
		}
	}
	
	func animate(elapsed:CGFloat)
	{
		if animationLength != nil && animationProgress != nil
		{
			animationProgress! += elapsed
			if animationProgress > animationLength!
			{
				animationProgress = animationLength!
			}
			
			let progress = animationProgress! / animationLength!
			
			//set body part rotations
			for limb in limbs.values
			{
				//figure out which direction to rotate
				let forwardDistance:CGFloat
				let backwardDistance:CGFloat
				if limb.rotateTo > limb.rotateFrom
				{
					forwardDistance = limb.rotateTo - limb.rotateFrom
					backwardDistance = limb.rotateFrom + 2 * CGFloat(M_PI) - limb.rotateTo
				}
				else if limb.rotateTo < limb.rotateFrom
				{
					forwardDistance = 2 * CGFloat(M_PI) - limb.rotateFrom + limb.rotateTo
					backwardDistance = limb.rotateFrom - limb.rotateTo
				}
				else
				{
					//no animation
					forwardDistance = 0
					backwardDistance = 0
				}
				
				if forwardDistance != 0 && backwardDistance != 0
				{
					if forwardDistance <= backwardDistance
					{
						limb.spriteNode.zRotation = limb.rotateFrom + forwardDistance * progress
					}
					else
					{
						limb.spriteNode.zRotation = limb.rotateFrom - backwardDistance * progress
					}
					while limb.spriteNode.zRotation >= 2 * CGFloat(M_PI)
					{
						limb.spriteNode.zRotation -= 2 * CGFloat(M_PI)
					}
					while limb.spriteNode.zRotation < 0
					{
						limb.spriteNode.zRotation += 2 * CGFloat(M_PI)
					}
				}
			}
			
			//if the animation is over, end it
			if animationProgress! == animationLength!
			{
				animationProgress = nil
				animationLength = nil
				
				//TODO: AND THEN START THE NEXT ONE, DUN DUN DUN
				let ar = ["neutral", "cranekick", "bow", "fencing"]
				while true
				{
					let pick = ar[Int(arc4random_uniform(UInt32(ar.count)))]
					if pick != lastBS!
					{
						setBodyState(pick)
						break
					}
				}
			}
		}
		
		//move undulation timers forward
		for undulation in undulations.values
		{
			undulation.animate(elapsed)
		}
		
		setPositions()
	}
	
	func setBodyState(bs:String)
	{
		if lastBS != nil && lastBS! != bs
		{
			animationLength = 0.65
			animationProgress = 0
		}
		
		//set up the animation variables
		for limb in limbs.values
		{
			limb.rotateFrom = limb.spriteNode.zRotation
			limb.rotateTo = 0
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
					}
				}
			}
			for limb in limbs.values
			{
				recursiveLimbAngle(limb)
			}
			
			//bound all rotation values
			for limb in limbs.values
			{
				while limb.rotateTo >= 2 * CGFloat(M_PI)
				{
					limb.rotateTo -= 2 * CGFloat(M_PI)
				}
				while limb.rotateTo < 0
				{
					limb.rotateTo += 2 * CGFloat(M_PI)
				}
			}
		}
		else
		{
			return
		}
		
		//if there's no animation, just insta-rotate the limbs
		if animationLength == nil
		{
			for limb in limbs.values
			{
				limb.spriteNode.zRotation = limb.rotateTo
			}
		}
		
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
				
				//add undulation to it
				y += limb.undulation?.offset ?? 0
				
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
			heightAdj = max(heightAdj, adj)
		}
		for limb in limbs.values
		{
			limb.spriteNode.position = CGPoint(x: limb.spriteNode.position.x, y: limb.spriteNode.position.y - heightAdj)
		}
	}
}