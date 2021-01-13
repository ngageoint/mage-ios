//
//  AttributionsViewController.m
//  MAGE
//
//  Created by William Newman on 2/8/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AttributionsViewController.h"
#import "AttributionTableViewCell.h"

@interface AttributionsViewController ()
@property (weak, nonatomic) NSArray *attributions;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation AttributionsViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>)containerScheme {
    self = [super initWithStyle:UITableViewStylePlain];
    self.scheme = containerScheme;
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    [self.tableView reloadData];
}

-(void) viewDidLoad {
    [super viewDidLoad];
        
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120.0;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"AttributionCell" bundle:nil] forCellReuseIdentifier:@"attributionCell"];
}

- (NSArray *) attributions {
        
    if (_attributions == nil) {
        _attributions = [NSArray arrayWithObjects:
        @{
           @"title": @"GeoPackage",
           @"copyright": @"Copyright (c) 2015 BIT Systems",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/ngageoint/geopackage-ios/master/LICENSE" forText:@"MIT license"]
         },
         @{
           @"title": @"MagicalRecord",
           @"copyright": @"Copyright (c) 2010-2015, Magical Panda Software, LLC",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/magicalpanda/MagicalRecord/master/LICENSE" forText:@"MIT license"]
          },
         @{
           @"title": @"AFNetworking",
           @"copyright": @"Copyright (c) 2011–2016 Alamofire Software Foundation (http://alamofire.org/)",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/AFNetworking/AFNetworking/master/LICENSE" forText:@"MIT license"]
          },
         @{
           @"title": @"DateTools",
           @"copyright": @"Copyright (c) 2014 Matthew York",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/MatthewYork/DateTools/master/LICENSE" forText:@"MIT license"]
          },
         @{
           @"title": @"Kngfisher",
           @"copyright": @"Copyright (c) 2019 Wei Wang",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/onevcat/Kingfisher/master/LICENSE" forText:@"MIT license"]
         },
         @{
           @"title": @"Objective-zip",
           @"copyright": @"Copyright (c) 2009-2012, Flying Dolphin Studio",
           @"text": [self string:@"This product includes software licensed under the BSD license." withLink:@"https://raw.githubusercontent.com/gianlucabertani/Objective-Zip/master/LICENSE.md" forText:@"BSD license"]
          },
         @{
           @"title": @"HexColors",
           @"copyright": @"Copyright (c) 2012 Marius Landwehr marius.landwehr@gmail.com",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/mRs-/HexColors/master/LICENCE" forText:@"MIT license"]
          },
         @{
           @"title": @"UIImage-Categories",
           @"copyright": @"Copyright (c) 2013 Marc Charbonneau",
           @"text": [self string:@"This product includes software licensed under the MIT license." withLink:@"https://raw.githubusercontent.com/jimjeffers/UIImage-Categories/master/LICENSE" forText:@"MIT license"]
           },
         @{
           @"title": @"libPhoneNumber for iOS",
           @"copyright": @"",
           @"text": [self string:@"This product includes software licensed under the Apache License 2.0." withLink:@"https://raw.githubusercontent.com/iziz/libPhoneNumber-iOS/master/LICENSE" forText:@"Apache License 2.0"]
           },
         @{
           @"title": @"SkyFloatingLabelTextField",
           @"copyright": @"2016 Skyscanner Ltd",
           @"text": [self string:@"This product includes software licensed under the Apache License 2.0." withLink:@"https://raw.githubusercontent.com/Skyscanner/SkyFloatingLabelTextField/master/LICENSE" forText:@"Apache License 2.0"]
           },
                         
         nil];
    }
    
    return _attributions;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.attributions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AttributionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"attributionCell"];
    
    NSDictionary *attribution = [self.attributions objectAtIndex:[indexPath row]];
    
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    
    cell.attribution.text = [attribution objectForKey:@"title"];
    cell.copyright.text = [attribution objectForKey:@"copyright"];
    cell.text.attributedText = [attribution objectForKey:@"text"];
    
    cell.attribution.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.87];
    cell.copyright.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.6];
    cell.text.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.6];
    
    return cell;
}

- (NSAttributedString *) string:(NSString *) string withLink:(NSString *) link forText:(NSString *) text {
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.6] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute: NSLinkAttributeName value:link range: [attributedString.mutableString rangeOfString:text options:NSCaseInsensitiveSearch]];
    
    return attributedString;
}

@end
