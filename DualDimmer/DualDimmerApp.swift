//
//  DualDimmerApp.swift
//  DualDimmer
//
//  Created by Francesco Fattori on 13/01/22.
//

import Foundation
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
    var worker = Worker()
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuView = ContentView()
            .environmentObject(GlobalVars.shared)
        
        popOver.behavior = .transient
        popOver.animates = false
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let MenuButton = statusItem?.button{
            MenuButton.image = NSImage(named: "menubar")
            MenuButton.action = #selector(MenuButtonToggle)
        }
        
        //Hide dock icon
        let newPolicy: NSApplication.ActivationPolicy = .accessory
        NSApplication.shared.setActivationPolicy(newPolicy)
        
        //loads preferences
        GlobalVars.shared.timeout = UserDefaults.standard.float(forKey: "timeout")
        GlobalVars.shared.enabled = UserDefaults.standard.bool(forKey: "enabled")
        GlobalVars.shared.screenID = UserDefaults.standard.object(forKey: "display") as? NSNumber
        
        worker.runFastTimer()
    }
    
    @objc func MenuButtonToggle(){
        if let menuButton = statusItem?.button{
            self.popOver.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc
    func runTimer(){
        self.worker.runFastTimer()
    }
    
    
    
    
    

}
