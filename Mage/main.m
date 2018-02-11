//
//  main.m
//  Mage
//
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char * argv[])
{
#import "AppDelegate.h"
    
    @autoreleasepool {
        Class appDelegateClass = NSClassFromString(@"TestingAppDelegate");
        if (!appDelegateClass)
            appDelegateClass = [AppDelegate class];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
    }
    
    
    
//    @autoreleasepool {
//        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//    }
}
