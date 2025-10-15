//
//  main.m
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

static Class ResolveSwiftClass(NSString *name) {
    Class resolvedClass = NSClassFromString(name);
    if (resolvedClass) return resolvedClass;
    
    NSString *module = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    
    if (module.length > 0) {
        NSString *scoped = [NSString stringWithFormat:@"%@.%@", module, name];
        resolvedClass = NSClassFromString(scoped);
    }
    return resolvedClass;
    
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
        // Are we under XCTest?
        BOOL runningTests = [[[NSProcessInfo processInfo] environment] objectForKey:@"XCTestConfigurationFilePath"] != nil;
        
        Class appDelegateClass = [AppDelegate class];
        
        if (runningTests) {
            // Default test delegate
            Class testing = ResolveSwiftClass(@"TestingAppDelegate");
            if (testing) appDelegateClass = testing;
            
            // Simple host for "view testing"
            NSString *viewTesting = [[[NSProcessInfo processInfo] environment] objectForKey:@"VIEW_TESTING"];
            if ([viewTesting isEqualToString:@"true"]) {
                Class viewLoader = ResolveSwiftClass(@"ViewLoaderAppDelegate");
                if (viewLoader) appDelegateClass = viewLoader;
            }
        }

        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
    }
}
