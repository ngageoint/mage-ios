//
//  MageInitializer.m
//  MAGE
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageInitializer.h"

#import "MagicalRecord+MAGE.h"
#import <mach/mach.h>

@implementation MageInitializer

+ (void) initializePreferences {

    NSURL *sdkPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences-sdk" withExtension:@"plist"];
    NSDictionary *sdkPreferences = [NSDictionary dictionaryWithContentsOfURL:sdkPreferencesFile];

    NSURL *defaultPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences" withExtension:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesFile];

    NSMutableDictionary *allPreferences = [[NSMutableDictionary alloc] initWithDictionary:sdkPreferences];
    [allPreferences addEntriesFromDictionary:defaultPreferences];
    NSLog(@"+++++++++++++++++++ Standard User Defaults observers %@", [[NSUserDefaults standardUserDefaults] observationInfo]);
    [MageInitializer reportMemory];
    [[NSUserDefaults standardUserDefaults]  registerDefaults:allPreferences];
}

+ (void) reportMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
        NSLog(@"Memory in use (in MiB): %f", ((CGFloat)info.resident_size / 1048576));
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

+ (void) setupCoreData {
    [MagicalRecord setupMageCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
}

+ (void) clearAndSetupCoreData {
    [MagicalRecord deleteAndSetupMageCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
}

@end
