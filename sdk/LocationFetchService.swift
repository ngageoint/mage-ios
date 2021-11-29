//
//  LocationFetchService.m
//  mage-ios-sdk
//
//

import Foundation

@objc public class LocationFetchService: NSObject {
    
    @objc public static let singleton = LocationFetchService()
    @objc public var started = false
    
    var interval: TimeInterval = Double(UserDefaults.standard.userFetchFrequency)
    var locationFetchTimer: Timer?
    
    private override init() {
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: "userFetchFrequency", options: .new, context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else {
            return
        }
        
        if change[NSKeyValueChangeKey.newKey] as? Double == interval {
            // we were called but thev alue is the same, ignore it
            return
        }
        if let interval = change[NSKeyValueChangeKey.newKey] as? Double {
            self.interval = interval
            if started {
                start()
            }
        }
    }
    
    @objc public func start() {
        stop()
        pullLocations()
        started = true
    }
    
    @objc public func stop() {
        NSLog("Stopping the location fetch timer")
        DispatchQueue.main.async { [weak self] in
            if let timer = self?.locationFetchTimer, timer.isValid {
                timer.invalidate()
                self?.locationFetchTimer = nil
            }
        }
        self.started = false
    }
    
    func pullLocations() {
        if !DataConnectionUtilities.shouldFetchLocations() {
            scheduleTimer()
            return
        }
        
        let locationFetchTask: URLSessionTask? = Location.operationToPullLocations { task, response in
            NSLog("Scheduling the location fetch timer")
            self.scheduleTimer()
        } failure: { task, error in
            NSLog("Failed to pull locations, scheduling the timer again")
            self.scheduleTimer()
        }

        NSLog("pulling locations")
        if let locationFetchTask = locationFetchTask {
            MageSessionManager.shared().addTask(locationFetchTask)
        }
    }
    
    func scheduleTimer() {
        if UserUtility.singleton.isTokenExpired {
            return;
        }
        if let locationFetchTimer = locationFetchTimer, locationFetchTimer.isValid {
            locationFetchTimer.invalidate()
            self.locationFetchTimer = nil
        }
        DispatchQueue.main.async { [weak self] in
            guard let fetchService = self else {
                return
            }
            self?.locationFetchTimer = Timer.scheduledTimer(timeInterval: fetchService.interval, target: fetchService, selector: #selector(fetchService.onTimerFire), userInfo: nil, repeats: false)
        }
    }
    
    @objc func onTimerFire() {
        if !UserUtility.singleton.isTokenExpired {
            pullLocations()
        }
    }
}
