//
//  DBLinkButton.m
//  DBNotes
//
//  Created by Brian Smith on 6/29/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBLinkButton.h"
#import "DBLoginController.h"
#import "DBSession.h"


@interface DBLinkButton () <DBLoginControllerDelegate>

- (void)configureView;

@end


@implementation DBLinkButton


- (id)initWithFrame:(CGRect)frame controller:(UIViewController*)theController {
    if ((self = [super initWithFrame:frame])) {
        controller = theController;
        [self addTarget:self action:@selector(didPressSelf) 
            forControlEvents:UIControlEventTouchUpInside];
        [self configureView];
    }
    return self;
}

- (void)configureView {
    if ([[DBSession sharedSession] isLinked]) {
        self.titleLabel.text = @"Unlink";
    } else {
        self.titleLabel.text = @"Link";
    }
}

- (void)dealloc {
    loginController.delegate = nil;
    [loginController release];
    [super dealloc];
}

- (void)didPressSelf {
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlink];
        [[[[UIAlertView alloc]
           initWithTitle:@"Dropbox Unlinked" 
           message:@"You have successfully unlinked this app from Dropbox" 
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
         
         [self configureView];
    } else {
        loginController = [DBLoginController new];
        loginController.delegate = self;
        [loginController presentFromController:controller];
    }
}


#pragma mark DBLoginControllerDelegate methods

- (void)loginControllerDidLogin:(DBLoginController*)controller {
    [self configureView];
    [loginController release];
    loginController = nil;
}

- (void)loginControllerDidCancel:(DBLoginController*)controller {
    [loginController release];
    loginController = nil;
}

@end
