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
    
    var pin: Pin!
    let coreDataStack = CoreDataStack.sharedInstance()
    var fetchedResultsController: NSFetchedResultsController!
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.camera.altitude *= 25
        
        if fetchPhotosFromMain().isEmpty {
            getPhotoURLs()
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

















