//
//  Document.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    let templateFileName = "Untitled"
    let fileExtension = ".gallery"
    
    var gallery: ImageGallery?
    
    override func contents(forType typeName: String) throws -> Any {
        return gallery?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let json = contents as? Data {
            gallery = ImageGallery(json: json)
        }
    }
}



