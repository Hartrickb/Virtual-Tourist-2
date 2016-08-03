//
//  MapViewController.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editView: UIView!
    
    let coreDataStack = CoreDataStack(modelName: "Model")!
    var editMode = false
    
    @IBAction func addPinToMap(sender: UILongPressGestureRecognizer) {
        addPin(sender)
    }
}

// MARK: Helper Functions
extension MapViewController {
    
    func addPin(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Ended && !editMode {
            let areaTapped = gesture.locationInView(mapView)
            let tapCoordinate = mapView.convertPoint(areaTapped, toCoordinateFromView: mapView)
            let annotation = Pin(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude, context: coreDataStack.context)
            coreDataStack.save()
            mapView.addAnnotation(annotation)
        }
    }
}

// MARK: Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("pinView") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinView")
            annotationView?.animatesDrop = true
        }
        
        annotationView?.annotation = annotation
        annotationView?.animatesDrop = true
        return annotationView
    }
    
}