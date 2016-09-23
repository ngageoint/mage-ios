//
//  ObservationViewController_iPhone.m
//  MAGE
//
//

#import "ObservationViewController_iPhone.h"

@implementation ObservationViewController_iPhone

- (NSMutableArray *) getHeaderSection {
    return [[NSMutableArray alloc] initWithObjects:@"header", @"map", @"directions", nil];
}

- (NSMutableArray *) getAttachmentsSection {
    NSMutableArray *attachmentsSection = [[NSMutableArray alloc] init];
    
    if (self.observation.attachments.count != 0) {
        [attachmentsSection addObject:@"attachments"];
    }
    
    return attachmentsSection;
}

@end
