//
//  ImageGalleryCollectionViewController.swift
//  ImageBrowser
//
//  Created by Olivia Brown on 5/19/18.
//  Copyright © 2018 Olivia Brown. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    @IBAction func closeGallery(_ sender: UIBarButtonItem) {
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    private let reuseIdentifier = "ImageCell"
    private var cellWidth: CGFloat = 130
    var document: ImageGalleryDocument?
    
    var currentGallery: ImageGallery? {
        get {
            let images = imageInfo.map { image in
                ImageGallery.Image(
                    url: image.url,
                    aspectRatio: Double(image.aspectRatio)
                )
            }
            return ImageGallery(images: images)
        }
        set {
            imageInfo = newValue?.images.map { ($0.url, CGFloat($0.aspectRatio)) } ?? []
            collectionView?.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if document?.documentState == .closed {
            document?.open { [weak self] success in
                if success {
                    self?.title = self?.document?.localizedName
                    self?.currentGallery = self?.document?.gallery
                }
            }
        }
    }
    
    
    private var imageInfo = [(url: URL, aspectRatio: CGFloat)]() {
        didSet {
            document?.gallery = currentGallery
            document?.updateChangeCount(.done)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dragInteractionEnabled = true
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(scaleCellWidth))
        collectionView?.addGestureRecognizer(pinch)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageVC = segue.destination as? ImageViewController, let indexPath = sender as? IndexPath {
            imageVC.imageUrl = imageInfo[indexPath.item].url
        }
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageInfo.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.imageUrl = imageInfo[indexPath.item].url
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toImage", sender: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let imageAspectRatio = imageInfo[indexPath.item].aspectRatio
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
                move(item: item, from: source, to: destination)
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
                        self.imageInfo.insert((url.imageURL, CGFloat(localAspectRatio)), at: insertionIndexPath.item)
                    })
                }
                else {
                    context.deletePlaceholder()
                }
            }
        })
    }
    
    private typealias ImageData = (url: URL, aspectRatio: CGFloat)
    
    private func move(item: UICollectionViewDropItem, from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        collectionView?.performBatchUpdates({
            let selectedImage = imageInfo.remove(at: sourceIndexPath.item)
            imageInfo.insert(selectedImage, at: destinationIndexPath.item)
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
