//
//  SimpleOSCMessage.swift
//  SimpleOSC
//
//  Created by MORIOKAToyoshi on 2016/04/05.
//  Copyright © 2016年 ___MORIOKAToyoshi___. All rights reserved.
//

import Foundation
struct SimpleOSCMessage {
    var address:String = ""
    var args:String = ","
    var dataArray:Array<Any> = []
    
    mutating func removeAll() {
        args = ","
        dataArray = []
    }
    
    func getOSCData() -> NSData {
        var data:NSMutableData = NSMutableData()
        data = SimpleOSCMessage.paddingString(address).dataUsingEncoding(NSUTF8StringEncoding)!.mutableCopy() as! NSMutableData
        data.appendData(SimpleOSCMessage.paddingString(args).dataUsingEncoding(NSUTF8StringEncoding)!)
        if dataArray.count != 0 {
            for i in 0...dataArray.count-1 {
                if dataArray[i] is Int32 {
                    data.appendData(SimpleOSCMessage.int2Data(dataArray[i] as! Int32))
                    
                }else if dataArray[i] is Float32 {
                    data.appendData(SimpleOSCMessage.float2Data(dataArray[i] as! Float32))
                    
                }else if dataArray[i] is String  {
                    data.appendData(SimpleOSCMessage.string2Data(dataArray[i] as! String))
                    
                }else{
                    return NSData()
                }
            }
        }
        return data
    }
    
    mutating func setAddress(address:String) {
        self.address = address
    }
    
    mutating func addInt32Param(param:Int32) {
        args += "i"
        dataArray.append(param)
    }
    
    mutating func addFloat32Param(param:Float32) {
        args += "f"
        dataArray.append(param)
    }
    
    mutating func addStringParam(param:String) {
        args += "s"
        dataArray.append("\"\(param)\"")
    }
    
    static func int2Data(val:Int32) -> NSData{
//        var returnVal = CFSwapInt32(UInt32(val))
        var returnVal = val.littleEndian
        return (NSData(bytes: &returnVal, length: sizeof(Int32)))
    }
    
    static func float2Data(val:Float32) -> NSData{
        var returnVal = CFConvertFloatHostToSwapped(val)
        return (NSData(bytes: &returnVal, length: sizeof(Float32)))
    }
    
    static func string2Data(val:String) -> NSData{
        let paddingVal = SimpleOSCMessage.paddingString(val)
        return paddingVal.dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    static func paddingString(original:String) -> String {
        var result = original
        let size = 4 - result.characters.count % 4
        
        for _ in 1...size { // add 1〜4 padding
            result += "\0"
        }
        
        return result
    }
}
