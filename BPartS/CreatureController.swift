//
//  CreatureController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

extension UIColor
{
	static func blendColor(color1:UIColor, color2:UIColor, blendFactor:CGFloat) -> UIColor
	{
		let nBlendFactor = 1-blendFactor
		var r1:CGFloat = 0
		var g1:CGFloat = 0
		var b1:CGFloat = 0
		var a1:CGFloat = 0
		var r2:CGFloat = 0
		var g2:CGFloat = 0
		var b2:CGFloat = 0
		var a2:CGFloat = 0
		color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
		color1.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
		return UIColor(red: r1 * blendFactor + r2 * nBlendFactor,
		               green: g1 * blendFactor + g2 * nBlendFactor,
		               blue: b1 * blendFactor + b2 * nBlendFactor,
		               alpha: a1 * blendFactor + a2 * nBlendFactor)
	}
}

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
	
	init(limbDict:[String : NSObject], coloration:[String : String])
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
		let colorName = limbDict["color name"] as! String
		let blendName = limbDict["blend name"] as! String
		limbTag = limbDict["limb tag"] as? String
		centerX = intWithName("center x")!
		centerY = intWithName("center y")!
		connectX = intWithName("connect x")!
		connectY = intWithName("connect y")!
		
		//set sprite node data
		spriteNode = SKSpriteNode(imageNamed: spriteName)
		spriteNode.anchorPoint = CGPoint(x: CGFloat(centerX) / spriteNode.size.width, y: CGFloat(centerY) / spriteNode.size.height)
		spriteNode.colorBlendFactor = 1
		
		//pick the color, changing the value as appropriate based on the blend name
		let baseColor = DataStore.getColorByName(coloration[colorName]!)!
		var h:CGFloat = 0
		var s:CGFloat = 0
		var v:CGFloat = 0
		var a:CGFloat = 0
		baseColor.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
		
		//TODO: these should probably be constants
		switch(blendName)
		{
		case "back body": v *= 0.85
		case "fore body": break
		default: break
		}
		
		spriteNode.color = UIColor(hue: h, saturation: s, brightness: v, alpha: a)
	}
}

class CreatureController
{
	private var lastBS:String?
	private var animationLength:CGFloat?
	private var animationProgress:CGFloat?
	private var holdLength:CGFloat?
	private var holdProgress:CGFloat?
	private var stopUndulation:Bool = false
	private var vibrate:Bool = false
	
	private let creature:Creature
	private let creatureNode:SKNode
	var morph:String
	{
		//TODO: get the appropriate morph for them, not just the first one
		let morphs = DataStore.getArray("Races", creature.race, "morphs") as! [String]
		return morphs[0]
	}
	var states:String
	{
		return DataStore.getString("Races", creature.race, "states")!
	}
	
	private var limbs = [String : BodyLimb]()
	private var undulations = [String : Undulation]()
	
	//TODO: constants
	let vibrateMagnitude:CGFloat = 3
	
	init(rootNode:SKNode, creature:Creature, position:CGPoint)
	{
		self.creature = creature
		
		creatureNode = SKNode()
		rootNode.addChild(creatureNode)
		constructUndulations()
		constructBody()
		setBodyState("neutral")
		setPositions()
		
		creatureNode.position = position
		
		
		//draw bounding box
//		let bb = getBoundingBox()
//		let bbS = SKShapeNode(rect: bb)
//		bbS.fillColor = UIColor.darkGrayColor()
//		creatureNode.insertChild(bbS, atIndex: 0)
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
		
		//TODO: load the appropriate coloration array
		let colorations = DataStore.getArray("Races", creature.race, "colorations") as! [[String : String]]
		let coloration = colorations[0]
		
		//first, read all of the limb data into memory
		let limbArray = DataStore.getArray("BodyMorphs", morph, "limbs") as! [[String : NSObject]]
		for limbDict in limbArray
		{
			let limb = BodyLimb(limbDict: limbDict, coloration: coloration)
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
			if let undulationName = limb.undulationName
			{
				limb.undulation = undulations[undulationName]
			}
		}
	}
	
