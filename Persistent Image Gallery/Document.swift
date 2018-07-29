//
//  Document.swift
//  Persistent Image Gallery
//
//  Created by Yuki Orikasa on 2018/07/29.
//  Copyright © 2018 Yuki Orikasa. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

