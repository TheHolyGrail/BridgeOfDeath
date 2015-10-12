//
//  Global.swift
//  anival
//
//  Created by Sam Grover on 9/30/15.
//  Copyright © 2015 The Holy Grail. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc public protocol GlobalSupportable: JSExport {
    // setTimeout, clearTimeout
    func set(fn: JSValue, timeout: JSValue) -> UInt
    func clearTimeout(identifier: UInt)
   
    // setInterval, clearInterval
    func set(fn: JSValue, interval: JSValue) -> UInt
    func clearInterval(identifier: UInt)
    
    func logmsg(msg: AnyObject!)
}

@objc public class Global: NSObject, GlobalSupportable {
    
    // Stores all functions set up with setTimeout and setInterval along with their parameters. Removed after dispatch (in case of setTimeout) or when cleared.
    // Keeping all input values as JSValues so that they can be called on the JS function,  'fn',  in the dispatch and sent back as they came.
    var jsFunctions = [UInt: [JSValue]]()
    
    public func set(fn: JSValue, timeout: JSValue) -> UInt {
        let identifier = UInt(arc4random())
        jsFunctions[identifier] = [fn, timeout]
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeout.toInt32()) * Int64(NSEC_PER_MSEC)), dispatch_get_main_queue()) { () -> Void in
            if let _ = self.jsFunctions[identifier] {
                fn.callWithArguments([timeout])
                self.jsFunctions.removeValueForKey(identifier)
            }
        }
        
        return identifier
    }
    
    public func clearTimeout(identifier: UInt) {
        removeJSFunction(identifier)
    }
    
    public func set(fn: JSValue, interval: JSValue) -> UInt {
        let identifier = UInt(arc4random())
        let values = [fn, interval]
        jsFunctions[identifier] = values
        setupIntervalDispatch(identifier, interval: interval)
        return identifier
    }
    
    public func clearInterval(identifier: UInt) {
        removeJSFunction(identifier)
    }
    
    public func logmsg(msg: AnyObject!) {
        if let msg = msg {
            print(msg)
        }
    }
    
    internal func setupIntervalDispatch(identifier: UInt, interval: JSValue) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(interval.toInt32()) * Int64(NSEC_PER_MSEC)), dispatch_get_main_queue()) { () -> Void in
            // If there are no values associated any longer (due to a clearInterval call), then it will not set up another dispatch and the recursion will end.
            if let values = self.jsFunctions[identifier] {
                let fn = values[0]
                fn.callWithArguments([interval])
                // Call this function recursively to set up the next dispatch
                self.setupIntervalDispatch(identifier, interval: interval)
            }
        }
    }
    
    internal func removeJSFunction(identifier: UInt) {
        self.jsFunctions.removeValueForKey(identifier)
    }
    
}
