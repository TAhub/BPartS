//
//  ViewController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

class ViewController: UIViewController {
	
	@IBOutlet weak var gameView: SKView!

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		let scene = GameScene(size: gameView.bounds.size)
		let flipNode = SKNode()
		flipNode.yScale = -1
		flipNode.position = CGPoint(x: 0, y: gameView.bounds.size.height)
		scene.scaleMode = .AspectFill
		scene.addChild(flipNode)
		gameView.presentScene(scene)
		
		
		let shape = SKShapeNode(rect: CGRect(x: 100, y: 300, width: 200, height: 100))
		shape.fillColor = UIColor.blueColor()
		flipNode.addChild(shape)
		
		let cr1 = Creature(race: "human")
		let cr2 = Creature(race: "human")
		let cc1 = CreatureController(rootNode: flipNode, creature: cr1, position: CGPoint(x: 150, y: 300))
		let cc2 = CreatureController(rootNode: flipNode, creature: cr2, position: CGPoint(x: 250, y: 300))
		scene.creatureControllers.append(cc1)
		scene.creatureControllers.append(cc2)
//		cc1.setBodyState("bow")
//		cc2.setBodyState("bow")
	}
}