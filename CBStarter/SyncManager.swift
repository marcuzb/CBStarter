//
//  SyncManager.swift
//  CompanySimulator
//
//  Created by Marcus Broome on 18/11/2014.
//  Copyright (c) 2014 Databisse Limited. All rights reserved.
//

import Foundation




class SyncManager: NSObject {
    static let sharedInstance: SyncManager = SyncManager()
    
    let REMOTE_URL = NSURL(string: Login.sharedInstance.databaseUrl)
    private var push: CBLReplication?
    private var pull: CBLReplication?
    private var manager: CBLManager?
    private var authenticator: CBLAuthenticatorProtocol?
    private var db: CBLDatabase?
    private var lastSyncError: NSError?
    private var lastPullNotificationTime: NSDate?
    private var syncStartTime: NSDate?
    var database : CBLDatabase {
        return self.db!
    }
    var databaseMaybe : CBLDatabase? {
        return self.db
    }
    
    private var _pullChannels = [String]()
    func setPullChannels( channels : [String] )
    {
        _pullChannels = []
        for channel in channels {
            _pullChannels.append(channel)
        }
    }

    
    private var pullChannels: [String] {
        get {
            return _pullChannels // ["namesClearance", "layouts", "appSettings"]
        }
    }

    
    override init(){
        super.init()
        setupManager()
        setUpDatabase(databaseName: Login.sharedInstance.database)
        setUpViews()
    }
    
    func startSyncForCurrentLogin() {
        syncStartTime = NSDate()
        let login = Login.sharedInstance
        if login.isValid {
            XCGLogger.defaultInstance().warning("startSyncForCurrentLogin with \(login.userName!)")
            setUpAuthenticator(userName: login.userName!, password: login.password!)
            sync()
        }
        else {
            if let user_name = login.userName, let password = login.getStoredPassword()  {
                setUpAuthenticator(userName: user_name, password: password)
                sync()
            }
        }
    }
    
    class func performBackgroundSync(completionHandler callback: (UIBackgroundFetchResult) -> ()) -> OneOffBackgroundPull? {
        let login = Login.sharedInstance
        if let password = login.getStoredPassword(), let manager = SyncManager.getCblManager(), let url = NSURL(string: login.databaseUrl) {
            var error: NSError?
            if let sync_db = manager.databaseNamed(login.database, error: &error) {
                if let err = error {
                    println(err)
                }
                else {
                    if let pullReplication = sync_db.createPullReplication(url) {
                        pullReplication.continuous = false
                        pullReplication.authenticator = SyncManager.createAuthenticator(userName: login.userName!, password: password)
                        pullReplication.channels = SyncManager.sharedInstance.pullChannels
                        return OneOffBackgroundPull(replication: pullReplication, completionHandler: callback)
                    }
                }
            }
        }
        callback(UIBackgroundFetchResult.Failed)
        return nil
    }
    
    class func getNextVersion(rev: CBLUnsavedRevision) -> Int {
        return ((rev["version"] as? Int) ?? 0) + 1
    }
    
    private static func getCblManager() -> CBLManager? {
        //if let manager = CBLManager.sharedInstance() {
        let manager = CBLManager.sharedInstance()
        manager.excludedFromBackup = true
        return manager
        //}
        //return nil
    }
    
    private func setupManager(){
        manager =  SyncManager.getCblManager()
        if manager == nil {
            XCGLogger.defaultInstance().error( "Problem setting up DB Manager - Cannot create Manager Instance")
            exit(-1)
        }
    }
    
    private func setUpDatabase(#databaseName: String) {
        var error: NSError?
        db = manager!.databaseNamed(databaseName, error: &error)
        if let err = error {
            XCGLogger.defaultInstance().error("Database not set up! " + err.localizedDescription )
        }
    }
    
    private func resetDatabase(#databaseName : String) {
        var error: NSError?
        setUpDatabase(databaseName: databaseName)
        if !db!.deleteDatabase(&error) {
            XCGLogger.defaultInstance().error("Problem deleting Database")
        }
        db = nil
        setUpDatabase(databaseName: databaseName)
    }
    
    private func sync(){
        defineSync()
        observeSync()
        startSync()
    }
    
    private static func createAuthenticator(#userName: String, password: String) -> CBLAuthenticatorProtocol? {
        return CBLAuthenticator.basicAuthenticatorWithName(userName, password: password)
    }
    
    private func setUpAuthenticator(#userName: String, password: String) {
        authenticator = SyncManager.createAuthenticator(userName: userName, password: password)
    }
    
    private func defineSync(){
        if let url = REMOTE_URL {
            if let pushReplication = db?.createPushReplication(url) {
                pushReplication.continuous = true
                pushReplication.authenticator = self.authenticator
                push = pushReplication
            }
            
            if let pullReplication = db?.createPullReplication(url) {
                pullReplication.continuous = true
                pullReplication.authenticator = self.authenticator
                pullReplication.channels = SyncManager.sharedInstance.pullChannels
                pull = pullReplication
            }
        }
    }
    
    private func stopObservingSync() {
        if (pull != nil) || (push != nil) {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    private func observeSync() {
        stopObservingSync()
        if let pullReplication = pull {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:",
                name: kCBLReplicationChangeNotification, object: pullReplication)
        }
        if let pushReplication = push {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:",
                name: kCBLReplicationChangeNotification, object: pushReplication)
        }
    }
    
