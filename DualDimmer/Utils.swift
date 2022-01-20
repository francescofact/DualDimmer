//
//  Utils.swift
//  DualDimmer
//
//  Created by Francesco Fattori on 18/01/22.
//

import SwiftUI
import Cocoa

func findScreenByDeviceID(id: NSNumber) -> NSScreen? {
    for screen in NSScreen.screens{
        if screen.getScreenNumber() == id{
            return screen
        }
    }
    return nil
}

func getScreenWithMouse() -> NSScreen?{
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
    
    return screenWithMouse
}

func setBrightnessLevel(level: Float) {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
    print(service)
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
            print(service)
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
