//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/5/16.
//  Copyright © 2016 Bennett. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var currentPage: NSNumber?
    @NSManaged var totalPages: NSNumber?
    @NSManaged var photos: NSSet?

}
