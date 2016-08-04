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
		let flipNode = SKNode()
		flipNode.yScale = -1
		flipNode.position = CGPoint(x: 0, y: gameView.bounds.size.height)
		scene.scaleMode = .AspectFill
		scene.addChild(flipNode)
		gameView.presentScene(scene)
		
		
		//make the terrain
		let shape = SKShapeNode(rect: CGRect(x: 0, y: 290, width: 700, height: 900))
		shape.fillColor = UIColor.brownColor()
		shape.strokeColor = UIColor.darkGrayColor()
		flipNode.addChild(shape)
		
		
		//make UI
		//TODO: make UI
		
		
		//make the game
		let game = Game()
		game.players.append(Creature(race: "human"))
		game.players.append(Creature(race: "human"))
		game.players.append(Creature(race: "human"))
		game.enemies.append(Creature(race: "human"))
		game.enemies.append(Creature(race: "human"))
		game.enemies.append(Creature(race: "human"))
		scene.game = game
		
		
		//make creature controllers for the creatures
		func makeCC(array:[Creature], xStart:CGFloat, xOff:CGFloat, flipped:Bool)
		{
			for (i, cr) in array.enumerate()
			{
				let cc = CreatureController(rootNode: flipNode, creature: cr, position: CGPointMake(xStart + xOff * CGFloat(i), 300))
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