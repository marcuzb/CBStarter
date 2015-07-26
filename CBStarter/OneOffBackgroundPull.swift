//
//  OneOffBackgroundPull.swift
//  Clearance
//
//  Created by Jonathan Clarke on 29/06/2015.
//  Copyright (c) 2015 Jonathan Clarke. All rights reserved.
//

import Foundation

class OneOffBackgroundPull: NSObject {
    private var m_replication: CBLReplication?
    private var m_callback: ((UIBackgroundFetchResult) -> ())?
    private var m_change_count: Int
    private var m_timeout: NSTimer?
    
    var changeCount: Int {
        get { return m_change_count }
    }
    
    func replicationProgress(notification: NSNotification) {
        if notification.object as? CBLReplication == m_replication {
            if let repl = m_replication {
                if repl.status == .Stopped {
                    if let err = repl.lastError {
                        m_change_count = -1
                    }
                    else {
                        m_change_count = Int(repl.completedChangesCount)
                    }
                    dispose()
                }
                else if repl.status == .Offline {
                    m_change_count = -1
                    dispose()
                }
            }
        }
    }
    
    init(replication: CBLReplication, completionHandler callback: (UIBackgroundFetchResult) -> ()) {
        m_change_count = -1
        super.init()
        m_callback = callback
        m_replication = replication
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:",
            name: kCBLReplicationChangeNotification, object: replication)
        m_timeout = NSTimer.scheduledTimerWithTimeInterval(25, target:self, selector: Selector("timeout"), userInfo: nil, repeats: false)
        replication.start()
    }
    private func removeReplicationObserver() {
        if let repl = m_replication {
            m_replication = nil
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    private func doCallback() {
        if let cb = m_callback {
            m_callback = nil
            cb(m_change_count == -1 ? UIBackgroundFetchResult.Failed : (m_change_count == 0 ? UIBackgroundFetchResult.NoData : UIBackgroundFetchResult.NewData))
        }
    }
    private func stopTimer() {
        if let timer = m_timeout {
            m_timeout = nil
            timer.invalidate()
        }
    }
    func timeout() {
        if let repl = m_replication {
            repl.stop()
        }
        dispose()
    }
    
    func dispose() {
        stopTimer()
        removeReplicationObserver()
        doCallback()
    }
    
    deinit {
        dispose()
    }
}
