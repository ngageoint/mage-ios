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
@property (weak, nonatomic) NSString *attachmentFormatName;
@property (nonatomic, strong) IBOutlet id<AttachmentSelectionDelegate> attachmentSelectionDelegate;
@property (nonatomic, weak) id<MDCContainerScheming> containerScheme;

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;
@end
