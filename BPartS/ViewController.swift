//
//  ViewController.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import SpriteKit

//spacing info
let creatureOffset:CGFloat = 75
let auraWidth:CGFloat = 125.0
let auraHeight:CGFloat = 60.0
let selectDistance:CGFloat = 75
let barHeight:CGFloat = 12
let barYOff:CGFloat = 20
let barWidth:CGFloat = 34
let energyIconSize:CGFloat = 5
let energyIconSpacing:CGFloat = 2
let maxEnergyIconsPerRow:Int = 4
let strainIndicatorWidth:CGFloat = 30
let strainIndicatorHeight:CGFloat = 30
let uiElementSeparation:CGFloat = 4


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
		
		
		let height:CGFloat = 375
		
		
		
		//make the terrain
		let shape = SKShapeNode(rect: CGRect(x: 0, y: height - 20, width: 700, height: 900))
		shape.fillColor = UIColor.brownColor()
		shape.strokeColor = UIColor.darkGrayColor()
		scene.flipNode.addChild(shape)
		
		
		//make the game
		let game = Game()
		game.players.append(Creature(creatureType: "engineer", player: true, sideAmmo: game.playersAmmo))
		game.players.append(Creature(creatureType: "drifter", player: true, sideAmmo: game.playersAmmo))
		game.players.append(Creature(creatureType: "grappler", player: true, sideAmmo: game.playersAmmo))
		game.players.append(Creature(creatureType: "robot", player: true, sideAmmo: game.playersAmmo))
		game.enemies.append(Creature(creatureType: "engineer", player: false, sideAmmo: game.enemiesAmmo))
		game.enemies.append(Creature(creatureType: "drifter", player: false, sideAmmo: game.enemiesAmmo))
		game.enemies.append(Creature(creatureType: "grappler", player: false, sideAmmo: game.enemiesAmmo))
		game.enemies.append(Creature(creatureType: "robot", player: false, sideAmmo: game.enemiesAmmo))
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
		makeCC(game.players, xStart: 50, xOff: creatureOffset, flipped: false)
		makeCC(game.enemies, xStart: gameView.frame.size.width - 50, xOff: -creatureOffset, flipped: true)
		
		
		//and start everything
		game.start()
	}
}