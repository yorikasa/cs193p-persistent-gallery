//
//  ImageCollectionViewController.swift
//  Image Gallery
//
//  Created by Yuki Orikasa on 2018/07/08.
//  Copyright © 2018 Yuki Orikasa. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Image Cell"

class ImageCollectionViewController: UICollectionViewController {
    
//    var gallery: Gallery? {
//        didSet {
//            collection = gallery!.collection
//        }
//    }
    
    var gallery: Gallery? {
        get {
            return galleryDocument?.gallery
        }
        set {
            galleryDocument?.gallery = newValue
        }
    }
    
    var cellWidth: CGFloat = 100
    var galleryDocument: GalleryDocument?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // The code below don't have to be here when prototype cell was created in the storyboard!
        // self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        registerGestures()
        collectionView?.dragInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        galleryDocument?.open(completionHandler: { (success) in
            if success {
                self.navigationItem.title = self.galleryDocument?.localizedName
                self.collectionView?.reloadData()
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Image Detail" {
            if let vc = segue.destination as? ImageDetailViewController {
                if let item = sender as? ImageCollectionViewCell {
                    if let indexPath = collectionView?.indexPath(for: item) {
                        vc.imageURL = gallery?.collection[indexPath.item].url
                    }
                }
            }
        }
    }
}

// MARK: - Actions
extension ImageCollectionViewController {
    @IBAction func dismissView(_ sender: UIBarButtonItem) {
        // these lines of code should have been named "documentUpdated" or such.
        galleryDocument?.gallery = gallery
        if galleryDocument?.gallery != nil {
            galleryDocument?.updateChangeCount(.done)
        }
        
        dismiss(animated: true) {
            self.galleryDocument?.close(completionHandler: nil)
        }
    }
}

// MARK: - DataSource & Delegate & DelegateFlowLayout
extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        if let collection = gallery?.collection {
            return collection.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            DispatchQueue.global(qos: .userInitiated).async {
                if let url = self.gallery?.collection[indexPath.row].url {
//                    let fetchedImage = self.fetchImage(url: url, imageCell: imageCell)
                    DispatchQueue.main.async {
//                        imageCell.imageView.image = fetchedImage
                        self.fetchImage(url: url, imageCell: imageCell)
                    }
                }
            }
            return imageCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth: CGFloat = self.cellWidth
        let cellHeight: CGFloat = CGFloat(gallery?.collection[indexPath.item].aspectRatio ?? 1) * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    private func fetchImage(url: URL, imageCell: ImageCollectionViewCell) {
        let sharedCache = URLCache.shared
        let request = URLRequest(url: url)
        if let response = sharedCache.cachedResponse(for: request) {
            DispatchQueue.main.async {
                imageCell.imageView.image = UIImage(data: response.data)
            }
        } else {
            // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        print(error as Any)
                        return
                }
                if let data = data, let response = response {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    sharedCache.storeCachedResponse(cachedResponse, for: request)
                    DispatchQueue.main.async {
                        imageCell.imageView.image = UIImage(data: data)
                    }
                }
            }
            task.resume()
        }
    }
}

// MARK: - UICollectionView Drag Delegate
extension ImageCollectionViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = "local dd!"
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        guard gallery != nil else {
            return []
        }
        let imageItem = gallery!.collection[indexPath.item]
        let dragItem = imageItem.dragItem()
        dragItem.localObject = imageItem
        return [dragItem]
    }
}

// MARK: - UICollectionView Drop Delegate
extension ImageCollectionViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isLocal = (session.localDragSession?.localContext as? String) == "local dd!"
        return UICollectionViewDropProposal(operation: isLocal ? .move : .copy,
                                            intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard gallery != nil else { return }
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if coordinator.session.localDragSession != nil {
                // this may be dangerous (force unwrap sourceIndexPath)
                guard item.sourceIndexPath != nil else {return}
                if let imageItem = item.dragItem.localObject as? ImageItem {
                    // this may also dangerous
                    // `index` of collecion always equals to `sourceIndexPath` of collectionView???
                    // let index = self.collection.index(of: imageItem)
                    
                    collectionView.performBatchUpdates({
                        self.gallery!.collection.remove(at: item.sourceIndexPath!.item)
                        self.gallery!.collection.insert(imageItem, at: destinationIndexPath.item)
                        //collectionView.moveItem(at: item.sourceIndexPath!, to: destinationIndexPath)
                    })
                    // this animate drop! but slightly glitchy yet
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                // drop from outside
                // TODO: animate drop when cross-app drop
                let placeholder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath,
                                                                  reuseIdentifier: "Placeholder Cell")
                let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)
                
                let newItem = ImageItem()
                DispatchQueue.main.async {
                    placeholderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
                        self.gallery!.collection.insert(newItem, at: insertionIndexPath.item)
                        //collectionView.insertItems(at: [insertionIndexPath])
                    })
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let url = provider as? NSURL {
                        newItem.url = url as URL
                    }
                    DispatchQueue.main.async {
                        //collectionView.reloadItems(at: [destinationIndexPath])
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        newItem.imageSize = image.size
                    }
                    DispatchQueue.main.async {
                        //collectionView.reloadItems(at: [destinationIndexPath])
                    }
                }
            }
        }
    }
}


// MARK: - Add Pinch to Zoom Gestures
extension ImageCollectionViewController {
    
    @objc private func changeCellWidth(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .ended:
            self.cellWidth = self.cellWidth * sender.scale
            collectionView?.reloadData()
        default:
            break
        }
    }
    private func registerGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(changeCellWidth(_:)))
        collectionView?.addGestureRecognizer(pinch)
    }
    
}
