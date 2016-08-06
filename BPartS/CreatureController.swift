//
//  CreatureController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

let auraWidth:CGFloat = 125.0
let auraHeight:CGFloat = 60.0

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

class CreatureLimbMemory
{
	private var armor:String?
	private var broken:Bool
	
	init(creatureLimb:CreatureLimb)
	{
		armor = creatureLimb.armor
		broken = creatureLimb.broken
	}
	func compare(creatureLimb:CreatureLimb) -> Bool
	{
		if (armor == nil) != (creatureLimb.armor == nil)
		{
			return false
		}
		if let armor = armor, let cArmor = creatureLimb.armor
		{
			if armor != cArmor
			{
				return false
			}
		}
		return broken == creatureLimb.broken
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
	let creatureLimb:CreatureLimb?
	let weaponLimb:Bool
	var invisible:Bool
	
	//animation variables
	var rotateFrom:CGFloat = 0
	var rotateTo:CGFloat = 0
	
	
	//misc flags
	var startFlag = false
	
	init(limbDict:[String : NSObject], coloration:[String : String], creatureLimb:CreatureLimb?, morph:String)
	{
		func intWithName(name:String) -> Int?
		{
			if let num = limbDict[name] as? NSNumber
			{
				return Int(num.intValue)
			}
			return nil
		}
		
		self.creatureLimb = creatureLimb
		
		//get constants
		name = limbDict["name"] as! String
		parentName = limbDict["parent"] as? String
		undulationName = limbDict["undulation"] as? String
		var spriteName = limbDict["sprite name"] as! String
		var colorName = limbDict["color name"] as! String
		let blendName = limbDict["blend name"] as! String
		weaponLimb = limbDict["weapon limb"] != nil
		limbTag = limbDict["limb tag"] as? String
		centerX = intWithName("center x")!
		centerY = intWithName("center y")!
		connectX = intWithName("connect x")!
		connectY = intWithName("connect y")!
		
		invisible = true
		if weaponLimb
		{
			if !(creatureLimb?.broken ?? true)
			{
				//it's a weapon limb, so unless you have a weapon it's invisible
				if let weapon = creatureLimb?.weapon
				{
					invisible = false
					spriteName = weapon.sprite
				}
			}
		}
		else
		{
			//it's not a weapon limb, so check to see if it will be replaced by armor
			invisible = limbDict["invisible unless replaced"] != nil
			
			//check what the creature limb's armor will do
			if let creatureLimb = creatureLimb, let armor = creatureLimb.armor
			{
				//does it have anything for this particular limb?
				let morphAppearances = DataStore.getDictionary("Armors", armor, "appearance by morph") as! [String : [String : [String : String]]]
				if let morphAppearance = morphAppearances[morph]
				{
					for (part, partAppearance) in morphAppearance
					{
						//this will take partial matches, so I don't need to separately define each limb
						if name.containsString(part)
						{
							if partAppearance["invisible"] == nil
							{
								spriteName = partAppearance["sprite name"] ?? spriteName
								colorName = partAppearance["color name"] ?? colorName
								invisible = false
							}
							else
							{
								invisible = true
							}
							break
						}
					}
				}
			}
		}
		
		//set sprite node data
		spriteNode = SKSpriteNode(imageNamed: spriteName)
		spriteNode.anchorPoint = CGPoint(x: CGFloat(centerX) / spriteNode.size.width, y: CGFloat(centerY) / spriteNode.size.height)
		spriteNode.colorBlendFactor = 1
		
		if invisible
		{
			spriteNode.hidden = true
		}
		else
		{
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
			case "back body": v *= 0.9
			case "fore body": break
			default: break
			}
			
			spriteNode.color = UIColor(hue: h, saturation: s, brightness: v, alpha: a)
		}
	}
	
	func transformPoint(point:CGPoint) -> CGPoint
	{
		let pX = point.x
		let pY = point.y
		let cX = spriteNode.position.x
		let cY = spriteNode.position.y
		let a = spriteNode.zRotation
		let newX = cX + (pX - cX) * cos(a) - (pY - cY) * sin(a)
		let newY = cY + (pX - cX) * sin(a) + (pY - cY) * cos(a)
		
		return CGPoint(x: newX, y: newY)
	}
	
