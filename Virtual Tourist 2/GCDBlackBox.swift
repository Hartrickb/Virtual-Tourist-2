//
//  GCDBlackBox.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation

// Performs updates on the main thread
func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}

