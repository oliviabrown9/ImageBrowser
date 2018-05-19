//
//  ImageGallery.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import Foundation

class ImageGallery {
    var name: String
    var images = [Image]()
    
    init(name: String = "New Gallery") {
        self.name = name
    }
    
    struct Image {
        let url: URL
        let aspectRatio: Double
    }
}
