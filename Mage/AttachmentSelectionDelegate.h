//
//  AttachmentSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Attachment.h"

@protocol AttachmentSelectionDelegate

@required

- (void) selectedAttachment:(Attachment *) attachment;
- (void) selectedUnsentAttachment: (NSDictionary *) unsentAttachment;

@optional
- (void) attachmentFabTapped:(Attachment *) attachment completionHandler: (void(^)(BOOL))handler;
- (void) attachmentFabTappedField:(NSDictionary *) field completionHandler: (void(^)(BOOL))handler;

@end
