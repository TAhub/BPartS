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
	
	var cc:CreatureController!

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
		
		
		let shape = SKShapeNode(rect: CGRect(x: 150, y: 200, width: 100, height: 100))
		shape.fillColor = UIColor.blueColor()
		flipNode.addChild(shape)
		
		cc = CreatureController(rootNode: flipNode)
	}
}