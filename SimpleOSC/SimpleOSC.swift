//
//  SimpleOSC.swift
//  SimpleOSC
//
//  Created by MORIOKAToyoshi on 2016/04/30.
//  Copyright © 2016年 ___MORIOKAToyoshi___. All rights reserved.
//

import Foundation

public struct SimpleOSC {
    
    func ptr<T: Any>(_ p: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
        return p
    }
    
    var oscMessageArray:Array<SimpleOSCMessage>
    
    public init(){
        oscMessageArray = []
    }
    
    public mutating func removeAll() {
        oscMessageArray.removeAll()
    }
    
    public func getOSCData() -> Data {
        let result = NSMutableData()
        let header = SimpleOSCMessage.paddingString("#bundle")
        let timeTag = "\0\0\0\0\0\0\0\0" // this is timetag not support
        result.append(header.data(using: String.Encoding.utf8)!)
        result.append(timeTag.data(using: String.Encoding.utf8)!)
        
        if oscMessageArray.count != 0 {
            for i in 0...oscMessageArray.count-1 {
                let message = oscMessageArray[i].getOSCData()
                result.append(SimpleOSCMessage.uInt2Data(UInt32(message.count)) as Data)
                result.append(message as Data)
            }
        }

        return result as Data
    }
    
    public func parseOSCData(_ data:Data) -> Dictionary<String, AnyObject> {
        var result:Dictionary<String, AnyObject> = [:]
        
        if hasBundle(data) {
            print("data has bundle.")
            
            if data.count < 16 {
                print("error. too short data.")
            }
            
            // remove bundle text and time code
            result = parseOSCMessage(data.subdata(in: Range(16..<data.count)) as Data)
            
        }else{
            print("data does not has bundle.")
            // need support without bundle single osc message here.
        }
        
        return result
    }
    
    func hasBundle(_ data:Data) -> Bool {
        if data.count >= 8 {
            let headString = NSString(data: data.subdata(in: Range(0..<7)), encoding:String.Encoding.utf8.rawValue)
            if headString!.isEqual(to: "#bundle") {
                return true;
            }
        }
        return false
    }
    
    func parseOSCMessage(_ data:Data) -> Dictionary<String, AnyObject> {
        var resultArray:Dictionary<String, AnyObject> = [:]
        var head = 0
        
        print("message array size:\(data.count)")
        
        while head <= data.count {
            print("header:\(head).")
            // read message size
            let sizeData = data.subdata(in: Range(head..<head+4))
            print("sizedata:\(sizeData.count)")
            var size: Int32 = 0
            size = sizeData.withUnsafeBytes{ $0.pointee }
            print("osc message size is \(size.byteSwapped).")
            
            // get osc data
            let oscData = data.subdata(in: Range(head + 4..<head + 4 + Int(size.byteSwapped)))
            
            // get address
            let addressAndData = getAddress(oscData as Data)
            let newAddress = addressAndData.address
            let address = newAddress.components(separatedBy: "\0")
            // get data array
            let oscDataArray = oscData.subdata(in: Range(addressAndData.startArgs..<oscData.count))
            let resultDataArray = getDataArray(oscDataArray as Data)
            
            resultArray[address[0]] = resultDataArray.resultArray as AnyObject?
            
            head = head + Int(size.byteSwapped) + 4
            
            if head >= data.count {
                break
            }
        }
        return resultArray
    }
    
    func getDataArray(_ srcData:Data) -> (success:Bool, resultArray:Array<AnyObject>) {
        var resultArray:Array<AnyObject> = []
        var argsTypeArray:Array<String> = []
        
        var head = 0
        var argsCheckFinish = false
        
        // make argsTypeArray
        while argsCheckFinish != true {
            let firstArgsData = String(String(data: srcData.subdata(in: Range(head..<head+4)), encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue))!)
            head = head + 4
            
            print("character:\(firstArgsData)")
            
            for character in (firstArgsData?.characters)!{
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
                    // another args. sorry not support.
                }
            }
        }
        
        // headから実際のvalueがある
        for arg in argsTypeArray {
            if arg == "int" {
                let paramsData = srcData.subdata(in: Range(head..<head + 4))
                // 12/6
                var tempData: Int32 = 0
                tempData = paramsData.withUnsafeBytes{ $0.pointee }
                let data = tempData.byteSwapped
                head = head + 4
                resultArray.append(data as AnyObject)
                
            }else if arg == "float" {
                let paramsData = srcData.subdata(in: Range(head..<head + 4))

                var data: CFSwappedFloat32 = CFSwappedFloat32()
                let rawPtr = UnsafeMutableRawPointer(&data)
                let opaquePtr = OpaquePointer(rawPtr)
                let contextPtr = UnsafeMutablePointer<UInt8>(opaquePtr)
                paramsData.copyBytes(to: contextPtr, count: MemoryLayout<Float32>.size)
                head = head + 4
                resultArray.append(CFConvertFloatSwappedToHost(data) as AnyObject)
                
            }else if arg == "string" {
                var startDoubleQuat = false
                var endDoubleQuat = false
                var resultString = ""
                while !endDoubleQuat || head < srcData.count {
                    let stringData = String(NSString(data: srcData.subdata(in: Range(head..<head+4)), encoding:String.Encoding.utf8.rawValue)!)
                    head = head + 4
                    resultString += stringData
                    for character in stringData.characters{
                        if character == "\"" {
                            if !startDoubleQuat {
                                startDoubleQuat = true
                                
                            }else{
                                endDoubleQuat = true
                                var newResultStringArray = resultString.components(separatedBy:"\0")
                                resultArray.append(newResultStringArray[0] as AnyObject)
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
    
    func getAddress(_ srcData:Data) -> (success:Bool, address:String, startArgs:Int) {
        let parser = getFirstComma(srcData)
        return (parser.success, String(String(data: srcData.subdata(in: Range(0..<parser.point)), encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue))!), parser.point)
    }
    
    func getFirstComma(_ data:Data) -> (success:Bool, point:Int) {
        var success = false
        var result = 0
        var head = 0;
        
        while head + 2 < data.count || success != true {
            let comma = NSString(data: data.subdata(in: Range(head..<head+1)), encoding:String.Encoding.utf8.rawValue)
            
            if comma == "," {
                result = head
                success = true
                break
            }
            head  = head + 2
        }
        
        return (success, result)
    }
    
    public mutating func addMessage(_ address:String, dataArray:Array<Any>){
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
    
    public mutating func addMessage(_ address:String, data:Int32){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addInt32Param(data)
        oscMessageArray.append(newMessage)
    }
    
    public mutating func addMessage(_ address:String, data:Float32){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addFloat32Param(data)
        oscMessageArray.append(newMessage)
    }
    
    public mutating func addMessage(_ address:String, data:String){
        var newMessage = SimpleOSCMessage()
        newMessage.setAddress("/\(address)")
        newMessage.addStringParam(data)
        oscMessageArray.append(newMessage)
    }
    
    
}
