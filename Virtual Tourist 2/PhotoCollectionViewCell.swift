//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist 2
//
//  Created by Bennett Hartrick on 8/4/16.
//  Copyright © 2016 Bennett. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    
    var task: URLSessionTask? {
        didSet {
            if let previousTask = oldValue {
                previousTask.cancel()
            }
        }
    }
    
    // Clears the cell for reusing
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}
