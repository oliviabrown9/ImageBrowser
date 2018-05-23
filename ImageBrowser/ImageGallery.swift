//
//  ImageGallery.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import Foundation

class ImageGallery: Codable {
    var name: String
    var images = [Image]()
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    struct Image: Codable {
        let url: URL
        let aspectRatio: Double
    }
    
    init(images: [Image] = [Image]()) {
        self.name = "Untitled"
        self.images = images
    }
    
    init?(json: Data) {
        if let updatedValue = try? JSONDecoder().decode(ImageGallery.self, from: json) {
            name = updatedValue.name
            images = updatedValue.images
        }
        else {
            return nil
        }
    }
}
