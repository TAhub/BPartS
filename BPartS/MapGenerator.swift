//
//  MapGenerator.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

let relativeLevelAdjustFactor:CGFloat = 0.05

class MapGenerator
{
	static func generateEncounter(encounterData:[Int], areaLevel:Int) -> [Creature]
	{
		var creatures = [Creature]()
		for relativeLevelAdjust in encounterData
		{
			let rlaFactor = (1 + CGFloat(relativeLevelAdjust) * relativeLevelAdjustFactor)
			let desiredLevel = Int(((1 + biggerLevelFactor * CGFloat(areaLevel)) * rlaFactor - 1) / biggerLevelFactor)
			
			//TODO: of all of the enemy types in this area, find the two closest to the desired level
			//pick one of them at random, and then level-adjust it to be the desired level
			//TODO: ok so the level-adjustment should probably be inside the creature gen script because it also affects weapon level
		}
		
		
		return creatures
	}
}