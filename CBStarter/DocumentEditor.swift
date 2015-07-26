//
//  DocumentEditor.swift
//  CompanySimulator
//
//  Created by Marcus Broome on 20/01/2015.
//  Copyright (c) 2015 Databisse Limited. All rights reserved.
//

import Foundation


class DocumentEditor {
 
//  private func replaceValueAsStringForKey(key: String, withValue value: NSObject, inDoc document: CBLDocument) -> (){
//    var properties = document.properties
//    properties[key] = value
//    writeDocument(document, withProperties: properties)
//  }
//  
//  private func removeValueFromDocumentForKey(key: String, fromDoc document: CBLDocument) ->(){
//    var properties = document.properties
//    properties[key] = nil
//    writeDocument(document, withProperties: properties)
//  }
  
  func writeDocument(document: CBLDocument, withProperties properties: [NSObject: AnyObject]) {
    var error: NSError?
    if document.putProperties(properties, error: &error) == nil {
      XCGLogger.defaultInstance().error("Could not write document " + error!.localizedDescription )
    }
    
  }
  
}