    func replicationProgress(notification: NSNotification) {
        if notification.object as? CBLReplication == pull {
            let status = (pull?.status ?? .Offline)
            if ((status == .Active) || (status == .Idle)) {
                lastPullNotificationTime = NSDate()
            }
        }
        
        if (pull?.status ?? .Offline) == .Active || (push?.status ?? .Offline) == .Active {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        checkReplicationErrors()
    }
    
    private func checkReplicationErrors(){
        let error = pull?.lastError ?? push?.lastError
        if let err = error{
            if error != lastSyncError {
                lastSyncError = error!
                if let err = error {
                    XCGLogger.defaultInstance().error("Replication Error:" + err.localizedDescription )
                }
            }
        }
    }
    
    var pullStatus: CBLReplicationStatus {
        return (pull?.status ?? .Offline)
    }
    var isPulling: Bool {
        let status = pullStatus
        return (status == .Active) || (status == .Idle)
    }
    var pullStatusMessage: String {
        if let pl = pull {
            switch pl.status {
            case .Stopped :
                return "Stopped"
            case .Offline :
                return "Offline"
            default :
                return "OK"
            }
        }
        else {
            return "Down"
        }
    }
    var lastPullError: NSError? {
        return pull?.lastError
    }
    var lastPullTime: NSDate? {
        return lastPullNotificationTime
    }
    var secondsSinceLastPull: NSTimeInterval {
        if let last_pull = lastPullNotificationTime {
            return NSDate().timeIntervalSinceDate(last_pull)
        }
        return NSTimeInterval(-1)
    }
    var secondsSinceSyncStarted: NSTimeInterval {
        if let started = syncStartTime {
            return NSDate().timeIntervalSinceDate(started)
        }
        return NSTimeInterval(-1)
    }
    private func isTimeToRestartSync() -> Bool {
        if (syncStartTime == nil) {
            return true
        }
        return (secondsSinceSyncStarted > 20)
    }
    
    var pushStatus: CBLReplicationStatus {
        return (push?.status ?? .Offline)
    }
    var isPushing: Bool {
        let status = pushStatus
        return (status == .Active) || (status == .Idle)
    }
    var lastPushError: NSError? {
        return push?.lastError
    }
    
    func checkSyncStatus(userRequested: Bool = false) {
        if (pull != nil) && isPulling {
            return
        }
        if (pull == nil) {
            if userRequested || isTimeToRestartSync() {
                startSyncForCurrentLogin()
            }
        }
        else if (pullStatus == .Stopped) ||
            ((pullStatus == .Offline)
                && isTimeToRestartSync()
                && ((lastPullNotificationTime == nil) || (secondsSinceLastPull > 120))
            ) {
                syncStartTime = NSDate()
                pull!.restart()
                push?.restart()
        }
    }
    
    func getStatusMessageVerbose() -> String {
        var msg = "", desc = "unknown", usermsg = "", pullmsg = (isPulling ? "OK" : "Down")
        
        let login = Login.sharedInstance
        if login.isValid {
            usermsg = "valid user"
        }
        else {
            if let userName = login.userName
            {
                usermsg = "\(userName) not valid user"
            }
            else
            {
                usermsg = "login.userName is nil"
            }
        }
        if pull == nil {
            msg = "pull is nil, status is undefined"
        }
        else
        {
            switch pull!.status {
                case .Stopped :
                    desc = "Stopped"
                case .Offline :
                    desc = "Offline"
                case .Active :
                    desc = "Active"
                case .Idle :
                    desc = "Idle"
            }
            msg = "pull status is " + pull!.status.rawValue.description + " " + desc
        }
        return "\(msg) ie \(pullmsg) \(usermsg)"
    }
    
    func getStatusMessage() -> NSAttributedString {
        let font_normal = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        let font_descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption1)
        let font_bold = UIFont(descriptor: font_descriptor.fontDescriptorWithSymbolicTraits(.TraitBold)!, size: 0)
        
        let bold_attrs = [NSFontAttributeName : font_bold]
        let bad_attrs = [NSFontAttributeName : font_bold, NSForegroundColorAttributeName : UIColor.redColor()]
        let normal_attrs = [NSFontAttributeName : font_normal]
        
        let message = NSMutableAttributedString()
        
        message.appendAttributedString(NSAttributedString(string: "Connection: ", attributes: normal_attrs))
        message.appendAttributedString(NSAttributedString(string: pullStatusMessage, attributes: (isPulling ? bold_attrs : bad_attrs)))
        
        
        if let dtm = lastPullTime {
            message.appendAttributedString(NSAttributedString(string: " (\(TimeStamper.getNiceDate(dtm)))", attributes: normal_attrs))
        }
        return message
    }
    
    
    private func startSync () {
        pull?.start()
        push?.start()
    }
    
    func stopSync() {
        syncStartTime = nil
        stopObservingSync()
        pull?.stop()
        pull = nil
        push?.stop()
        push = nil
    }
    
    func enableLogging(){
        CBLManager.enableLogging("Sync")
    }
    
    func setUpViews(){
        if let db = self.db {
            ViewsManager.setUpAllViews(db)
        }
    }
    
    deinit {
        stopObservingSync()
    }
}











