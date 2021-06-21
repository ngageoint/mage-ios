//
//  main.m
//  Mage
//
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char * argv[]) {    
    @autoreleasepool {
        Class appDelegateClass = NSClassFromString(@"TestingAppDelegate");

        NSLog(@"View testing is %@",[[[NSProcessInfo processInfo] environment] objectForKey:@"VIEW_TESTING"]);
        if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"VIEW_TESTING"] isEqualToString:@"true"]) {
            appDelegateClass = NSClassFromString(@"ViewLoaderAppDelegate");
        }
        if (!appDelegateClass)
            appDelegateClass = [AppDelegate class];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
    }
    
//    @autoreleasepool {
//        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//    }
}
