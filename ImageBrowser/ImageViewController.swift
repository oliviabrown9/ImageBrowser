//
//  ImageViewController.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    private var minZoomScale: CGFloat = 0.25
    private var maxZoomScale: CGFloat = 4
    
    var imageUrl: URL? {
        didSet {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: self.imageUrl!) {
                    DispatchQueue.main.async {
                        self.image = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private var imageView = UIImageView()
    
    private var image: UIImage? {
        didSet {
            DispatchQueue.main.async {
                self.imageView.image = self.image
                self.imageView.frame = CGRect(origin: CGPoint.zero, size: self.image!.size)
                self.scrollView.contentSize = self.image!.size
            }
        }
    }
    
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.addSubview(imageView)
            scrollView.minimumZoomScale = minZoomScale
            scrollView.maximumZoomScale = maxZoomScale
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

