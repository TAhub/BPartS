//
//  MapGenerator.swift
//  BPartS
//
//  Created by Theodore Abshire on 8/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

let relativeLevelAdjustFactor:CGFloat = 0.05

//TODO: move the room structure to a map class
class Room
{
	let x:Int
	let y:Int
	weak var north:Room?
	weak var east:Room?
	weak var west:Room?
	weak var south:Room?
	
	//TODO: encounter data
	//TODO: room type data
	
	init(x:Int, y:Int)
	{
		self.x = x
		self.y = y
	}
}

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
	
	static func generateRooms()
	{
		var rooms = [Room]()
		var failed = false
		
		//constants
		let branchLength = 5
		let mapLength = 20
		
		func recursiveRoomGenerate(x x:Int, y:Int, branchType:String?, obligations:[String], lengthLeft:Int, roomFrom:Room?)
		{
			if failed
			{
				return
			}
			
			let room = Room(x: x, y: y)
			rooms.append(room)
			
			if let roomFrom = roomFrom
			{
				//TODO: set the north, south, etc properties of both room and roomFrom to link them to each other
				
				if lengthLeft == 0
				{
					if let branchType = branchType
					{
						//TODO: make this a special room type, based on the branch type
						//IE a key branch will have a key here, etc
					}
					else
					{
						//TODO: make this the exit room
					}
					return
				}
			}
			else
			{
				//TODO: make room into a start room type
			}
			
			
			var possibleMoves = [(Int, Int)]()
			//TODO: find every possible direction you can expand (AKA, direction without a room already there)
			
			if possibleMoves.count == 0
			{
				failed = true
				return
			}
			
			//TODO: randomly re-order the possible moves
			
			let mustFulfillObligation = obligations.count >= lengthLeft - 1 //if you get too close to the end, do nothing but fulfill obligations
			var obligations = obligations
			if possibleMoves.count >= 2 && branchType == nil && !mustFulfillObligation //TODO: only have a chance of doing this; maybe a max number of branches too?
			{
				let branchMove = possibleMoves[1]
				let branchType = "key" //TODO: pick a branch type
				//TODO: branch types should have associated information; like the color of the key for a key branch, etc
				obligations.append(branchType)
				recursiveRoomGenerate(x: branchMove.0, y: branchMove.1, branchType: branchType, obligations: [String](), lengthLeft: branchLength, roomFrom: room)
			}
			else if obligations.count > 0
			{
				//TODO: there should be a chance to remove one obligation and "fulfill" it
				//unless mustFulfillObligation is true, then it should be a 100% chance
				//IE a "key" obligation turns this into a gate room that requires a key to move to the next room
			}
			
			let nextMove = possibleMoves[0]
			recursiveRoomGenerate(x: nextMove.0, y: nextMove.1, branchType: nil, obligations: obligations, lengthLeft: lengthLeft - 1, roomFrom: room)
		}
		
		recursiveRoomGenerate(x: 0, y: 0, branchType: nil, obligations: [String](), lengthLeft: mapLength, roomFrom: nil)
		
		if failed
		{
			//TODO: try again
		}
		else
		{
			//TODO: return the rooms I guess
		}
	}
}