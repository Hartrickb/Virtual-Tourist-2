//
//  FlickrConvenience.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/4/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient {
    
    // Downloads URLs for photos from a specific Pin Location
    func getPhotoURLsFromPin(_ pin: Pin, page: Int, completionHandlerForPinPhotos: @escaping (_ results: [URL]?, _ pages: Int?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let bboxString = self.bboxString(pin)
        let extraParameters = [
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.BoundingBox: bboxString,
            Constants.FlickrParameterKeys.Page: String(page),
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPageLimit
        ]
        
        /* 2. Make the request */
        let _ = taskForGETMethod(Constants.FlickrParameterValues.SearchMethod, extraParameters: extraParameters as [String : AnyObject]) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                print("Error in taskForGETMethod: \(error)")
                completionHandlerForPinPhotos(nil, nil, "taskForGETFailed")
            } else {
                if let results = results as? [String: AnyObject] {
                    guard let
                        photosDictionary = results[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],
                        let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]],
                        let numPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                            completionHandlerForPinPhotos(nil, nil, "Could not parse JSON. Maybe format has changed")
                            return
                    }
                    
                    var photoURLs = [URL]()
                    for photo in photosArray {
                        if let urlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String, let url = URL(string: urlString) {
                            photoURLs.append(url)
                        } else {
                            print("No URL for photo")
                        }
                    }
                    
                    completionHandlerForPinPhotos(photoURLs, numPages, nil)
                }
            }
        }
    }
    
    // Download data for a given URL
    func downloadDataForURL(_ cellURL: URL, completionHandlerForDownload: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let task = session.dataTask(with: cellURL, completionHandler: { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForDownload(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForDownload(data, nil)
        }) 
        
        task.resume()
        return task
    }
    
}
