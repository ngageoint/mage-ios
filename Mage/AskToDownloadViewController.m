//
//  AskToDownloadViewController.m
//  MAGE
//
//  Created by Daniel Barela on 3/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AskToDownloadViewController.h"

@interface AskToDownloadViewController ()

@property (weak, nonatomic) IBOutlet UILabel *attachmentSizeLabel;
@property (weak, nonatomic) Attachment *attachment;
@property (strong, nonatomic) id<AskToDownloadDelegate> delegate;

@end

@implementation AskToDownloadViewController

- (instancetype) initWithAttachment: (Attachment *) attachment andDelegate: (id<AskToDownloadDelegate>) delegate {
    self = [super initWithNibName:@"AskToDownload" bundle:nil];
    if (self != nil) {
        _attachment = attachment;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.attachmentSizeLabel.text = [NSString stringWithFormat:@"Attachment size is %@", self.attachment.size];
}

- (IBAction)downloadAttachment:(id)sender {
    [self.delegate downloadAttachment];
}

@end
