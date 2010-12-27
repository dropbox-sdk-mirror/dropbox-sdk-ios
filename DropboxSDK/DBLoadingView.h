//
//  DBLoadingView.h
//  DropboxSDK
//
//  Created by Brian Smith on 6/30/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DBLoadingView : UIView {
    UILabel* titleLabel;
    UIActivityIndicatorView* activityIndicator;
}

- (id)initWithTitle:(NSString*)title;

- (void)show;
- (void)dismiss;

//@property (nonatomic, retain) NSString* title;

@end
