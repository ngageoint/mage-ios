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
        Class appDelegateClass = ResolveSwiftClass(@"TestingAppDelegate");

        NSLog(@"View testing is %@",[[[NSProcessInfo processInfo] environment] objectForKey:@"VIEW_TESTING"]);
        
        NSString *viewTesting = [[[NSProcessInfo processInfo] environment] objectForKey: @"VIEW_TESTING"];
        if([viewTesting isEqualToString:@"true"]) {
            Class viewLoader = ResolveSwiftClass(@"ViewLoaderAppDelegate");
            if (viewLoader) { appDelegateClass = viewLoader; }
        }
        
        // Last resort; production AppDelegate
        if (!appDelegateClass) {
            appDelegateClass = [AppDelegate class];
        }
        
        NSLog(@"AppDelegate class: %@", NSStringFromClass(appDelegateClass));
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
    }
}
