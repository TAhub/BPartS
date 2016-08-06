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
		
		//make scene
		let scene = GameScene(size: gameView.bounds.size)
		scene.flipNode = SKNode()
		scene.flipNode.yScale = -1
		scene.flipNode.position = CGPoint(x: 0, y: gameView.bounds.size.height)
		scene.scaleMode = .AspectFill
		scene.addChild(scene.flipNode)
		gameView.presentScene(scene)
		
		
		let height:CGFloat = 400
		
		
		
		//make the terrain
		let shape = SKShapeNode(rect: CGRect(x: 0, y: height - 20, width: 700, height: 900))
		shape.fillColor = UIColor.brownColor()
		shape.strokeColor = UIColor.darkGrayColor()
		scene.flipNode.addChild(shape)
		
		
		//make the game
		let game = Game()
		game.players.append(Creature(creatureType: "engineer", player: true))
		game.players.append(Creature(creatureType: "robot", player: true))
		game.players.append(Creature(creatureType: "grappler", player: true))
		game.enemies.append(Creature(creatureType: "engineer", player: false))
		game.enemies.append(Creature(creatureType: "robot", player: false))
		game.enemies.append(Creature(creatureType: "grappler", player: false))
		scene.game = game
		game.delegate = scene
		
		
		//make creature controllers for the creatures
		func makeCC(array:[Creature], xStart:CGFloat, xOff:CGFloat, flipped:Bool)
		{
			for (i, cr) in array.enumerate()
			{
				let cc = CreatureController(rootNode: scene.flipNode, creature: cr, position: CGPointMake(xStart + xOff * CGFloat(i), height))
				if flipped
				{
					cc.flipped = true
				}
				scene.creatureControllers.append(cc)
			}
		}
		makeCC(game.players, xStart: 50, xOff: 75, flipped: false)
		makeCC(game.enemies, xStart: gameView.frame.size.width - 50, xOff: -75, flipped: true)
		
		
		//and start everything
		game.start()
	}
}