//
//  Attachment+helper.h
//  mage-ios-sdk
//
//

#import "Attachment.h"

@interface Attachment (helper)

+ (Attachment *) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context;

- (id) populateFromJson: (NSDictionary *) json;

- (NSURL *) sourceURL;

@end
