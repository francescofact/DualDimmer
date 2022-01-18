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
