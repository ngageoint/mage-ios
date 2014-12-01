//
//  AttachmentCollectionDataStore.m
//  MAGE
//
//  Created by Dan Barela on 11/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AttachmentCollectionDataStore.h"
#import "AttachmentCell.h"
#import "Attachment+FICAttachment.h"
#import "AppDelegate.h"

@implementation AttachmentCollectionDataStore

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [_attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    
    FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
        cell.image.image = image;
        [cell.image.layer addAnimation:[CATransition animation] forKey:kCATransition];
        cell.image.layer.cornerRadius = 5;
        cell.image.clipsToBounds = YES;
    };
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL imageExists = [delegate.imageCache retrieveImageForEntity:attachment withFormatName:AttachmentSmallSquare completionBlock:completionBlock];
    
    if (imageExists == NO) {
        cell.image.image = [UIImage imageNamed:@"download"];
    }
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"there are %lu attachments", (unsigned long)_observation.attachments.count);
    return _observation.attachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSLog(@"clicked attachment %@", attachment.url);
    
    if (self.attachmentSelectionDelegate) {
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

@end
