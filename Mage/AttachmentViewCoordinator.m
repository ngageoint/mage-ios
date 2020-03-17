//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AttachmentViewCoordinator.h"
#import "DataConnectionUtilities.h"
#import "AttachmentViewController.h"
#import "FadeTransitionSegue.h"
#import "MAGE-Swift.h"

@interface AttachmentViewCoordinator()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) id<AttachmentViewDelegate> delegate;
@property (strong, nonatomic) Attachment *attachment;

@end

@implementation AttachmentViewCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate: (id<AttachmentViewDelegate>) delegate andAttachment: (Attachment *) attachment {
    self = [super init];
    if (!self) return nil;
    
    _navigationController = navigationController;
    _delegate = delegate;
    _attachment = attachment;
    
    return self;
}

- (void) start {
    if (![DataConnectionUtilities shouldFetchAttachments] && !self.attachment.localPath) {
        AskToDownloadViewController *vc = [[AskToDownloadViewController alloc] initWithAttachment:self.attachment andDelegate:self];
        [_navigationController pushViewController:vc animated:YES];
        return;
    } else {
        if ([self.attachment.contentType hasPrefix:@"image"]) {
            ImageAttachmentViewController *ac = [[ImageAttachmentViewController alloc] initWithAttachment:self.attachment];
            [_navigationController pushViewController:ac animated:NO];
        }
    }
}

- (void) downloadAttachment {
    // proceed to the attachment downloading view
    NSLog(@"Download the attachment");
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];

    [_navigationController popViewControllerAnimated:NO];
//    AttachmentViewController *vc = [[AttachmentViewController alloc] initWithAttachment:self.attachment];
//    [_navigationController pushViewController:vc animated:NO];
    
    if ([self.attachment.contentType hasPrefix:@"image"]) {
        ImageAttachmentViewController *ac = [[ImageAttachmentViewController alloc] initWithAttachment:self.attachment];
        [_navigationController pushViewController:ac animated:NO];
    }
}

@end
