//
//  TVGradientView.m
//  TVMagic2
//
//  Created by Patrick Quinn-Graham on 09-06-04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TVGradientView.h"

@implementation TVGradientView

- (void)drawRect:(NSRect)dirtyRect {
    
	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
    CGContextRef currentContext = (CGContextRef)[graphicsContext graphicsPort];

	CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 0.9, 0.9, 0.9, 1.0,  // Start color
		0.95, 0.95, 0.95, 1.0 }; // End color
	
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
	
    CGRect currentBounds = NSRectToCGRect([self bounds]);
	
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));
    CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, midCenter, 0);
	
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace); 
}

@end
