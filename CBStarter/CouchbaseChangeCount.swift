//
//  CouchbaseChangeCount.swift
//  Clearance
//
//  Created by David on 05/03/2015.
//  Copyright (c) 2015 Jonathan Clarke. All rights reserved.
//

import Foundation
import UIKit

class CouchbaseChangeCount {
    /*
    private static let IS_UPDATING_KEY = "cb_change_count_updating"
    private class func getSequenceKey() -> String? {
        if let user = Login.sharedInstance.userName {
            return "seq_\(user)@\(Login.sharedInstance.database)"
        }
        return nil
    }
    private static var isUpdatingBadge: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(CouchbaseChangeCount.IS_UPDATING_KEY)
        }
        set (b) {
            NSUserDefaults.standardUserDefaults().setBool(b, forKey: CouchbaseChangeCount.IS_UPDATING_KEY)
        }
    }
    private static var lastSequenceNumber: Int {
        get {
            if let key = CouchbaseChangeCount.getSequenceKey() {
                return NSUserDefaults.standardUserDefaults().integerForKey(key)
            }
            return 0
        }
        set (n) {
            if let key = CouchbaseChangeCount.getSequenceKey() {
                NSUserDefaults.standardUserDefaults().setInteger(n, forKey: key)
            }
        }
    }
    */
    private static var canUpdateAppBadge: Bool {
        let application = UIApplication.sharedApplication()
        let settings = application.currentUserNotificationSettings()
        return settings.types.rawValue & UIUserNotificationType.Badge.rawValue != 0
    }
    
    class func incrementAppBadge(n: Int) {
        if canUpdateAppBadge {
            UIApplication.sharedApplication().applicationIconBadgeNumber += n
        }
    }
    
    private class func clearAppBadge() {
        if canUpdateAppBadge {
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        }
    }
    /*
    private class func getUrl() -> String {
        let last_seq = CouchbaseChangeCount.lastSequenceNumber
        if last_seq == 0 {
            return "\(Login.sharedInstance.databaseUrl)/_changes"
        }
        return "\(Login.sharedInstance.databaseUrl)/_changes?since=\(last_seq)"
    }
    
    private class func updateChangeCountFromServerResponse(response: NSDictionary) -> Bool {
        var got_new_data = true
        if let last_seq = (response["last_seq"] as? String)?.toInt() {
            if last_seq != CouchbaseChangeCount.lastSequenceNumber {
                if CouchbaseChangeCount.isUpdatingBadge {
                    if let results = response["results"] as? NSArray {
                        let n = results.count
                        if n == 0 {
                            got_new_data = false
                        }
                        else {
                            CouchbaseChangeCount.incrementAppBadge(n)
                        }
                    }
                    else {
                        got_new_data = false
                    }
                }
                else {
                    CouchbaseChangeCount.isUpdatingBadge = true
                }
                CouchbaseChangeCount.lastSequenceNumber = last_seq
            }
            else {
                got_new_data = false
            }
        }
        return got_new_data
    }
    
    class func fetchChangeCountFromServerThenCallback(callback: (UIBackgroundFetchResult) -> ()) {
        if let user = Login.sharedInstance.userName {
            let credential = AgnosticData.getSessionCredentialForUser(user, andPassword: "secret")
            AgnosticData.fetchJsonFromUrl(url: CouchbaseChangeCount.getUrl(), thenCallback: { (json: NSDictionary?, message: String?) -> () in
                if let response = json {
                    callback(CouchbaseChangeCount.updateChangeCountFromServerResponse(response) ? UIBackgroundFetchResult.NewData : UIBackgroundFetchResult.NoData)
                }
                else {
                    callback(UIBackgroundFetchResult.Failed)
                }
            }, withCredential: credential)
        }
        else {
            callback(UIBackgroundFetchResult.Failed)
        }
    }
    
    */
    class func clear() {
        CouchbaseChangeCount.clearAppBadge()
        /*
        if CouchbaseChangeCount.isUpdatingBadge {
            CouchbaseChangeCount.clearAppBadge()
            CouchbaseChangeCount.isUpdatingBadge = false
        }
        */
    }
}