	var hitRect:CGRect
	{
		let left = spriteNode.position.x - spriteNode.anchorPoint.x * spriteNode.size.width
		let top = spriteNode.position.y - spriteNode.anchorPoint.y * spriteNode.size.height
		let right = left + spriteNode.size.width
		let bottom = top + spriteNode.size.height
		let p1 = transformPoint(CGPoint(x: left, y: top))
		let p2 = transformPoint(CGPoint(x: right, y: bottom))
		let finalX = min(p1.x, p2.x)
		let finalWidth = max(p1.x, p2.x) - finalX
		let finalY = min(p1.y, p2.y)
		let finalHeight = max(p1.y, p2.y) - finalY
		return CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
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
	
	var flipped:Bool = false
	{
		didSet
		{
			flipNode.xScale = flipped ? -1 : 1
		}
	}
	let creature:Creature
	let creatureNode:SKNode
	private let flipNode:SKNode
	private var auraNode:SKShapeNode!
	var morph:String
	{
		return creature.morph
	}
	var states:String
	{
		return DataStore.getString("Races", creature.race, "states")!
	}
	var personality:Int
	{
		return creature.personality
	}
	
	private var limbs = [String : BodyLimb]()
	private var undulations = [String : Undulation]()
	private var memories = [String : CreatureLimbMemory]()
	
	//TODO: constants
	let vibrateMagnitude:CGFloat = 3
	
	init(rootNode:SKNode, creature:Creature, position:CGPoint)
	{
		self.creature = creature
		
		creatureNode = SKNode()
		rootNode.addChild(creatureNode)
		
		flipNode = SKNode()
		creatureNode.addChild(flipNode)
		
		constructUndulations()
		constructBody()
		setBodyState(creature.restingState)
		setPositions()
		
		creatureNode.position = position
		
		for (name, limb) in creature.limbs
		{
			memories[name] = CreatureLimbMemory(creatureLimb: limb)
		}
		
		//draw bounding box
//		let bb = getBoundingBox()
//		let bbS = SKShapeNode(rect: bb)
//		bbS.fillColor = UIColor.darkGrayColor()
//		flipNode.insertChild(bbS, atIndex: 0)
		
		//make the aura node
		auraNode = SKShapeNode(ellipseOfSize: CGSize(width: auraWidth / 2, height: auraHeight / 2))
		creatureNode.insertChild(auraNode, atIndex: 0)
		auraNode.alpha = 0
	}
	
	private func setAuraNodeColor(active:Bool)
	{
		auraNode.fillColor = active ? UIColor.whiteColor() : (creature.action ? UIColor.lightGrayColor() : UIColor.darkGrayColor())
		auraNode.alpha = 0.5
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
		flipNode.removeAllChildren()
		
		//TODO: load the appropriate coloration array
		let colorations = DataStore.getArray("Races", creature.race, "colorations") as! [[String : String]]
		let coloration = colorations[creature.coloration]
		
		//first, read all of the limb data into memory
		let limbArray = DataStore.getArray("BodyMorphs", morph, "limbs") as! [[String : NSObject]]
		for limbDict in limbArray
		{
			//get the correct creature limb for this limb
			var cL:CreatureLimb?
			if let tag = limbDict["limb tag"] as? String
			{
				cL = creature.limbs[tag]!
			}
			
			let limb = BodyLimb(limbDict: limbDict, coloration: coloration, creatureLimb: cL, morph: morph)
			limbs[limb.name] = limb
			flipNode.addChild(limb.spriteNode)
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
	
	private func setRotations()
	{
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
	}
	
	func animate(elapsed:CGFloat, active:Bool)
	{
		setAuraNodeColor(active)
		
		if animationLength != nil && animationProgress != nil
		{
			animationProgress! += elapsed
			if animationProgress > animationLength!
			{
				animationProgress = animationLength!
			}
			
			setRotations()
			
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
			}
		}
		
		if !animating
		{
			//now that the anim is over, check to see if you need to remake your body any
			
			var change = false
			for limb in creature.limbs.values
			{
				let memory = memories[limb.name]!
				if !memory.compare(limb)
				{
					change = true
					break
				}
			}
			
			if change
			{
				//remake your memories
				memories.removeAll()
				for (name, limb) in creature.limbs
				{
					memories[name] = CreatureLimbMemory(creatureLimb: limb)
				}
				
				//remake the body
				constructBody()
				
				//and snap to the new position
				let bs = lastBS!
				lastBS = nil
				setBodyState(bs, length: 0, hold: 0)
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
	
	func setBodyState(bs:String, length:CGFloat = 0.2, hold:CGFloat = 0.5)
	{
		if lastBS != nil && lastBS! == bs
		{
			return
		}
		
		if lastBS != nil
		{
			animationLength = length // * 10
			animationProgress = 0
		}
		holdLength = hold // * 10
		holdProgress = 0
		
		//reset flags
		stopUndulation = false
		vibrate = false
		var hideWeapons = false
		
		//set up the animation variables
		for limb in limbs.values
		{
			limb.rotateFrom = limb.spriteNode.zRotation
			limb.rotateTo = 0
		}
		
		
		let state = DataStore.getDictionary("BodyStates", states, bs) as! [String : NSNumber]
		var finalState = state
		if let baseStateNumber = state["base pose"]
		{
			//retrieve the base state
			var baseStateInt = Int(baseStateNumber.intValue)
			
			if baseStateInt == -1
			{
				//use their personality value
				baseStateInt = personality
			}
			
			
			let baseState = DataStore.getDictionary("BodyStates", states, "base pose \(baseStateInt)") as! [String : NSNumber]
			
			//write over the base state with the main state
			finalState = baseState
			for (limbName, degreeNumber) in state
			{
				finalState[limbName] = degreeNumber
			}
		}
		
		for (limbName, degreeNumber) in finalState
		{
			//check for flags
			switch(limbName)
			{
			case "stop undulation": stopUndulation = true
			case "vibrate": vibrate = true
			case "hide weapons": hideWeapons = true
			case "base pose": break
			default:
				if let limb = limbs[limbName]
				{
					limb.rotateTo = CGFloat(M_PI) * CGFloat(degreeNumber.floatValue) / 180
				}
			}
		}
		
		//hide weapons based on the hideWeapon variable
		for limb in limbs.values
		{
			if limb.weaponLimb && !limb.invisible
			{
				limb.spriteNode.hidden = hideWeapons
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
	
	func getBoundingBox() -> CGRect
	{
		var minX:CGFloat = 999999
		var maxX:CGFloat = -999999
		var minY:CGFloat = 999999
		var maxY:CGFloat = -999999
		for limb in limbs.values
		{
			func transformCheck(pX pX:CGFloat, pY:CGFloat)
			{
				let newPoint = limb.transformPoint(CGPoint(x: pX, y: pY))
				let newX = newPoint.x
				let newY = newPoint.y
				
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
	
	private func makeEffect(muzzleX muzzleX:Int, muzzleY:Int, effectColor:UIColor, limb:BodyLimb, toController:CreatureController, toLimb:CreatureLimb) -> SKShapeNode?
	{
		//find non-invisible, non-weapon body parts on the target to hit
		var possibleHits = [BodyLimb]()
		for limb in toController.limbs.values
		{
			if !limb.weaponLimb && !limb.invisible && limb.creatureLimb != nil && limb.creatureLimb! === toLimb
			{
				possibleHits.append(limb)
			}
		}
		
		if possibleHits.count == 0
		{
			//just get their torso, if they have no targetable limbs at all
			possibleHits.append(toController.limbs["torso"]!)
		}
		
		//find which limb you hit
		let pick = possibleHits.randomElement!
		
		//translate the point into the weapon limb's coordinate space
		let muzzlePoint = limb.transformPoint(CGPoint(x: CGFloat(muzzleX - limb.centerX) + limb.spriteNode.position.x, y: CGFloat(muzzleY - limb.centerY) + limb.spriteNode.position.y))
		
		//find the center of the limb you hit
		let hitRect = pick.hitRect
		let hitPoint = CGPoint(x: hitRect.midX, y: hitRect.midY)
		
		//translate both points to the parent coordinate space
		let muzzlePointFinal = flipNode.convertPoint(muzzlePoint, toNode: creatureNode.parent!)
		let hitPointFinal = toController.flipNode.convertPoint(hitPoint, toNode: toController.creatureNode.parent!)
		
		//make the path
		let path = CGPathCreateMutable()
		CGPathMoveToPoint(path, nil, muzzlePointFinal.x, muzzlePointFinal.y)
		CGPathAddLineToPoint(path, nil, hitPointFinal.x, hitPointFinal.y)
		
		let line = SKShapeNode(path: path)
		line.strokeColor = effectColor
		return line
	}
	
	func makeEffectForSpecial(special:Special, toController:CreatureController, toLimb:CreatureLimb) -> SKShapeNode?
	{
		if let limbName = special.effectFromMorphLimb, let limb = limbs[limbName], let effectColor = special.effectColor
		{
			return makeEffect(muzzleX: limb.centerX, muzzleY: limb.centerY, effectColor: effectColor, limb: limb, toController: toController, toLimb: toLimb)
		}
		return nil
	}
	
	func makeEffectForWeapon(weapon:Weapon, toController:CreatureController, toLimb:CreatureLimb) -> SKShapeNode?
	{
		//find out which body-part holds that weapon
		var weaponLimb:BodyLimb?
		for limb in limbs.values
		{
			if limb.weaponLimb && limb.creatureLimb != nil && limb.creatureLimb!.weapon != nil && limb.creatureLimb!.weapon! === weapon
			{
				weaponLimb = limb
				break
			}
		}
		
		if let weaponLimb = weaponLimb
		{
			if let muzzleX = weapon.muzzleX, let muzzleY = weapon.muzzleY, let effectColor = weapon.effectColor
			{
				return makeEffect(muzzleX: muzzleX, muzzleY: muzzleY, effectColor: effectColor, limb: weaponLimb, toController: toController, toLimb: toLimb)
			}
			return nil
		}
		
		assertionFailure()
		return nil
	}
}