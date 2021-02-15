//
//  AttachmentCollectionDataStore.m
//  MAGE
//
//

#import "AttachmentCollectionDataStore.h"
#import <MaterialComponents/MDCFloatingButton.h>
#import "MAGE-Swift.h"

@interface AttachmentCollectionDataStore ()
@property (strong, nonatomic) NSString *imageName;
@property (nonatomic) BOOL useErrorColor;
@end

@implementation AttachmentCollectionDataStore

- (id) initWithButtonImage: (NSString *) imageName useErrorColor: (BOOL) useErrorColor {
    if ((self = [super init])) {
        self.imageName = imageName;
        self.useErrorColor = useErrorColor;
    }
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    self.containerScheme = containerScheme;
    [self.attachmentCollection reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [self.attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
    MDCFloatingButton *button = nil;
    if (self.imageName != nil) {
        button = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
        [button setImage:[UIImage imageNamed:self.imageName] forState:UIControlStateNormal];
        if (self.useErrorColor) {
            [button applySecondaryThemeWithScheme:[MAGEErrorScheme scheme]];
        } else {
            [button applySecondaryThemeWithScheme:self.containerScheme];
        }
        [button addTarget:self action:@selector(attachmentFabTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = indexPath.row;
    }
    [cell setImageWithAttachment:attachment formatName:self.attachmentFormatName button: button scheme: self.containerScheme];

    return cell;
}

- (void) attachmentFabTapped: (MDCFloatingButton *) sender {
    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:sender.tag];
        [self.attachmentSelectionDelegate attachmentFabTapped:attachment completionHandler:^(BOOL deleted) {
            [self.attachmentCollection reloadData];
        }];
    }
}

- (NSSet<Attachment *> *) filteredAttachments {
    return [self.attachments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"markedForDeletion != true"]];
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger) section {
    return [self filteredAttachments].count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

- (Attachment *) attachmentAtIndex:(NSUInteger) index {
    NSMutableArray *attachments = [[[self filteredAttachments] sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"remoteId" ascending:NO]
    ]] mutableCopy];
    
    return [attachments objectAtIndex:index];
}

@end
