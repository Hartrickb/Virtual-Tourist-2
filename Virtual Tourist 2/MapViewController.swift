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
    
    let coreDataStack = CoreDataStack.sharedInstance()
    var editMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPinsFromMainQueue()
    }
    
    @IBAction func addPinToMap(_ sender: UILongPressGestureRecognizer) {
        addPin(sender)
    }
    @IBAction func editButton(_ sender: UIBarButtonItem) {
        
        editMode = !editMode
        if editMode {
            UIView.animate(withDuration: 0.3, animations: {
                self.editView.isHidden = false
            })
            editButton.title = "Done"
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.editView.isHidden = true
            })
            editButton.title = "Edit"
        }
    }
}

// MARK: Helper Functions
extension MapViewController {
    
    func addPin(_ gesture: UILongPressGestureRecognizer) {
        
        // Drops a pin where the long tap ended
        if gesture.state == .ended && !editMode {
            let areaTapped = gesture.location(in: mapView)
            
            // Converts the tap to a coordinate
            let tapCoordinate = mapView.convert(areaTapped, toCoordinateFrom: mapView)
            
            // Creates a new Pin from coordinate and saves to Core Data
            let annotation = Pin(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude, context: coreDataStack.context)
            coreDataStack.save()
            
            // Adds the annotation to the map
            mapView.addAnnotation(annotation)
            
            // Gets first set of URLs for pin location
            getPhotoURLs(annotation)
        }
    }
    
    // Retrieves all pins that are stored in Core Data
    func fetchPinsFromMainQueue() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        var pins: [Pin]
        do {
            let result = try coreDataStack.context.fetch(fetchRequest) as? [Pin]
            if let result = result {
                pins = result
                
                // Adds fetched Pins to map
                performUIUpdatesOnMain({ 
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.mapView.addAnnotations(pins)
                })
            }
        } catch {
            print("Failed to fetch Pins from Main Queue")
        }
    }
    
    // Gets photoURLs for newly dropped pins in the background
    // to speed up process in
    func getPhotoURLs(_ pin: Pin) {
        FlickrClient.sharedInstance().getPhotoURLsFromPin(pin, page: 1) { (results, pages, errorString) in
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
                
                // Saves total pages and current page to Pin
                performUIUpdatesOnMain({ 
                    pin.totalPages = pages! as NSNumber?
                    pin.currentPage = 1
                    for photoURL in results! {
                        let urlString = String(describing: photoURL)
                        _ = Photo(pin: pin, url: urlString, context: self.coreDataStack.context)
                    }
                    self.coreDataStack.save()
                })
            }
        }
    }
    
    // Sends Pin tapped to the PinPhotoCollectionViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTappedSegue" {
            let pin = sender as! Pin
            let destinationViewController = segue.destination as! PinPhotoCollectionViewController
            destinationViewController.pin = pin
        }
    }
    
}

// MARK: Delegate
extension MapViewController: MKMapViewDelegate {
    
    // Either deletes pin if editing or goes to PinPhotoCollectionViewController
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation as! Pin
        
        if editMode {
            mapView.removeAnnotation(annotation)
            coreDataStack.context.delete(annotation)
            coreDataStack.save()
        } else {
            mapView.deselectAnnotation(annotation, animated: true)
            performSegue(withIdentifier: "pinTappedSegue", sender: annotation)
        }
        
    }
    
    // Animates Drop of the Pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pinView") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinView")
            annotationView?.animatesDrop = true
        }
        
        annotationView?.annotation = annotation
        annotationView?.animatesDrop = true
        return annotationView
    }
    
}
