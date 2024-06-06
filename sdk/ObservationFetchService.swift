//
//  ObservationFetchService.m
//  mage-ios-sdk
//
//

import Foundation

public class ObservationFetchService: NSObject {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    public static let singleton = ObservationFetchService()
    public var started = false
    
    var interval: TimeInterval = Double(UserDefaults.standard.observationFetchFrequency)
    var observationFetchTimer: Timer?
    
    private override init() {
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: "observationFetchFrequency", options: .new, context: nil)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "observationFetchFrequency")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else {
            return
        }

        if change[NSKeyValueChangeKey.newKey] as? Double == interval {
            // we were called but thevalue is the same, ignore it
            return
        }
        if let interval = change[NSKeyValueChangeKey.newKey] as? Double {
            self.interval = interval
            if started {
                start()
            }
        }
    }
    
    public func start(initial: Bool = false) {
        stop()
        pullObservations(initial: initial)
        started = true
    }
    
    public func stop() {
        NSLog("stop fetching observations")
        DispatchQueue.main.async { [weak self] in
            if let timer = self?.observationFetchTimer, timer.isValid {
                timer.invalidate();
                self?.observationFetchTimer = nil;
            }
        }
        self.started = false;
    }
    
    func pullObservations(initial: Bool = false) {
        if !DataConnectionUtilities.shouldFetchObservations() {
            scheduleTimer()
            return
        }
        Task {
            let pulled = await observationRepository.fetchObservations()
            self.scheduleTimer()
        }
    }
    
    func scheduleTimer() {
        if UserUtility.singleton.isTokenExpired {
            return;
        }
        if let observationFetchTimer = observationFetchTimer, observationFetchTimer.isValid {
            observationFetchTimer.invalidate()
            self.observationFetchTimer = nil
        }
        DispatchQueue.main.async { [weak self] in
            guard let fetchService = self else {
                return
            }
            self?.observationFetchTimer = Timer.scheduledTimer(timeInterval: fetchService.interval, target: fetchService, selector: #selector(fetchService.onTimerFire), userInfo: nil, repeats: false)
        }
    }
    
    @objc func onTimerFire() {
        if !UserUtility.singleton.isTokenExpired {
            pullObservations()
        }
    }
}
