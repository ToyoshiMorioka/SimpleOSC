//
//  SimpleOSC.swift
//  SimpleOSC
//
//  Created by MORIOKAToyoshi on 2016/04/30.
//  Copyright © 2016年 ___MORIOKAToyoshi___. All rights reserved.
//

import Foundation

public struct SimpleOSC {
    
    var oscMessageArray:Array<SimpleOSCMessage>
    
    public init(){
        oscMessageArray = []
    }
    
    public mutating func removeAll() {
        oscMessageArray.removeAll()
    }
    
    public func getOSCData() -> NSData {
        let result = NSMutableData()
        let header = SimpleOSCMessage.paddingString("#bundle")
        let timeTag = "\0\0\0\0\0\0\0\0" // this is timetag
        result.appendData(header.dataUsingEncoding(NSUTF8StringEncoding)!)
        result.appendData(timeTag.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        if oscMessageArray.count != 0 {
            for i in 0...oscMessageArray.count-1 {
                let message = oscMessageArray[i].getOSCData()
                result.appendData(SimpleOSCMessage.int2Data(Int32(message.length)))
                result.appendData(message)
            }
        }

        return result
    }
    
    public func parseOSCData(data:NSData) -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = [:]
        
        if hasBundle(data) {
            print("data has bundle.")
            
            if data.length < 16 {
                print("error. too short data.")
            }
            
            // remove bundle text and time code
            result = parseOSCMessage(data.subdataWithRange(NSRange(16..<data.length)))
            
        }else{
            print("data does not has bundle.")
            // need support without bundle single osc message here.
        }
        
        return result
    }
    
    func hasBundle(data:NSData) -> Bool {
        if data.length >= 8 {
            let headString = NSString(data: data.subdataWithRange(NSRange(0..<7)), encoding:NSUTF8StringEncoding)
            if headString!.isEqualToString("#bundle") {
                return true;
            }
        }
        return false
    }
    
    func parseOSCMessage(data:NSData) -> Dictionary<String, AnyObject> {
        var resultArray:Dictionary<String, AnyObject> = [:]
        var head = 0
        
        print("message array size:\(data.length)")
        
        while head <= data.length {
            print("header:\(head).")
            // read message size
            let sizeData = data.subdataWithRange(NSRange(head..<head+4))
            var size:Int = 0
            sizeData.getBytes(&size, length: sizeof(Int32))
            print("osc message size is \(size).")
            
            // get osc data
            let oscData = data.subdataWithRange(NSRange(head+4..<head+4+size))
            
            // get address
            let addressAndData = getAddress(oscData)
            let newAddress = addressAndData.address
            //newAddress.stringByReplacingOccurrencesOfString("\"", withString: "")
            //newAddress.stringByReplacingOccurrencesOfString("\0", withString: " ")
            let address = newAddress.componentsSeparatedByString("\0")
            // get data array
            let oscDataArray = oscData.subdataWithRange(NSRange(addressAndData.startArgs..<oscData.length))
            let resultDataArray = getDataArray(oscDataArray)
            
            resultArray[address[0]] = resultDataArray.resultArray
            
            head = head + size + 4
            
            if head >= data.length {
                break
            }
        }
        return resultArray
    }
    
