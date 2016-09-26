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
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var blockOperations: [BlockOperation] = []
    
    var totalPages: Int {
        return Int(pin.totalPages!)
    }
    
    // Sets current page based on the currentPage vs totalPages
    var currentPage: Int {
        get {
            if Int(pin.currentPage!) == totalPages || totalPages == 0 {
                return 1
            } else if Int(pin.currentPage!) < totalPages {
                return Int(pin.currentPage!) + 1
            } else {
                return Int(pin.currentPage!)
            }
        } set(page) {
            pin.currentPage = page as NSNumber?
        }
    }
    
    // Changes bottom button based on if any photos are selected
    // Used to set alpha of cells and delete selected cells
    var selectedPhotos: [IndexPath] = [] {
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
            let alert = UIAlertController(title: "No Photos Returned", message: "No photos were returned for this location. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
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
    
    @IBAction func bottomButtonPressed(_ sender: AnyObject) {
        // Deletes photos currently displayed and gets new photos
        if selectedPhotos.isEmpty {
            for photo in fetchedResultsController.fetchedObjects! as [Photo] {
                fetchedResultsController.managedObjectContext.delete(photo)
            }
            getPhotoURLs()
            
        // Deletes selected photos and saves Core Data
        } else {
            for index in selectedPhotos {
                let photo = fetchedResultsController.object(at: index) as Photo
                fetchedResultsController.managedObjectContext.delete(photo)
            }
            selectedPhotos.removeAll()
            coreDataStack.save()
        }
        
    }
    
    // Gets photos from Core Data
    func fetchPhotosFromMain() -> [Photo] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        // Make sure photos appear in the same order each time
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Only get photos for selected pin
        let predicate = NSPredicate(format: "pin = %@", pin)
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest as! NSFetchRequest<Photo>, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        var photos = [Photo]()
        do {
            try fetchedResultsController.performFetch()
            photos = fetchedResultsController.fetchedObjects! as [Photo]
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
                    let urlString = String(describing: photoURL)
                    _ = Photo(pin: self.pin, url: urlString, context: self.coreDataStack.context)
                }
                
                // Updates current page for pin in Core Data
                self.pin.currentPage = self.currentPage as NSNumber?
                print("currentPage: \(self.currentPage)")
                self.coreDataStack.save()
                
            }
        }
    }
    
    // Downloads images for cell
    func assignCellNewPhoto(_ cell: PhotoCollectionViewCell, photo: Photo) {
        cell.activityIndicator.startAnimating()
        let url = URL(string: photo.url)!
        
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedItems = fetchedResultsController.fetchedObjects?.count else {
            return 0
        }
        return fetchedItems
    }
    
    // Creates the cells and formats them with either a fetched image from Core
    // Data or downloads a new image
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath) 
        
        // If there is data from Core Data fetchedResults, display the image
        if let imageData = photo.imageData {
            cell.imageView.image = UIImage(data: imageData)
        // Get a new photo from Flickr to display and save it to Core Data
        } else {
            assignCellNewPhoto(cell, photo: photo)
            coreDataStack.save()
        }
        
        // Controls the alpha of selected Cells
        if selectedPhotos.index(of: indexPath) == nil {
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
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedPhotos.index(of: indexPath) {
            selectedPhotos.remove(at: index)
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
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.insertItems(at: [newIndexPath!])
                }
            }))
        } else if type == NSFetchedResultsChangeType.update {

            blockOperations.append(BlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.reloadItems(at: [indexPath!])
                }
            }))
        } else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let the = self {
                    the.collectionView.deleteItems(at: [indexPath!])
                }
            }))
        }
    }
    
    // Perform the blockOperations and clear them
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let batchUpdatesToPerform = {() -> Void in
            for operation in self.blockOperations {
                operation.start()
            }
        }
        collectionView.performBatchUpdates(batchUpdatesToPerform) { (finished) in
            self.blockOperations.removeAll(keepingCapacity: false)
        }
    }
    
}















