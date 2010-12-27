//
//  DBLoadingView.m
//  DropboxSDK
//
//  Created by Brian Smith on 6/30/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBLoadingView.h"


#define kPadding 10


@interface DBLoadingView ()

- (CGRect)beveledBoxFrame;

@end


@implementation DBLoadingView


- (id)initWithTitle:(NSString*)theTitle {
    CGRect frame = [[UIApplication sharedApplication] keyWindow].frame;
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        CGRect contentFrame = [self beveledBoxFrame];

        activityIndicator = 
            [[UIActivityIndicatorView alloc] 
             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.center = CGPointMake(
            floor(contentFrame.origin.x + contentFrame.size.width/2), 
            floor(contentFrame.origin.y + contentFrame.size.height/2) - kPadding);
        [self addSubview:activityIndicator];

        titleLabel = [UILabel new];
        titleLabel.text = theTitle;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        CGFloat titleLeading = titleLabel.font.leading;
        CGRect titleFrame = CGRectMake(
                contentFrame.origin.x + kPadding, 
                CGRectGetMaxY(contentFrame) - 2*kPadding - titleLeading, 
                contentFrame.size.width - 2*kPadding, titleLeading);
        titleLabel.frame = titleFrame;
        [self addSubview:titleLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect contentFrame = [self beveledBoxFrame];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat fillColor[] = { 0, 0, 0, 128.0/255 };
    CGContextSetFillColor(context, fillColor);
    CGFloat radius = 6;
    CGContextMoveToPoint(context, contentFrame.origin.x + radius, contentFrame.origin.y);
    CGContextAddArcToPoint(context, 
            CGRectGetMaxX(contentFrame), contentFrame.origin.y, 
            CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
            CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), 
            contentFrame.origin.x, CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
            contentFrame.origin.x, CGRectGetMaxY(contentFrame), 
            contentFrame.origin.x, contentFrame.origin.y, radius);
    CGContextAddArcToPoint(context, 
            contentFrame.origin.x, contentFrame.origin.y, 
            CGRectGetMaxX(contentFrame), contentFrame.origin.y, radius);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)dealloc {
    [super dealloc];
}

- (void)show {
    [activityIndicator startAnimating];
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:self];
}

- (void)dismiss {
    [activityIndicator stopAnimating];
    [self removeFromSuperview];
}

- (CGRect)beveledBoxFrame {
    CGSize contentSize = self.bounds.size;
    CGSize boxSize = CGSizeMake(160, 160);
    return CGRectMake(
        floor(contentSize.width/2 - boxSize.width/2),
        floor(contentSize.height/2 - boxSize.height/2) + 18,
        boxSize.width, boxSize.height);
}

@end
