//
//  LocationFetchService.m
//  mage-ios-sdk
//
//

import Foundation
import Persistence
import ServerDTO
import UseCaseFactory
import LocationFetch

public class LocationFetchService: NSObject {
    
    public static let singleton = LocationFetchService()
    public var started = false
    
    var interval: TimeInterval = Double(UserDefaults.standard.userFetchFrequency)
    var locationFetchTimer: Timer?
    
    private override init() {
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: "userFetchFrequency", options: .new, context: nil)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "userFetchFrequency")
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
    
    public func start() {
        stop()
        pullLocations()
        started = true
    }
    
    public func stop() {
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
        
        Task { [weak self] in
            defer {
                self?.scheduleTimer()
            }
            guard let currentEvent = Server.currentEventId() else {
                return
            }
            do {
                let eventID = EventID(currentEvent)
                let useCase = try await DependencyContainer.shared.useCaseFactory.resolve(
                    .EventLocationFetchUseCase
                )
                try await useCase
                    .execute(
                        eventID: eventID,
                        currentUserID: UserDefaults.standard
                            .currentUserId
                    )
                LocationFetchPackage.logger.info("Successfully fetched locations")
            } catch {
                LocationFetchPackage.logger.error("Failed to fetch locations: \(error.localizedDescription)")
            }
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
