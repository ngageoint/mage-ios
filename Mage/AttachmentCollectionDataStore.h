//
//  AttachmentCollectionDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <Observation+helper.h>
#import "AttachmentSelectionDelegate.h"

@interface AttachmentCollectionDataStore : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) Observation *observation;
@property (nonatomic, strong) IBOutlet id<AttachmentSelectionDelegate> attachmentSelectionDelegate;

@end
