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
    
    func getOSCData() -> Data {
        var data:Data = Data()
        data = SimpleOSCMessage.paddingString(address).data(using: String.Encoding.utf8)! 
        data.append(SimpleOSCMessage.paddingString(args).data(using: String.Encoding.utf8)!)
        if dataArray.count != 0 {
            for i in 0...dataArray.count-1 {
                if dataArray[i] is Int32 {
                    data.append(SimpleOSCMessage.int2Data(dataArray[i] as! Int32) as Data)
                    
                }else if dataArray[i] is Float32 {
                    data.append(SimpleOSCMessage.float2Data(dataArray[i] as! Float32) as Data)
                    
                }else if dataArray[i] is String  {
                    data.append(SimpleOSCMessage.string2Data(dataArray[i] as! String) as Data)
                    
                }else{
                    return Data()
                }
            }
        }
        return data
    }
    
    mutating func setAddress(_ address:String) {
        self.address = address
    }
    
    mutating func addInt32Param(_ param:Int32) {
        args += "i"
        dataArray.append(param)
    }
    
    mutating func addFloat32Param(_ param:Float32) {
        args += "f"
        dataArray.append(param)
    }
    
    mutating func addStringParam(_ param:String) {
        args += "s"
        dataArray.append("\"\(param)\"")
    }
    
    static func int2Data(_ val:Int32) -> Data{
        //var returnVal = CFSwapInt32(UInt32(val))
        var returnVal = Int32.init(bigEndian: val)
        //var returnVal = val.bigEndian
        return (Data(bytes: &returnVal, count: MemoryLayout<Int32>.size))
    }
    
    static func uInt2Data(_ val:UInt32) -> Data{
//        var returnVal = CFSwapInt32(UInt32(val))
        var returnVal = Int32.init(bigEndian: Int32(val))
        return (Data(bytes: &returnVal, count: MemoryLayout<Int32>.size))
    }
    
    static func float2Data(_ val:Float32) -> Data{
        var returnVal = CFConvertFloatHostToSwapped(val)
        return (Data(bytes: &returnVal, count: MemoryLayout<Float32>.size))
    }
    
    static func string2Data(_ val:String) -> Data{
        let paddingVal = SimpleOSCMessage.paddingString(val)
        return (paddingVal.data(using: String.Encoding.utf8)! as NSData) as Data
    }
    
    static func paddingString(_ original:String) -> String {
        var result = original
        let size = 4 - result.characters.count % 4
        
        for _ in 1...size { // add 1〜4 padding
            result += "\0"
        }
        
        return result
    }
}
