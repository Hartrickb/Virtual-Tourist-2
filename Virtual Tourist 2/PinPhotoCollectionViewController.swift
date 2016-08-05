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
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    var pin: Pin!
    let coreDataStack = CoreDataStack.sharedInstance()
    var fetchedResultsController: NSFetchedResultsController!
    var blockOperations: [NSBlockOperation] = []
    
    var totalPages: Int {
        return Int(pin.totalPages!)
    }
    
    // Sets current page based on the currentPage vs totalPages
    var currentPage: Int {
        get {
            if pin.currentPage! == totalPages || totalPages == 0 {
                return 1
            } else if Int(pin.currentPage!) < totalPages {
                return Int(pin.currentPage!) + 1
            } else {
                return Int(pin.currentPage!)
            }
        } set(page) {
            pin.currentPage = page
        }
    }
    
    // Changes bottom button based on if any photos are selected
    // Used to set alpha of cells and delete selected cells
    var selectedPhotos: [NSIndexPath] = [] {
        didSet {
            if selectedPhotos.isEmpty {
                bottomButton.title = "New Collection"
            } else {
                bottomButton.title = "Delete Images"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegates and dataSource
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Display alert if no photos were returned
        if totalPages == 0 {
            let alert = UIAlertController(title: "No Photos Returned", message: "No photos were returned for this location. Please try again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        
        // Configures map view for PinPhotoCollectionViewController
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.camera.altitude *= 25
        
        // If photos are stored in Core Data, do not get new photos
        if fetchPhotosFromMain().isEmpty {
            getPhotoURLs()
        }
    }
    
    @IBAction func bottomButtonPressed(sender: AnyObject) {
        // Deletes photos currently displayed and gets new photos
        if selectedPhotos.isEmpty {
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                fetchedResultsController.managedObjectContext.deleteObject(photo)
            }
            getPhotoURLs()
            
        // Deletes selected photos and saves Core Data
        } else {
            for index in selectedPhotos {
                let photo = fetchedResultsController.objectAtIndexPath(index) as? Photo
                fetchedResultsController.managedObjectContext.deleteObject(photo!)
            }
            selectedPhotos.removeAll()
            coreDataStack.save()
        }
        
    }
    
    // Gets photos from Core Data
    func fetchPhotosFromMain() -> [Photo] {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Make sure photos appear in the same order each time
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Only get photos for selected pin
        let predicate = NSPredicate(format: "pin = %@", pin)
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        var photos = [Photo]()
        do {
            try fetchedResultsController.performFetch()
            photos = fetchedResultsController.fetchedObjects as! [Photo]
        } catch let error {
            print("Error Fetching: \(error)")
        }
        
        return photos
    }
    
    // Get photos from Flickr based on pin
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
                    // Creates a new photo for associated pin with URL
                    let urlString = String(photoURL)
                    _ = Photo(pin: self.pin, url: urlString, context: self.coreDataStack.context)
                }
                
                // Updates current page for pin in Core Data
                self.pin.currentPage = self.currentPage
                print("currentPage: \(self.currentPage)")
                self.coreDataStack.save()
                
            }
        }
    }
    
    // Downloads images for cell
    func assignCellNewPhoto(cell: PhotoCollectionViewCell, photo: Photo) {
        cell.activityIndicator.startAnimating()
        let url = NSURL(string: photo.url)!
        
        let task = FlickrClient.sharedInstance().downloadDataForURL(url) { (data, error) in
            
            guard error == nil else {
                print("Error: \(error)")
                return
            }
                
            guard let data = data else {
                print("No data returned with this request")
                return
            }
            
            performUIUpdatesOnMain({ 
                photo.imageData = data
                let image = UIImage(data: data)
                cell.activityIndicator.stopAnimating()
                cell.imageView.image = image
            })
        }
        task.resume()
    }
    
}


// MARK: DataSource

extension PinPhotoCollectionViewController: UICollectionViewDataSource {
    
    // Calculates how many cells to display
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedItems = fetchedResultsController.fetchedObjects?.count else {
            return 0
        }
        return fetchedItems
    }
    
    // Creates the cells and formats them with either a fetched image from Core
    // Data or downloads a new image
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // If there is data from Core Data fetchedResults, display the image
        if let imageData = photo.imageData {
            cell.imageView.image = UIImage(data: imageData)
        // Get a new photo from Flickr to display and save it to Core Data
        } else {
            assignCellNewPhoto(cell, photo: photo)
            coreDataStack.save()
        }
        
        // Controls the alpha of selected Cells
        if selectedPhotos.indexOf(indexPath) == nil {
            cell.alpha = 1.0
        } else {
            cell.alpha = 0.5
        }
        
        return cell
    }
}

// MARK: Delegate

extension PinPhotoCollectionViewController: UICollectionViewDelegate {
    
    // Controls the selected cells and the selectedPhotos variable
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedPhotos.indexOf(indexPath) {
            selectedPhotos.removeAtIndex(index)
            cell.alpha = 1.0
        } else {
            selectedPhotos.append(indexPath)
            cell.alpha = 0.5
        }
    }
    
}

extension PinPhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
    // Based on the user action of either deleting or getting new cells, add an
    // operation to preform to the blockOperations array
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if type == NSFetchedResultsChangeType.Insert {
            
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.insertItemsAtIndexPaths([newIndexPath!])
                }
            }))
        } else if type == NSFetchedResultsChangeType.Update {

            blockOperations.append(NSBlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.reloadItemsAtIndexPaths([indexPath!])
                }
            }))
        } else if type == NSFetchedResultsChangeType.Delete {
            
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.deleteItemsAtIndexPaths([indexPath!])
                }
            }))
        }
    }
    
    // Perform the blockOperations and clear them
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let batchUpdatesToPerform = {() -> Void in
            for operation in self.blockOperations {
                operation.start()
            }
        }
        collectionView.performBatchUpdates(batchUpdatesToPerform) { (finished) in
            self.blockOperations.removeAll(keepCapacity: false)
        }
    }
    
}















