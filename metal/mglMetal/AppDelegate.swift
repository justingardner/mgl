//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  AppDelegate.swift
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
import Cocoa

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Main Application
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // We want mglMetal to stay responsive and not go on "app nap".
    // https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheAppLevel.html
    let preventAppNap = ProcessInfo.processInfo.beginActivity(
        options: .userInitiated,
        reason: "Responding to incoming commands")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
