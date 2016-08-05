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
    
    func getPhotoURLsFromPin(pin: Pin, page: Int, completionHandlerForPinPhotos: (results: [NSURL]?, pages: Int?, errorString: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let bboxString = self.bboxString(pin)
        let extraParameters = [
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.BoundingBox: bboxString,
            Constants.FlickrParameterKeys.Page: String(page),
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPageLimit
        ]
        
        /* 2. Make the request */
        taskForGETMethod(Constants.FlickrParameterValues.SearchMethod, extraParameters: extraParameters) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                print("Error in taskForGETMethod: \(error)")
                completionHandlerForPinPhotos(results: nil, pages: nil, errorString: "taskForGETFailed")
            } else {
                if let results = results as? [String: AnyObject] {
                    guard let
                        photosDictionary = results[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],
                        photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]],
                        numPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                            completionHandlerForPinPhotos(results: nil, pages: nil, errorString: "Could not parse JSON. Maybe format has changed")
                            return
                    }
                    
                    var photoURLs = [NSURL]()
                    for photo in photosArray {
                        if let urlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String, let url = NSURL(string: urlString) {
                            photoURLs.append(url)
                        } else {
                            print("No URL for photo")
                        }
                    }
                    
                    completionHandlerForPinPhotos(results: photoURLs, pages: numPages, errorString: nil)
                }
            }
        }
    }
    
    // Download data for a given URL
    func downloadDataForURL(cellURL: NSURL, completionHandlerForDownload: (data: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let task = session.dataTaskWithURL(cellURL) { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForDownload(data: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForDownload(data: data, error: nil)
        }
        
        task.resume()
        return task
    }
    
}
