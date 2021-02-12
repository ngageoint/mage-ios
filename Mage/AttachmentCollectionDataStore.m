//
//  AttachmentCollectionDataStore.m
//  MAGE
//
//

#import "AttachmentCollectionDataStore.h"
#import "MAGE-Swift.h"

@implementation AttachmentCollectionDataStore

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    self.containerScheme = containerScheme;
    [self.attachmentCollection reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [self.attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
    [cell setImageWithAttachment:attachment formatName:self.attachmentFormatName scheme: self.containerScheme];

    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger) section {
    return self.attachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

- (Attachment *) attachmentAtIndex:(NSUInteger) index {
    NSMutableArray *attachments = [[self.attachments sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"remoteId" ascending:NO]
    ]] mutableCopy];
    
    return [attachments objectAtIndex:index];
}

@end
