//
//  GameScene.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

class GameScene: SKScene
{
	private var lastTime:NSTimeInterval?
	var creatureControllers = [CreatureController]()
	
	override func update(currentTime: NSTimeInterval)
	{
		if let lastTime = lastTime
		{
			let elapsed = CGFloat(currentTime - lastTime)
			for cc in creatureControllers
			{
				cc.animate(elapsed)
			}
		}
		lastTime = currentTime
	}
}