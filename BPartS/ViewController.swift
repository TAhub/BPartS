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
		
		let shape = SKShapeNode(rect: CGRect(x: 50, y: 300, width: 600, height: 100))
		shape.fillColor = UIColor.blueColor()
		flipNode.addChild(shape)
		
		let game = Game()
		game.players.append(Creature(race: "human"))
		game.enemies.append(Creature(race: "human"))
		for (i, cr) in (game.players + game.enemies).enumerate()
		{
			let cc = CreatureController(rootNode: flipNode, creature: cr, position: CGPoint(x: 100 + 100 * i, y: 300))
			scene.creatureControllers.append(cc)
		}
		scene.game = game
		
		game.start()
	}
}