//
//  DBLinkButton.h
//  DBNotes
//
//  Created by Brian Smith on 6/29/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DBLoginController;

@interface DBLinkButton : UIButton {
    UIViewController* controller;
    DBLoginController* loginController;
}

- (id)initWithFrame:(CGRect)frame controller:(UIViewController*)controller;

@end
