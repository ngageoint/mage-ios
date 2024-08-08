//
//  AttachmentSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Attachment;

@protocol AttachmentSelectionDelegate

@required

- (void) selectedAttachment:(NSURL *) attachmentUri;
- (void) selectedUnsentAttachment: (NSDictionary *) unsentAttachment;
- (void) selectedNotCachedAttachment: (NSURL *) attachmentUri completionHandler: (void(^)(BOOL))handler;

@optional
- (void) attachmentFabTapped:(NSURL *) attachmentUri completionHandler: (void(^)(BOOL))handler;
- (void) attachmentFabTappedField:(NSDictionary *) field completionHandler: (void(^)(BOOL))handler;

@end
