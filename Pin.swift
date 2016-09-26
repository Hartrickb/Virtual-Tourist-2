//
//  Pin.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/5/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
    // Makes Pin MKAnnotation compatible
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(latitude), Double(longitude))
    }
    
    // Initialized a new Pin
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude as NSNumber
            self.longitude = longitude as NSNumber
        } else {
            fatalError("Could not initialize Pin")
        }
    }
}
