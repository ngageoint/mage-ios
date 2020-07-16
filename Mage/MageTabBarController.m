//
//  MageTabBarController.m
//  MAGE
//
//

#import "MageTabBarController.h"
#import "MeViewController.h"
#import "ObservationViewController_iPad.h"

@implementation MageTabBarController

//func createFeedViewController(feed: Feed) -> UINavigationController {
//    let size = 24;
//    let fvc = FeedItemsViewController(feed: feed);
//    let nc = UINavigationController(rootViewController: fvc);
//    setNavigationControllerAppearance(nc: nc);
//    nc.tabBarItem = UITabBarItem(title: feed.title, image: nil, tag: feed.id!.intValue + 5);
//    nc.tabBarItem.image = UIImage(named: "marker")?.aspectResize(to: CGSize(width: size, height: size));
//
//    if let url: URL = feed.iconURL() {
//        let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
//        KingfisherManager.shared.retrieveImage(with: url, options: [
//                                                                    .processor(processor),
//                                                                    .scaleFactor(UIScreen.main.scale),
//                                                                    .transition(.fade(1)),
//                                                                    .cacheOriginalImage
//                                                                    ]) { result in
//            switch result {
//            case .success(let value):
//                let image: UIImage = value.image.aspectResize(to: CGSize(width: size, height: size));
//                nc.tabBarItem.image = image;
//            case .failure(let error):
//                print(error);
//            }
//        }
//    }
//    return nc;
//}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    UINavigationController *navigationController = [self navigationController];
    [navigationController popToRootViewControllerAnimated:NO];
    
    if ([[segue identifier] isEqualToString:@"DisplayPersonFromMapSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        [destination setUser:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationFromMapSegue"]) {
        ObservationViewController_iPad *destination = (ObservationViewController_iPad *)[segue destinationViewController];
        [destination setObservation:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayFeedItemFromMapSeque"]) {
        NSLog(@"Feed item tapped segue");
    }
}

@end
