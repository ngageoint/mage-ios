//
//  PopAndGoSegue.m
//  MAGE
//
//

#import "PopAndGoSegue.h"

@implementation PopAndGoSegue

-(void)perform {
    UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    UINavigationController *navigationController = sourceViewController.navigationController;

    NSArray *viewControllers = navigationController.viewControllers;
    NSMutableArray *newViewControllers = [NSMutableArray array];
    
    [newViewControllers addObject:[viewControllers objectAtIndex:0]];
    [newViewControllers addObject:destinationController];
    [navigationController setViewControllers:newViewControllers animated:YES];
}

@end
