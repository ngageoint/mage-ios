//
//  AttachmentCollectionDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "AttachmentSelectionDelegate.h"

@class AttachmentModel;

@interface AttachmentCollectionDataStore : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) NSArray<AttachmentModel *> *attachments;
@property (strong, nonatomic) NSArray<NSDictionary *> *unsentAttachments;
@property (weak, nonatomic) NSString *attachmentFormatName;
@property (nonatomic, weak) IBOutlet id<AttachmentSelectionDelegate> attachmentSelectionDelegate;
@property (nonatomic, weak) id<AppContainerScheming> containerScheme;

- (id) initWithButtonImage: (NSString *) imageName useErrorColor: (BOOL) useErrorColor;
- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;
@end
