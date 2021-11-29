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

//#import "LocationFetchService.h"
//#import "MageSessionManager.h"
//#import "DataConnectionUtilities.h"
//#import "MAGE-Swift.h"
//
//NSString * const kLocationFetchFrequencyKey = @"userFetchFrequency";
//
//@interface LocationFetchService ()
//    @property (nonatomic) NSTimeInterval interval;
//    @property (nonatomic, strong) NSTimer* locationFetchTimer;
//@end
//
//@implementation LocationFetchService
//
//+ (instancetype) singleton {
//    static LocationFetchService *fetchService = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        fetchService = [[self alloc] init];
//        fetchService.started = false;
//    });
//    return fetchService;
//}
//
//- (id) init {
//    if (self = [super init]) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//        _interval = [[defaults valueForKey:kLocationFetchFrequencyKey] doubleValue];
//
//        [[NSUserDefaults standardUserDefaults] addObserver:self
//                                                forKeyPath:kLocationFetchFrequencyKey
//                                                   options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
//                                                   context:NULL];
//    }
//
//	return self;
//}
//
//- (void) start {
//    [self stop];
//
//    [self pullLocations];
//    self.started = true;
//}
//
//- (void) scheduleTimer {
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        weakSelf.locationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:weakSelf selector:@selector(onTimerFire) userInfo:nil repeats:NO];
//    });
//}
//
//- (void) onTimerFire {
//    NSLog(@"timer to pull locations fired");
//    if (![[UserUtility singleton] isTokenExpired]) {
//        [self pullLocations];
//    }
//}
//
//- (void) pullLocations{
//    if ([DataConnectionUtilities shouldFetchLocations]) {
//        NSURLSessionDataTask *locationFetchTask = [Location operationToPullLocationsWithSuccess:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
//            if (![[UserUtility singleton] isTokenExpired]) {
//                NSLog(@"Scheduling the location fetch timer");
//                [self scheduleTimer];
//            }
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            NSLog(@"Failed to pull locations, scheduling the timer again");
//            [self scheduleTimer];
//        }];
//
//        NSLog(@"pulling locations");
//        if (locationFetchTask != nil) {
//            [[MageSessionManager sharedManager] addTask:locationFetchTask];
//        }
//        [[MageSessionManager sharedManager] addTask:locationFetchTask];
//    } else {
//        [self scheduleTimer];
//    }
//}
//
//-(void) stop {
//    self.started = false;
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        // TODO: if this gets run after the timer is schedule in start, it will stop fetching
//        if ([weakSelf.locationFetchTimer isValid]) {
//            NSLog(@"Stopping the location fetch timer");
//            [weakSelf.locationFetchTimer invalidate];
//            weakSelf.locationFetchTimer = nil;
//        }
//    });
//}
//
//- (void) observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context {
//    if ([[change objectForKey:NSKeyValueChangeNewKey] doubleValue] == _interval) {
//        // we were called but the value is the same, ignore it
//        return;
//    }
//    _interval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
//    if (_started) {
//        [self start];
//    }
//}
//
//
//@end