    func getDataArray(srcData:NSData) -> (success:Bool, resultArray:Array<AnyObject>) {
        var resultArray:Array<AnyObject> = []
        var argsTypeArray:Array<String> = []
        
        var head = 0
        var argsCheckFinish = false
        
        // make argsTypeArray
        while argsCheckFinish != true {
            let firstArgsData = String(NSString(data: srcData.subdataWithRange(NSRange(head..<head+4)), encoding:NSUTF8StringEncoding)!)
            head = head + 4
            
            print("character:\(firstArgsData)")
            
            for character in firstArgsData.characters{
                print("\(character)")
                if character == "i" {
                    argsTypeArray.append("int")
                }else if character == "f" {
                    argsTypeArray.append("float")
                }else if character == "s" {
                    argsTypeArray.append("string")
                }else if character == "\0"{
                    //print("args type get finish. args are \(argsTypeArray.count)")
                    argsCheckFinish = true
                    break
                }else{
                    // athor args. sorry not support.
                }
            }
        }
        
        // headから実際のvalueがある
        for arg in argsTypeArray {
            if arg == "int" {
                let paramsData = srcData.subdataWithRange(NSRange(head..<head + 4))
                var data:Int = 0
                paramsData.getBytes(&data, length: sizeof(Int32))
                //print("data:\(data)")
                head = head + 4
                resultArray.append(data)
                
            }else if arg == "float" {
                let paramsData = srcData.subdataWithRange(NSRange(head..<head + 4))
                var data:CFSwappedFloat32 = CFSwappedFloat32()
                paramsData.getBytes(&data, length: sizeof(Float32))
                //print("data:\(CFConvertFloatSwappedToHost(data))")
                head = head + 4
                resultArray.append(CFConvertFloatSwappedToHost(data))
                
            }else if arg == "string" {
                var startDoubleQuat = false
                var endDoubleQuat = false
                var resultString = ""
                while !endDoubleQuat || head < srcData.length {
                    let stringData = String(NSString(data: srcData.subdataWithRange(NSRange(head..<head+4)), encoding:NSUTF8StringEncoding)!)
                    head = head + 4
                    resultString += stringData
                    for character in stringData.characters{
                        if character == "\"" {
                            if !startDoubleQuat {
                                startDoubleQuat = true
                                
                            }else{
                                endDoubleQuat = true
                                var newResultStringArray = resultString.componentsSeparatedByString("\0")
                                resultArray.append(newResultStringArray[0])
                                //print("string read finish! string:\(resultString)")
                                //break
                            }
                        }
                    }
                }
                
                if !endDoubleQuat {
                    //print("error unssuported text data.")
                    break
                }
                
            }else{
                
            }
        }
        
        // get val from data
        
        return (true, resultArray)
    }
    
    func getAddress(srcData:NSData) -> (success:Bool, address:String, startArgs:Int) {
        let parser = getFirstComma(srcData)
        return (parser.success, String(NSString(data: srcData.subdataWithRange(NSRange(0..<parser.point)), encoding:NSUTF8StringEncoding)!), parser.point)
    }
    
    func getFirstComma(data:NSData) -> (success:Bool, point:Int) {
        var success = false
        var result = 0
        var head = 0;
        
        while head + 2 < data.length || success != true {
            let comma = NSString(data: data.subdataWithRange(NSRange(head..<head+1)), encoding:NSUTF8StringEncoding)
            
            if comma == "," {
                result = head
                success = true
                break
            }
            head  = head + 2
        }
        
        return (success, result)
    }
    
    public mutating func addMessage(address:String, dataArray:Array<Any>){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        
        for data in dataArray {
            switch data {
            case is Int:
                newMessage.addInt32Param(Int32(data as! Int))
            case is Int32:
                newMessage.addInt32Param(data as! Int32)
            case is Int64:
                newMessage.addInt32Param(Int32(data as! Int64))
            case is Float:
                newMessage.addFloat32Param(Float32(data as! Float))
            case is Double:
                newMessage.addFloat32Param(Float32(data as! Double))
            case is Float32:
                newMessage.addFloat32Param(data as! Float32)
            case is String:
                newMessage.addStringParam(data as! String)
            default:
                break
            }
        }
        
        oscMessageArray.append(newMessage)
    }
    
    public mutating func addMessage(address:String, data:Int32){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addInt32Param(data)
        oscMessageArray.append(newMessage)
    }
    
    public mutating func addMessage(address:String, data:Float32){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addFloat32Param(data)
        oscMessageArray.append(newMessage)
    }
    
    public mutating func addMessage(address:String, data:String){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addStringParam(data)
        oscMessageArray.append(newMessage)
    }
    
    
}
