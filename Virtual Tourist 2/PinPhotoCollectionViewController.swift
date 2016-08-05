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
    var currentPage = 1
    var selectedPhotos: [NSIndexPath] = [] {
        didSet {
            if selectedPhotos.isEmpty {
                bottomButton.title = "New Collection"
            } else {
                bottomButton.title = "Delete Images"
            }
        }
    }
    var blockOperations: [NSBlockOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.camera.altitude *= 25
        
        if fetchPhotosFromMain().isEmpty {
            getPhotoURLs()
        }
    }
    
    @IBAction func bottomButtonPressed(sender: AnyObject) {
        if selectedPhotos.isEmpty {
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                fetchedResultsController.managedObjectContext.deleteObject(photo)
            }
            getPhotoURLs()
        } else {
            for index in selectedPhotos {
                let photo = fetchedResultsController.objectAtIndexPath(index) as? Photo
                fetchedResultsController.managedObjectContext.deleteObject(photo!)
            }
            selectedPhotos.removeAll()
            coreDataStack.save()
        }
        
    }
    
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
                if self.currentPage < pages! {
                    self.currentPage += 1
                } else {
                    self.currentPage = 1
                }
                print("currentPage: \(self.currentPage)")
                self.coreDataStack.save()
                
            }
        }
    }
    
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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedItems = fetchedResultsController.fetchedObjects?.count else {
            return 0
        }
        return fetchedItems
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let imageData = photo.imageData {
            cell.imageView.image = UIImage(data: imageData)
        } else {
            assignCellNewPhoto(cell, photo: photo)
            coreDataStack.save()
        }
        
        return cell
    }
}

// MARK: Delegate

extension PinPhotoCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedPhotos.indexOf(indexPath) {
            selectedPhotos.removeAtIndex(index)
            cell.imageView.alpha = 1.0
        } else {
            selectedPhotos.append(indexPath)
            cell.imageView.alpha = 0.5
        }
    }
    
}

extension PinPhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
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
        } else if type == NSFetchedResultsChangeType.Move {
            
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
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















