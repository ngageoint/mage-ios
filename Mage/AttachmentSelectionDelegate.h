//
//  AttachmentSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Attachment.h"

@protocol AttachmentSelectionDelegate <NSObject>

@required

- (void) selectedAttachment:(Attachment *) attachment;

@end