//
//  CouchbaseAttachmentList.swift
//  Clearance
//
//  Created by David on 09/03/2015.
//  Copyright (c) 2015 Jonathan Clarke. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

public class Attachment: NSObject, QLPreviewItem {
    let name: String
    let image: UIImage //?
    var tempFile: TempFile?
    var hasChanged: Bool = false
    
    /*
    public init(forName: String) {
        name = forName
        image = nil
    }
    */
    public init(forImage: UIImage, named: String) {
        name = named
        image = forImage
    }
    /*
    public var isImage: Bool {
        return image != nil
    }
    */
    
    /* QLPreviewItem */
    public var previewItemTitle: String { return name }
    public var previewItemURL: NSURL! {
        if tempFile == nil { //&& self.isImage {
            tempFile = TempFile(fromData: UIImageJPEGRepresentation(image, 0.75), withContentType: "image/jpeg")
        }
        assert(tempFile != nil)
        return tempFile!.url
    }
}

public class AttachmentList: QLPreviewControllerDataSource {
    private var doc: CBLDocument?
    private var list: [Attachment] = []
    
    init() {
        doc = nil
    }
    init(forDocument: CBLDocument) {
        doc = forDocument
        if let rev = doc?.currentRevision {
            if let attachment_names = rev.attachmentNames as [AnyObject]! {
                for i in 0 ..< attachment_names.count {
                    if let name = attachment_names[i] as? String {
                        if let attachment = rev.attachmentNamed(name), let data = attachment.content {
                            if let image = UIImage(data: data) {
                                list.append(Attachment(forImage: image, named:name))
                                /*
                                let tf = TempFile(fromData: attachment.content, named: name, withContentType: attachment.contentType)
                                println("contentUrl:\(attachment.contentURL)")
                                println("url:\(tf.url)")
                                */
                            }
                        }
                    }
                }
            }
            sortList()
        }
    }
    
    private func sortList() {
        list.sort({ (a: Attachment, b: Attachment) -> Bool in
            return a.name.caseInsensitiveCompare(b.name) == NSComparisonResult.OrderedAscending
        })
    }
    public var isEmpty: Bool { return list.count == 0 }
    public var count: Int { return list.count }
    public func add(image: UIImage, named: String) {
        let attachment = Attachment(forImage: image, named: named)
        attachment.hasChanged = true
        list.append(attachment)
        /*
        if let valid_doc = doc {
            let newRev = valid_doc.currentRevision.createRevision()
            let imageData = UIImageJPEGRepresentation(image, 0.75)
            newRev.setAttachmentNamed(named, withContentType: "image/jpeg", content: imageData)
            var error: NSError?
            assert(newRev.save(&error) != nil)
        }
        */
        sortList()
    }
    
    public func save() -> Bool {
        if doc == nil {
            return false
        }
        return saveForDocument(doc!)
    }
    
    public func saveForDocument(document: CBLDocument) -> Bool {
        var saved: Bool = false
        for attachment in list {
            if attachment.hasChanged {
                saved = true
                break
            }
        }
        if saved {
            if let rev = document.currentRevision?.createRevision() {
                for attachment in list {
                    if attachment.hasChanged {
                        let imageData = UIImageJPEGRepresentation(attachment.image, 0.75)
                        rev.setAttachmentNamed(attachment.name, withContentType: "image/jpeg", content: imageData)
                    }
                }
                var error: NSError?
                assert(rev.save(&error) != nil)
                if let err = error {
                    XCGLogger.defaultInstance().error("Attachment save failed " + err.localizedDescription )
                    return false
                }
                for attachment in list {
                    if attachment.hasChanged {
                        attachment.hasChanged = false
                    }
                }
            }
        }
        else {
            saved = true
        }
        self.doc = document
        return saved
    }
    
    /*
    public func add(forName: String) {
        list.append(Attachment(forName: forName))
    }
    */
    subscript(i: Int) -> Attachment {
        return list[i]
    }
    public func getIndexForName(name: String) -> Int {
        var i: Int
        for i in 0 ..< list.count {
            if list[i].name == name {
                return i
            }
        }
        return -1
    }
    
    /* QLPreviewControllerDataSource */
    @objc public func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
        return list.count
    }
    @objc public func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        return list[index]
    }
}