	var animating:Bool
	{
		return animationLength != nil || animationProgress != nil || holdLength != nil || holdProgress != nil
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
			}
		}
		else if holdLength != nil || holdProgress != nil
		{
			holdProgress! += elapsed
			if holdProgress! >= holdLength!
			{
				//you're done holding
				holdProgress = nil
				holdLength = nil
				
				//TODO: SO YOU SHOULD START THE NEXT ANIMATION, DUN DUN DUN
//				let ar = ["neutral", "cranekick", "bow", "fencing", "flinch", "defend", "sitting"]
//				while true
//				{
//					let pick = ar[Int(arc4random_uniform(UInt32(ar.count)))]
//					if pick != lastBS!
//					{
//						setBodyState(pick)
//						break
//					}
//				}
			}
		}
		
		//move undulation timers forward
		if !stopUndulation || !applyFlags
		{
			for undulation in undulations.values
			{
				undulation.animate(elapsed)
			}
		}
		
		setPositions()
	}
	
	private var applyFlags:Bool
	{
		if let animationLength = animationLength, let animationProgress = animationProgress
		{
			return animationProgress > animationLength / 2
		}
		return true
	}
	
	func setBodyState(bs:String)
	{
		if lastBS != nil && lastBS! != bs
		{
			animationLength = 0.2
			animationProgress = 0
		}
		holdLength = 0.5
		holdProgress = 0
		
		//reset flags
		stopUndulation = false
		vibrate = false
		
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
				//check for flags
				switch(limbName)
				{
				case "stop undulation":
					stopUndulation = true
				case "vibrate":
					vibrate = true
				default:
					if let limb = limbs[limbName]
					{
						limb.rotateTo = CGFloat(M_PI) * CGFloat(degreeNumber.floatValue) / 180
					}
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
					x += cos(parent.spriteNode.zRotation) * CGFloat(connectX) - sin(parent.spriteNode.zRotation) * CGFloat(connectY)
					y += cos(parent.spriteNode.zRotation) * CGFloat(connectY) + sin(parent.spriteNode.zRotation) * CGFloat(connectX)
					
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
		
		//use the bounding box to estimate how far below (0, 0) you are, then adjust accordingly
		var yAdj:CGFloat = getBoundingBox().maxY
		var xAdj:CGFloat = 0
		if vibrate && applyFlags
		{
			//add some randomness
			xAdj += (CGFloat(arc4random_uniform(200)) - 100) * 0.01 * vibrateMagnitude
			yAdj += (CGFloat(arc4random_uniform(200)) - 100) * 0.01 * vibrateMagnitude
		}
		for limb in limbs.values
		{
			limb.spriteNode.position = CGPoint(x: limb.spriteNode.position.x - xAdj, y: limb.spriteNode.position.y - yAdj)
		}
	}
	
	private func getBoundingBox() -> CGRect
	{
		var minX:CGFloat = 999999
		var maxX:CGFloat = -999999
		var minY:CGFloat = 999999
		var maxY:CGFloat = -999999
		for limb in limbs.values
		{
			func transformCheck(pX pX:CGFloat, pY:CGFloat)
			{
				let cX = limb.spriteNode.position.x
				let cY = limb.spriteNode.position.y
				let a = limb.spriteNode.zRotation
				let newX = cX + (pX - cX) * cos(a) - (pY - cY) * sin(a)
				let newY = cY + (pX - cX) * sin(a) + (pY - cY) * cos(a)
				
				minX = min(minX, newX)
				maxX = max(maxX, newX)
				minY = min(minY, newY)
				maxY = max(maxY, newY)
			}
			let left = limb.spriteNode.position.x - limb.spriteNode.anchorPoint.x * limb.spriteNode.size.width
			let top = limb.spriteNode.position.y - limb.spriteNode.anchorPoint.y * limb.spriteNode.size.height
			let right = left + limb.spriteNode.size.width
			let bottom = top + limb.spriteNode.size.height
			transformCheck(pX: left, pY: top)
			transformCheck(pX: right, pY: top)
			transformCheck(pX: left, pY: bottom)
			transformCheck(pX: right, pY: bottom)
		}
		return CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
	}
}