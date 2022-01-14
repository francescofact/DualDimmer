//
//  DualDimmerApp.swift
//  DualDimmer
//
//  Created by Francesco Fattori on 13/01/22.
//

import SwiftUI
import IOKit.pwr_mgt
import Cocoa

@main
struct DualDimmerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject,NSApplicationDelegate{
    var statusItem: NSStatusItem?
    var popOver = NSPopover()
    var currentTimer: Timer?
    
    var screen2dim = NSScreen.screens[1]
    var lastDate = Date()
    var dimAfter = 3
    var isDimmed = false
    var lastBrightness = 0.0 as Float
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuView = ContentView()
        popOver.behavior = .transient
        popOver.animates = false
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let MenuButton = statusItem?.button{
            MenuButton.image = NSImage(systemSymbolName: "icloud.and.arrow.up.fill", accessibilityDescription: nil)
            MenuButton.action = #selector(MenuButtonToggle)
        }
        
        runFastTimer();
        
        
    }
    
    @objc func MenuButtonToggle(){
        if let menuButton = statusItem?.button{
            self.popOver.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func getScreenWithMouse() -> NSScreen?{
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
        
        return screenWithMouse
    }
    
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
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            self.currentTimer = timer
            self.compute();
        }
    }
    
    func runFastTimer(){
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.currentTimer = timer
            self.compute()
        }
    }
    
    func compute(){
        print(Date().ISO8601Format())
        let mouseInOther = self.getScreenWithMouse() != self.screen2dim
        if (!self.isDimmed && mouseInOther){
            if (Int(Date().timeIntervalSince(self.lastDate)) > self.dimAfter){
                if (self.checkIfAppPrevents()){
                    runTimer(fast: false)
                } else {
                    self.lastBrightness = self.getDisplayBrightness()
                    self.setBrightnessLevel(level: 0.1)
                    self.isDimmed = true
                    
                    runTimer(fast: true)
                }
            }
        } else {
            self.lastDate = Date()
            if (self.isDimmed && !mouseInOther){
                self.setBrightnessLevel(level: self.lastBrightness)
                self.isDimmed = false;
            }
        }
    }
    
    func setBrightnessLevel(level: Float) {

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
        IOObjectRelease(service)
    }
    
    func getDisplayBrightness() -> Float {

        var brightness: Float = 1.0
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        let result: kern_return_t = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)

        if result == kIOReturnSuccess {

            while service != 0 {
                service = IOIteratorNext(iterator)
                IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
                IOObjectRelease(service)
            }
        }
        return brightness
    }
    
    func getParentScreen(x: Float,y: Float) -> NSScreen{
        let screens = NSScreen.screens
        for screen in screens{
            let frame = screen.frame
            if (Float(frame.minX) <= x && Float(frame.maxX) >= x){
                return screen;
            }
        }
        fatalError("App is in misterious screen")
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
                            let parentScreen = self.getParentScreen(x: bounds["X"] as! Float, y: bounds["Y"] as! Float)
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
