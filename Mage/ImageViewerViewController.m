//
//  ImageViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 8/13/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ImageViewerViewController.h"
#import <FICImageCache.h>
#import "AppDelegate.h"

@interface ImageViewerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) BOOL shouldHideNavBar;

@end

@implementation ImageViewerViewController

bool originalNavBarHidden;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.imageUrl != nil) {
        [self imageView].image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageUrl]];
    } else {
        FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
            [self imageView].image = image;
        };
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        BOOL imageExists = [delegate.imageCache retrieveImageForEntity:[self attachment] withFormatName:AttachmentLarge completionBlock:completionBlock];
        
        if (imageExists == NO) {
            [self imageView].image = [UIImage imageNamed:@"download"];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    originalNavBarHidden = [self.navigationController isNavigationBarHidden];
    [self.navigationController setNavigationBarHidden:_shouldHideNavBar animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:originalNavBarHidden animated:animated];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
