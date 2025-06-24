//
//  AppDefaultTypographyScheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppDefaultTypographyScheme.h"

@implementation AppDefaultTypographyScheme

- (UIFont *)headline1Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
}

- (UIFont *)headline2Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
}

- (UIFont *)headline3Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
}

- (UIFont *)headline4Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
}

- (UIFont *)headline5Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

- (UIFont *)headline6Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

- (UIFont *)subtitle1Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

- (UIFont *)subtitle2Font {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}

- (UIFont *)captionFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
}

- (UIFont *)headlineFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

- (UIFont *)bodyFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (UIFont *)buttonFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
}

@end
