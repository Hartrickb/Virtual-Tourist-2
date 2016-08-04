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
    let coreDataStack = CoreDataStack.sharedInstance()
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.camera.altitude *= 25
        
        getPhotoURLs()
    }
    
    func getPhotoURLs() {
        FlickrClient.sharedInstance().getPhotoURLsFromPin(pin, page: currentPage) { (results, pages, errorString) in
            if let error = errorString {
                print("Error: \(error)")
            } else {
                
                guard results != nil else {
                    print("No results")
                    return
                }
                
                guard pages != nil else {
                    print("No total number of pages")
                    return
                }
                
                for photoURL in results! {
                    let urlString = String(photoURL)
                    _ = Photo(pin: self.pin, url: urlString, context: self.coreDataStack.context)
                }
                self.coreDataStack.save()
                
            }
        }
    }
    
}

