//
//  AttachmentCollectionDataStore.m
//  MAGE
//
//

#import "AttachmentCollectionDataStore.h"
#import "AttachmentCell.h"
#import "Attachment+FICAttachment.h"
#import "AppDelegate.h"

@implementation AttachmentCollectionDataStore

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *allAttachments = [NSMutableArray arrayWithArray:[self.observation.attachments allObjects]];
    [allAttachments addObjectsFromArray:self.observation.transientAttachments];
    
    AttachmentCell *cell = [self.attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [allAttachments objectAtIndex:[indexPath row]];
    [cell setImageForAttachament:attachment];

    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.observation.attachments.count + self.observation.transientAttachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *allAttachments = [NSMutableArray arrayWithArray:[self.observation.attachments allObjects]];
    [allAttachments addObjectsFromArray:self.observation.transientAttachments];
    
    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [allAttachments objectAtIndex:[indexPath row]];
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

@end
