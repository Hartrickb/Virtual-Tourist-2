//
//  PinPhotoCollectionViewController.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PinPhotoCollectionViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pin: Pin!
    let coreDataStack = CoreDataStack(modelName: "Model")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.camera.altitude *= 25
    }
    
}

