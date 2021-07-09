//
//  AttachmentCollectionDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "Observation.h"
#import <MaterialComponents/MDCContainerScheme.h>
#import "AttachmentSelectionDelegate.h"

@interface AttachmentCollectionDataStore : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) NSSet<Attachment *> *attachments;
@property (strong, nonatomic) NSArray<NSDictionary *> *unsentAttachments;
@property (weak, nonatomic) NSString *attachmentFormatName;
@property (nonatomic, weak) IBOutlet id<AttachmentSelectionDelegate> attachmentSelectionDelegate;
@property (nonatomic, weak) id<MDCContainerScheming> containerScheme;

- (id) initWithButtonImage: (NSString *) imageName useErrorColor: (BOOL) useErrorColor;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;
@end
