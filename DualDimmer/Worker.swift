//
//  Worker.swift
//  DualDimmer
//
//  Created by Francesco Fattori on 18/01/22.
//


import Foundation
import SwiftUI
import IOKit.pwr_mgt
import Cocoa

class Worker {
    var currentTimer: Timer?
    var screen2dim: NSScreen?
    var lastDate = Date()
    var isDimmed = false
    var lastBrightness = 0.0 as Float
    
    
    func runTimer(fast: Bool){
        if (currentTimer != nil){
            self.currentTimer.unsafelyUnwrapped.invalidate()
        }
        if (fast){
            runFastTimer()
        } else {
            runSlowTimer()
        }
    }
    
    func runSlowTimer(){
        let timer = Timer(timeInterval: 5, repeats: true) { timer in
            self.currentTimer = timer
            self.compute();
        }
        
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
    
    func runFastTimer(){
        print("Fast timer initializer says hola")
        //Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
        let timer = Timer(timeInterval: 0.5, repeats: true) { timer in
            self.currentTimer = timer
            self.compute()
        }
        
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        
    }
    
    func compute(){
        print("hola computato")
        if (GlobalVars.shared.screenID == nil || !GlobalVars.shared.enabled){
            print("screenID is null or app is disabled")
            runSlowTimer()
            return;
        }
        self.screen2dim = findScreenByDeviceID(id: GlobalVars.shared.screenID.unsafelyUnwrapped)
        if (self.screen2dim == nil){
            print("screen obj is null")
            runSlowTimer()
            return;
        }
        
        
        let mouseInOther = getScreenWithMouse() != self.screen2dim
        if (!self.isDimmed && mouseInOther){
            if (Float(Date().timeIntervalSince(self.lastDate)) > GlobalVars.shared.timeout){
                if (self.checkIfAppPrevents()){
                    self.lastDate = Date()
                    runTimer(fast: false)
                } else {
                    self.lastDate = Date()
                    self.lastBrightness = getDisplayBrightness()
                    setBrightnessLevel(level: 0.1)
                    self.isDimmed = true
                    
                    runTimer(fast: true)
                }
            }
        } else {
            self.lastDate = Date()
            if (self.isDimmed && !mouseInOther){
                setBrightnessLevel(level: self.lastBrightness)
                self.isDimmed = false;
            }
        }
    }
    
    
    
    func checkIfAppPrevents() -> Bool{
        let windowList: CFArray? = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        var assertions: Unmanaged<CFDictionary>?
        if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
            fatalError("Error with assertions")
        }
        
        let assertions2 = assertions?.takeRetainedValue()
        for ass in assertions2.unsafelyUnwrapped as NSDictionary{
            let myval = (ass.value as? NSArray).unsafelyUnwrapped
            for single in myval as! [NSDictionary]{
                if (single["AssertionTrueType"] as! String == "PreventUserIdleDisplaySleep"){
                    let pid = single["AssertPID"] as! Int
                    for entry in windowList! as Array {
                        let bounds: NSDictionary = entry.object(forKey: kCGWindowBounds) as! NSDictionary

                        let name: String = entry.object(forKey: kCGWindowOwnerName) as? String ?? "N/A"
                        let ownerPID: Int = entry.object(forKey: kCGWindowOwnerPID) as? Int ?? 0
                        if (ownerPID == pid){
                            let parentScreen = getParentScreen(x: bounds["X"] as! Float, y: bounds["Y"] as! Float)
                            if (parentScreen == self.screen2dim){
                                print(name + " is avoiding, isInDimmableScreen: YES")
                                return true
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
}
