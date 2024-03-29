//
//  DocumentBrowserViewController.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    private var template: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        if UIDevice.current.userInterfaceIdiom == .pad {
            template = try? FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
                ).appendingPathComponent("Untitled.imagegallery")
            if template != nil {
                allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
            }
        }
    }
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    func presentDocument(at documentURL: URL) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyBoard.instantiateViewController(withIdentifier: "NavController")
        
        if let galleryViewController = navController.contents as? ImageGalleryCollectionViewController {
            galleryViewController.document = ImageGalleryDocument(fileURL: documentURL)
        }
        
        present(navController, animated: true)
    }
}

