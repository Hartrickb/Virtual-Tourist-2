//
//  Pin.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(latitude), Double(longitude))
    }
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Could not initialize Pin")
        }
    }
    
}
