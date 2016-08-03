//
//  MapViewController.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/3/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    let coreDataStack = CoreDataStack(modelName: "Model")!
    var editMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPinsFromMainQueue()
    }
    
    @IBAction func addPinToMap(sender: UILongPressGestureRecognizer) {
        addPin(sender)
    }
    @IBAction func editButton(sender: UIBarButtonItem) {
        
        editMode = !editMode
        if editMode {
            UIView.animateWithDuration(0.3, animations: {
                self.editView.hidden = false
            })
            editButton.title = "Done"
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.editView.hidden = true
            })
            editButton.title = "Edit"
        }
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
    
    func fetchPinsFromMainQueue() {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        var pins: [Pin]
        do {
            let result = try coreDataStack.context.executeFetchRequest(fetchRequest) as? [Pin]
            if let result = result {
                pins = result
                performUIUpdatesOnMain({ 
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.mapView.addAnnotations(pins)
                })
            }
        } catch {
            print("Failed to fetch Pins from Main Queue")
        }
        
    }
    
}

// MARK: Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let annotation = view.annotation as! Pin
        
        if editMode {
            mapView.removeAnnotation(annotation)
            coreDataStack.context.deleteObject(annotation)
            coreDataStack.save()
        }
        
    }
    
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