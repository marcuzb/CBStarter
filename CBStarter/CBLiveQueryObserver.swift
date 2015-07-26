//
//  CBLiveQueryObserver.swift
//  Clearance
//
//  Created by Jonathan Clarke on 29/06/2015.
//  Copyright (c) 2015 Jonathan Clarke. All rights reserved.
//

import Foundation

protocol CBLiveQueryObserverDelegate: class {
    func liveQueryObserverHasRows(rows: CBLQueryEnumerator)
}

class CBLiveQueryObserver: NSObject {
    private var m_live_query: CBLLiveQuery?
    private var m_query: CBLQuery?
    private var m_last_fetch: NSDate?
    
    private var m_callback: ((rows: CBLQueryEnumerator) -> ())?
    private weak var m_delegate: CBLiveQueryObserverDelegate?
    
    private var m_waiting_for_update: ((isOk: Bool) -> ())?
    
    init(forQuery: CBLQuery, sortedDescending: Bool, withCallback: ((rows: CBLQueryEnumerator) -> ())? = nil) {
        super.init()
        m_live_query = forQuery.asLiveQuery()
        m_live_query!.descending = sortedDescending
        
        m_live_query!.addObserver(self, forKeyPath: "rows", options: nil, context: nil)
        m_query = forQuery
        m_callback = withCallback
        m_live_query!.start()
        /*
        println("waiting for live query rows")
        println("wait done \(m_live_query!.waitForRows())")
        */
        //m_live_query!.waitForRows()
    }
    
    func updateQuery(query: CBLQuery, sortedDescending: Bool) {
        //dispose of old version
        m_live_query?.stop()
        m_live_query?.removeObserver(self, forKeyPath: "rows")
        m_live_query = nil
        m_query = nil
        
        //start new version
        m_live_query = query.asLiveQuery()
        m_live_query!.descending = sortedDescending
        m_live_query!.addObserver(self, forKeyPath: "rows", options: nil, context: nil)
        m_query = query
        m_live_query!.start()
    }
    
    func refreshAndCallback(callback:((isOk: Bool) -> ())) {
        //not sure if this is a good idea...
        if (m_live_query == nil) {
            callback(isOk: false)
            return
        }
        m_waiting_for_update = callback
        let sortedDescending = m_live_query!.descending
        m_live_query!.stop()
        m_live_query?.removeObserver(self, forKeyPath: "rows")
        m_live_query = nil
        
        //start new version
        m_live_query = m_query!.asLiveQuery()
        m_live_query!.descending = sortedDescending
        m_live_query!.addObserver(self, forKeyPath: "rows", options: nil, context: nil)
        m_live_query!.start()
    }
    
    var delgate: CBLiveQueryObserverDelegate? {
        get {
            return m_delegate
        }
        set (d) {
            m_delegate = d
            if let d1 = d, let rows = m_live_query?.rows {
                dispatch_async(dispatch_get_main_queue()) {
                    d1.liveQueryObserverHasRows(rows)
                }
            }
        }
    }
    
    func setCallback(callback: ((rows: CBLQueryEnumerator) -> ())?) {
        m_callback = callback
        if let cb = callback {
            if let rows = m_live_query?.rows {
                dispatch_async(dispatch_get_main_queue()) {
                    cb(rows: rows)
                }
            }
        }
    }
    var lastError: NSError? {
        return m_live_query?.lastError
    }
    var lastFetch: NSDate? {
        return m_last_fetch
    }
    
    private func gotRows(rows: CBLQueryEnumerator) {
        if let cb = m_callback {
            cb(rows: rows)
        }
        if let d = m_delegate {
            d.liveQueryObserverHasRows(rows)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject,
        change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
            //println("CBLiveQueryObserver.observeValueForKeyPath")
            if let lq = m_live_query {
                if object as? NSObject == lq {
                    if let error = m_live_query!.lastError {
                        XCGLogger.defaultInstance().error(error.localizedDescription)
                    }
                    m_last_fetch = NSDate()
                    //println("CBLiveQueryObserver.observeValueForKeyPath with \(m_live_query!.rows.count)")
                    if let rows = lq.rows {
                        gotRows(rows)
                    }
                    
                    m_waiting_for_update?(isOk: m_live_query!.lastError == nil)
                    m_waiting_for_update = nil
                }
                else {
                    XCGLogger.defaultInstance().debug("Unexpected object passed to observer")
                }
            }
    }
    deinit {
        //println("CBLiveQueryObserver.deinit")
        m_live_query?.removeObserver(self, forKeyPath: "rows")
    }
}
