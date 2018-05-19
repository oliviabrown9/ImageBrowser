//
//  ImageGalleryCollectionViewController.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    private let reuseIdentifier = "ImageCell"
    private var cellWidth: CGFloat = 130
    
    var currentGallery = ImageGallery() {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(scaleCellWidth))
        collectionView?.addGestureRecognizer(pinch)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageVC = segue.destination as? ImageViewController, let indexPath = sender as? IndexPath {
            imageVC.imageUrl = currentGallery.images[indexPath.item].url
        }
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentGallery.images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.imageUrl = currentGallery.images[indexPath.item].url
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toImage", sender: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let imageAspectRatio = currentGallery.images[indexPath.item].aspectRatio
        return CGSize(width: cellWidth, height: cellWidth * CGFloat(imageAspectRatio))
    }
    
    // MARK: - UICollectionViewDragDelegate
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(for: indexPath)
    }
    
    private func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        if let cell = collectionView?.cellForItem(at: indexPath) as? ImageCollectionViewCell {
            if let image = cell.imageView.image {
                let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
                dragItem.localObject = image
                return [dragItem]
            }
        }
        return []
    }
    
    // MARK: - UICollectionViewDropDelegate
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let withinCollectionView = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        if withinCollectionView {
            return session.canLoadObjects(ofClass: UIImage.self)
        }
        else {
            return session.canLoadObjects(ofClass: URL.self) && session.canLoadObjects(ofClass: UIImage.self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let withinCollectionView = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: withinCollectionView ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        for (index, item) in coordinator.items.enumerated() {
            let destination = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
            let indexPath = IndexPath(item: destination.item + index, section: destination.section)
            if let source = item.sourceIndexPath {
                moveItem(at: indexPath, from: source, to: destination)
                coordinator.drop(item.dragItem, toItemAt: destination)
            }
            else {
                let placeHolderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: indexPath, reuseIdentifier: "PlaceholderCell"))
                replaceHolder(for: item, with: placeHolderContext)
            }
        }
    }
    
    private func replaceHolder(for item: UICollectionViewDropItem, with context: UICollectionViewDropPlaceholderContext ) {
        var aspectRatio: CGFloat?
        item.dragItem.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (provider, error) in
            if let image = provider as? UIImage {
                aspectRatio = image.size.height / image.size.width
            }
        })
        let _ = item.dragItem.itemProvider.loadObject(ofClass: URL.self, completionHandler: { (provider, error) in
            DispatchQueue.main.async {
                if let url = provider, let localAspectRatio = aspectRatio {
                    context.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
                        let image = ImageGallery.Image(url: url.imageURL, aspectRatio: Double(localAspectRatio))
                        self.currentGallery.images.insert(image, at: insertionIndexPath.item)
                    })
                }
                else {
                    context.deletePlaceholder()
                }
            }
        })
    }
    
    private func moveItem(at indexPath: IndexPath, from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        collectionView?.performBatchUpdates({
            let selectedImage = currentGallery.images.remove(at: sourceIndexPath.item)
            currentGallery.images.insert(selectedImage, at: indexPath.item)
            collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        })
    }
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    @objc private func scaleCellWidth(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            flowLayout?.invalidateLayout()
            cellWidth *= recognizer.scale
            recognizer.scale = 1.0
        default:
            break
        }
    }
}
