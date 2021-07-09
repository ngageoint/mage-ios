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
    
    Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
    if (attachment != nil) {
        [cell setImageWithAttachment:attachment formatName:self.attachmentFormatName button: button scheme: self.containerScheme];
    } else {
        NSDictionary *unsentAttachment = [self unsentAttachmentAtIndex:[indexPath row]];
        [cell setImageWithNewAttachment:unsentAttachment button:button scheme:self.containerScheme];
    }

    return cell;
}

- (void) attachmentFabTapped: (MDCFloatingButton *) sender {
    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:sender.tag];
        if (attachment != nil) {
            [self.attachmentSelectionDelegate attachmentFabTapped:attachment completionHandler:^(BOOL deleted) {
                [self.attachmentCollection reloadData];
            }];
        } else {
            NSDictionary *unsentAttachment = [self unsentAttachmentAtIndex:sender.tag];
            [self.attachmentSelectionDelegate attachmentFabTappedField:unsentAttachment completionHandler:^(BOOL deleted) {
                [self.attachmentCollection reloadData];
            }];
        }
    }
}

- (NSSet<Attachment *> *) filteredAttachments {
    return [self.attachments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"markedForDeletion != true"]];
}

- (NSArray<NSDictionary *> *) filteredUnsentAttachments {
    return [self.unsentAttachments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"markedForDeletion != true"]];
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger) section {
    return [self filteredAttachments].count + [self filteredUnsentAttachments].count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.attachmentSelectionDelegate) {
        Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
        [self.attachmentSelectionDelegate selectedAttachment:attachment];
    }
}

- (NSDictionary *) unsentAttachmentAtIndex:(NSUInteger) index {
    return [[self filteredUnsentAttachments] objectAtIndex:(index - [[self filteredAttachments] count])];
}

- (Attachment *) attachmentAtIndex:(NSUInteger) index {
    NSMutableArray *attachments = [[[self filteredAttachments] sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"remoteId" ascending:NO]
    ]] mutableCopy];
    
    @try {
        return [attachments objectAtIndex:index];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

@end
