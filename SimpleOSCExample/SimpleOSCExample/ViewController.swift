//
//  ViewController.swift
//  SimpleOSCExample
//
//  Created by MORIOKAToyoshi on 2016/08/13.
//  Copyright © 2016年 ___MORIOKAToyoshi___. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make osc data
        var out:SimpleOSC = SimpleOSC()
        
        // make int value
        let testInt:Int32 = 500
        out.addMessage("int", data: testInt)
        
        // make float value
        let testFloat:Float32 = 55.5
        out.addMessage("float", data: testFloat)
        
        // make string
        let testString:String = "hogehoge"
        out.addMessage("string", data: testString)
        
        // make array
        let testValArray:Array<Any> = [1, 2, 3]
        out.addMessage("triple", dataArray: testValArray)
        
        // make multi type array
        let testTypeVal:Array<Any> = [1, 1.0, "mogamoga"]
        out.addMessage("multi", dataArray: testTypeVal)
        
        // check result
        let oscData = out.getOSCData()
        print("osc data:\(oscData)")
        
        // convert data to osc dictionary
        let input:SimpleOSC = SimpleOSC()
        let result = input.parseOSCData(oscData)
        print("input:\(result)")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
