//
//  ImageCacheTests.m
//  MAGETests
//
//  Created by Daniel Barela on 2/21/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//
@import OHHTTPStubs;

#import <XCTest/XCTest.h>
//#import <OCMock/OCMock.h>
//#import "MAGE-Swift.h"
//#import "Attachment+Thumbnail.h"
//#import <FICImageCache.h>
//#import "MagicalRecord+MAGE.h"
//#import "MageSessionManager.h"
//#import "StoredPassword.h"

@interface ImageCacheTests : XCTestCase
//@property (strong, nonatomic) ImageCacheProvider *imageProvider;
- (UIImage *) createUIImageFromURL: (NSURL *) url;
@end

@implementation ImageCacheTests

//- (void)setUp {
//    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
//    [MagicalRecord setupCoreDataStackWithInMemoryStore];
//    [[MageSessionManager manager] setToken:@"oldtoken"];
//    [StoredPassword persistTokenToKeyChain:@"oldtoken"];
//    self.imageProvider = ImageCacheProvider.shared;
//}
//
//- (void)tearDown {
//    self.imageProvider = NULL;
//    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
//    [OHHTTPStubs removeAllStubs];
//}
//
//- (void)testLoadAnImage {
//    CGSize size = CGSizeMake(75, 75);
//    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
//    [[UIColor whiteColor] setFill];
//    UIRectFill(CGRectMake(0, 0, size.width, size.height));
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    id imageCacheMock = OCMPartialMock(self.imageProvider);
//
//    [OCMStub([imageCacheMock createUIImageFromURL:[OCMArg any]]) andReturn:UIImagePNGRepresentation(image)];
//
////    id nsdataMock = OCMClassMock([NSData class]);
////    [OCMStub([nsdataMock dataWithContentsOfURL:[OCMArg any]]) andReturn:UIImagePNGRepresentation(image)];
//
////    [OCMStub([nsdataMock dataWithContentsOfURL:[NSURL URLWithString: @"https://mage.geointservices.io/testimage?access_token=oldtoken&size=75"]]) andReturn:UIImagePNGRepresentation(image)];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//
//    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
//    Attachment *attachment = [Attachment MR_createEntity];
//    attachment.url = @"https://mage.geointservices.io/testimage";
//    attachment.contentType = @"image/png";
//    dispatch_async(dispatch_get_main_queue(), ^{
//        BOOL imageExists = [sharedImageCache retrieveImageForEntity:attachment withFormatName:AttachmentSmallSquare completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
//            NSLog(@"hello");
//            NSLog(@"image height %f", image.size.height);
//            NSLog(@"image width %f", image.size.width);
//        }];
//    });
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        NSLog(@"did it");
//    }];
//}

@end
