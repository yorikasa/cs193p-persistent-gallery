//
//  ImageItem.swift
//  Image Gallery
//
//  Created by Yuki Orikasa on 2018/07/07.
//  Copyright © 2018 Yuki Orikasa. All rights reserved.
//

import UIKit
import MobileCoreServices

class ImageItem: NSObject, Codable {
    var imageSize: CGSize
    var aspectRatio: CGFloat {
        return  imageSize.height / imageSize.width
    }
    var url: URL
    var createdAt: Date
    
    init(size: CGSize, url: String) {
        imageSize = size
        self.url = URL.init(string: url)!
        createdAt = Date()
    }
    
    init(size: CGSize, url: URL) {
        imageSize = size
        self.url = url
        createdAt = Date()
    }
    
    init(url: URL) {
        imageSize = CGSize(width: 100, height: 100)
        self.url = url
        createdAt = Date()
    }
    
    override init() {
        imageSize = CGSize(width: 100, height: 100)
        self.url = URL.init(string: "url")!
        createdAt = Date()
        
        super.init()
    }
}

extension ImageItem {
    static func == (lhs: ImageItem, rhs: ImageItem ) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return true
        } else {
            return false
        }
    }
}

enum ImageItemError: Error {
    case invalidTypeIdentifier
}

// MARK: - Drag & Drop
extension ImageItem {
    func dragItem() -> UIDragItem {
        let itemProvider = NSItemProvider(item: self.url as NSURL, typeIdentifier: kUTTypeURL as String)
        return UIDragItem(itemProvider: itemProvider)
    }
}

// MARK: - NSItemProviderReading (creates model object from data)
extension ImageItem: NSItemProviderReading {
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        switch typeIdentifier {
        case String(kUTTypeURL):
            return self.init(size: CGSize(width: 100, height: 100),
                             url: URL(string: "dsio")!)
        case String(kUTTypeUTF8PlainText):
            return self.init(size: CGSize(width: 100, height: 100),
                             url: String(data: data, encoding: .utf8)!)
        default:
            throw ImageItemError.invalidTypeIdentifier
        }
    }
    
    static var readableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeURL as String, kUTTypeUTF8PlainText as String]
    }
}

// MARK: - NSItemProviderWriting (exports data from model object)
//extension ImageItem: NSItemProviderWriting {
//    static var writableTypeIdentifiersForItemProvider: [String] {
//        <#code#>
//    }
//
//    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
//        <#code#>
//    }
//}
