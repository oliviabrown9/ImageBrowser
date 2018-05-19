//
//  ImageCollectionViewCell.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var imageUrl: URL? {
        didSet {
            downloadImage()
        }
    }
    
    private var image: UIImage? {
        didSet {
            imageView.image = image
            activityIndicator.stopAnimating()
        }
    }
    
    private func downloadImage() {
        if let url = imageUrl {
            activityIndicator.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self?.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}
