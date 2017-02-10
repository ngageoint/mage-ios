//
//  AttachmentCollectionDataStore.m
//  MAGE
//
//

#import "AttachmentCollectionDataStore.h"
#import "AttachmentCell.h"
#import "AppDelegate.h"

@implementation AttachmentCollectionDataStore

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [self.attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
    [cell setImageForAttachament:attachment withFormatName:self.attachmentFormatName];

    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger) section {
    return self.observation.attachments.count + self.observation.transientAttachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

- (Attachment *) attachmentAtIndex:(NSUInteger) index {
    NSMutableArray *attachments = [[self.observation.attachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]] mutableCopy];
    [attachments addObjectsFromArray:self.observation.transientAttachments];
    
    return [attachments objectAtIndex:index];
}

@end
