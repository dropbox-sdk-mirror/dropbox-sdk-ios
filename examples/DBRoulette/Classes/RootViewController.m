//
//  RootViewController.m
//  DBRoulette
//
//  Created by Brian Smith on 6/29/10.
//  Copyright Dropbox, Inc. 2010. All rights reserved.
//

#import "RootViewController.h"
#import "DropboxSDK.h"


@interface RootViewController () <DBLoginControllerDelegate>

- (void)updateButtons;

@end


@implementation RootViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.title = @"Link Account";
    }
    return self;
}

- (void)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
        DBLoginController* controller = [[DBLoginController new] autorelease];
        controller.delegate = self;
        [controller presentFromController:self];
    } else {
        [[DBSession sharedSession] unlink];
        [[[[UIAlertView alloc] 
           initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked" 
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        [self updateButtons];
    }
}

- (IBAction)didPressPhotos {
    [self.navigationController pushViewController:photoViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButtons];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
            initWithTitle:@"Photos" style:UIBarButtonItemStylePlain 
            target:self action:@selector(didPressPhotos)] autorelease];
    self.title = @"Link Account";
}

- (void)viewDidUnload {
    [linkButton release];
    linkButton = nil;
}


- (void)dealloc {
    [linkButton release];
    [photoViewController release];
    [super dealloc];
}


#pragma mark DBLoginControllerDelegate methods

- (void)loginControllerDidLogin:(DBLoginController*)controller {
    [self updateButtons];
    [self.navigationController pushViewController:photoViewController animated:YES];
}

- (void)loginControllerDidCancel:(DBLoginController*)controller {

}


#pragma mark private methods

@synthesize linkButton;
@synthesize photoViewController;

- (void)updateButtons {
    NSString* title = [[DBSession sharedSession] isLinked] ? @"Unlink Dropbox" : @"Link Dropbox";
    [linkButton setTitle:title forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItem.enabled = [[DBSession sharedSession] isLinked];
}

@end

