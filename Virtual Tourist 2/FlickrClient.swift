//
//  FlickrClient.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/4/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import Foundation
import MapKit

class FlickrClient {
    
    var session = NSURLSession.sharedSession()
    
    // MARK: GET
    
    func taskForGETMethod(method: String, extraParameters: [String: AnyObject], completionHandlerForGET: (results: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        var parametersWithBasicParameters = extraParameters
        parametersWithBasicParameters[Constants.FlickrParameterKeys.Method] = method
        parametersWithBasicParameters[Constants.FlickrParameterKeys.APIKey] = Constants.FlickrParameterValues.APIKey
        parametersWithBasicParameters[Constants.FlickrParameterKeys.Format] = Constants.FlickrParameterValues.ResponseFormat
        parametersWithBasicParameters[Constants.FlickrParameterKeys.NoJSONCallback] = Constants.FlickrParameterValues.DisableJSONCallback
        parametersWithBasicParameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterValues.UseSafeSearch
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(URL: flickrURLFromParameters(parametersWithBasicParameters))
        print("URL: \(flickrURLFromParameters(parametersWithBasicParameters))")
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                print("Error: \(error)")
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGET(results: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
//            /* GUARD: Did we get a successful 2XX response? */
//            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
//                sendError("Your request returned a status code other than 2xx!")
//                return
//            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: Helpers
    
    // Given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    // Create a Flickr URL from parameters
    private func flickrURLFromParameters(parameters: [String: AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        return components.URL!
    }
    
    // Create a bbox String
    func bboxString(pin: MKAnnotation) -> String {
        let latitude = Double(pin.coordinate.latitude)
        let longitude = Double(pin.coordinate.longitude)
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}

