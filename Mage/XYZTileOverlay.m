//
//  XYZTileOverlay.m
//  MAGE
//
//  Created by Dan Barela on 9/24/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "XYZTileOverlay.h"

@interface XYZTileOverlay ()
@property (nonatomic, strong) NSString *url;
@end


@implementation XYZTileOverlay

- (id) initWithURLTemplate: (NSString *) url {
    self.url = url;
    return [super initWithURLTemplate:self.url];
}

- (NSURL *) URLForTilePath:(MKTileOverlayPath) path {
    NSString *currentUrl = [self.url stringByReplacingOccurrencesOfString:@"{s}" withString:[[[self class] servers] objectAtIndex:arc4random() % [[self class] servers].count]];
    currentUrl = [currentUrl stringByReplacingOccurrencesOfString:@"{x}" withString:[NSString stringWithFormat:@"%li", path.x]];
    currentUrl = [currentUrl stringByReplacingOccurrencesOfString:@"{y}" withString:[NSString stringWithFormat:@"%li", path.y]];
    currentUrl = [currentUrl stringByReplacingOccurrencesOfString:@"{z}" withString:[NSString stringWithFormat:@"%li", path.z]];

    return [NSURL URLWithString: currentUrl];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData * _Nullable, NSError * _Nullable))result {
    NSURL *url1 = [self URLForTilePath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url1];
    request.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        result(data, error);
    }] resume];
}

+ (NSArray *)servers
{
    static NSArray *_servers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _servers = @[@"a",
                    @"b",
                    @"c",
                    @"d"];
    });
    return _servers;
}

@end
