//
//  ImageViewerViewController.h
//  Mage
//
//  Created by Dan Barela on 8/13/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attachment+FICAttachment.h"

@interface ImageViewerViewController : UIViewController

@property (weak, nonatomic) Attachment *attachment;
@property (weak, nonatomic) NSURL *mediaUrl;
@property (weak, nonatomic) NSString *contentType;

@end
