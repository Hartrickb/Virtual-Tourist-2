//
//  Photo.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {
    
    convenience init(pin: Pin, url: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.pin = pin
            self.url = url
        } else {
            fatalError("Failed to initialize Photo")
        }
    }
    
}
