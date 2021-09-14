//
//  TestingAppDelegate.m
//  MAGE
//
//  Created by Dan Barela on 2/5/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TestingAppDelegate.h"
#import "MagicalRecord+MAGE.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "MageInitializer.h"

@interface TestingAppDelegate ()
@property (nonatomic, strong) BaseMapOverlay *backgroundOverlay;
@property (nonatomic, strong) BaseMapOverlay *darkBackgroundOverlay;
@end

@implementation TestingAppDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MageInitializer initializePreferences];
    
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
    
    NSString *countriesDarkGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries_dark" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesDarkGeoPackagePath);
    
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        [manager importGeoPackageFromPath:countriesDarkGeoPackagePath];
    }
    @catch (NSException *e) {
        // probably was already imported and that is fine
    }
    NSString *countriesGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesGeoPackagePath);
    @try {
        [manager importGeoPackageFromPath:countriesGeoPackagePath];
    }
    @catch (NSException *e) {
        // probably was already imported and that is fine
    }
    
    GPKGGeoPackage *countriesGeoPackage = [manager open:@"countries"];
    if (countriesGeoPackage) {
        GPKGFeatureDao * featureDao = [countriesGeoPackage featureDaoWithTableName:@"countries"];
        
        // If indexed, add as a tile overlay
        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:countriesGeoPackage andFeatureDao:featureDao];
        [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:countriesGeoPackage andFeatureDao:featureDao]];
        
        self.backgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:featureTiles];
        [self.backgroundOverlay setMinZoom:0];
        self.backgroundOverlay.darkTheme = NO;
        
        self.backgroundOverlay.canReplaceMapContent = true;
    }
    
    GPKGGeoPackage *darkCountriesGeoPackage = [manager open:@"countries_dark"];
    if (darkCountriesGeoPackage) {
        GPKGFeatureDao * darkFeatureDao = [darkCountriesGeoPackage featureDaoWithTableName:@"countries"];
        
        // If indexed, add as a tile overlay
        GPKGFeatureTiles * darkFeatureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:darkCountriesGeoPackage andFeatureDao:darkFeatureDao];
        [darkFeatureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:darkCountriesGeoPackage andFeatureDao:darkFeatureDao]];
        
        self.darkBackgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:darkFeatureTiles];
        [self.darkBackgroundOverlay setMinZoom:0];
        self.darkBackgroundOverlay.darkTheme = YES;
        
        self.darkBackgroundOverlay.canReplaceMapContent = true;
    }
    
    return YES;
}

- (void) logout {
    self.logoutCalled = YES;
}

- (BaseMapOverlay *) getBaseMap {
    return self.backgroundOverlay;
}

- (BaseMapOverlay *) getDarkBaseMap {
    return self.darkBackgroundOverlay;
}

@end
