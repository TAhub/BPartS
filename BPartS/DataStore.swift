//
//  DataStore.swift
//  Arena
//
//  Created by Theodore Abshire on 6/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class DataStore
{
	private static var plistCache = [String : [NSString : NSObject]]()
	
	
	//MARK: internal functions
	static func getPlist(plist:String) -> [NSString : NSObject]
	{
		if let cached = plistCache[plist]
		{
			return cached
		}
		
		if let filePath = NSBundle.mainBundle().pathForResource(plist, ofType: "plist"), let dict = NSDictionary(contentsOfFile: filePath) as? [NSString : NSObject]
		{
			plistCache[plist] = dict
			
			return dict
		}
		assertionFailure()
		return [NSString : NSObject]()
	}
	
	static func getEntry(plist:String, _ entry:String) -> [NSString : NSObject]
	{
		let plist = getPlist(plist)
		if let entry = plist[entry] as? [NSString : NSObject]
		{
			return entry
		}
		assertionFailure()
		return [NSString : NSObject]()
	}
	
	//MARK: external accessors
	static func getInt(plist:String, _ entry:String, _ value:String) -> Int?
	{
		let entry = getEntry(plist, entry)
		if let number = entry[value] as? NSNumber
		{
			return Int(number.intValue)
		}
		return nil
	}
	
	static func getFloat(plist:String, _ entry:String, _ value:String) -> Float?
	{
		let entry = getEntry(plist, entry)
		if let number = entry[value] as? NSNumber
		{
			return number.floatValue
		}
		return nil
	}
	
	static func getString(plist:String, _ entry:String, _ value:String) -> String?
	{
		let entry = getEntry(plist, entry)
		return entry[value] as? String
	}
	
	static func getArray(plist:String, _ entry:String, _ value:String) -> [NSObject]?
	{
		let entry = getEntry(plist, entry)
		return entry[value] as? [NSObject]
	}
	
	static func getDictionary(plist:String, _ entry:String, _ value:String) -> [String : NSObject]?
	{
		let entry = getEntry(plist, entry)
		return entry[value] as? [String : NSObject]
	}
	
	static func getBool(plist:String, _ entry:String, _ value:String) -> Bool
	{
		let entry = getEntry(plist, entry)
		return entry[value] != nil
	}
	
	static func getColor(plist:String, _ entry:String, _ value:String) -> UIColor?
	{
		if let colorName = getString(plist, entry, value)
		{
			return getColorByName(colorName)
		}
		return nil
	}
	
	static func getColorByName(colorName:String) -> UIColor?
	{
		let plist = getPlist("Colors")
		if let colorString = plist[colorName] as? String
		{
			let scanner = NSScanner(string: colorString)
			var hexInt:uint = 0
			if !scanner.scanHexInt(&hexInt)
			{
				return nil
			}
			let red = (hexInt & 0xFF0000) / 0xFF / 0xFF
			let green = (hexInt & 0xFF00) / 0xFF
			let blue = (hexInt & 0xFF)
			return UIColor(red: CGFloat(red) / 0xFF, green: CGFloat(green) / 0xFF, blue: CGFloat(blue) / 0xFF, alpha: 1)
		}
		
		return nil
	}
}