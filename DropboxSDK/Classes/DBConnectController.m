//
//  DBConnectController.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/4/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

#import "DBConnectController.h"

#import <QuartzCore/QuartzCore.h>

#import "DBRequest.h"
#import "DBSession+iOS.h"


extern id<DBNetworkRequestDelegate> dbNetworkRequestDelegate;

@interface DBConnectController () <UIWebViewDelegate, UIAlertViewDelegate>

- (void)loadRequest;
- (void)dismiss;

@property (nonatomic, assign) BOOL hasLoaded;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) UIWebView *webView;

@end


@implementation DBConnectController

@synthesize hasLoaded;
@synthesize url;
@synthesize webView;

- (id)initWithUrl:(NSURL *)connectUrl {
    if ((self = [super init])) {
        self.url = connectUrl;

        self.title = @"Dropbox";
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)dealloc {
    [url release];
    if (webView.isLoading) {
        [dbNetworkRequestDelegate networkRequestStopped];
        [webView stopLoading];
        webView.delegate = nil;
    }
    [webView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:241.0/255 green:249.0/255 blue:255.0/255 alpha:1.0];

    UIActivityIndicatorView *activityIndicator =
        [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CGRect frame = self.view.bounds;
    frame.origin.y = -20;
    activityIndicator.frame = frame;
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    self.webView.hidden = YES;
    [self.view addSubview:self.webView];

    [self loadRequest];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [webView release];
    webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ||
            interfaceOrientation == UIInterfaceOrientationPortrait;
}


#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [dbNetworkRequestDelegate networkRequestStarted];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [aWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout = \"none\";"]; // Disable touch-and-hold action sheet
    [aWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect = \"none\";"]; // Disable text selection
    webView.frame = self.view.bounds;

    CATransition* transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionFade;
    [self.view.layer addAnimation:transition forKey:nil];

    webView.hidden = NO;

    hasLoaded = YES;
    [dbNetworkRequestDelegate networkRequestStopped];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // ignore "Fame Load Interrupted" errors
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) return;

    NSString *title = @"";
    NSString *message = @"";

    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
        title = NSLocalizedString(@"No internet connection", @"");
        message = NSLocalizedString(@"Try again once you have an internet connection.", @"");
    } else if ([error.domain isEqual:NSURLErrorDomain] &&
               (error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotConnectToHost)) {
        title = NSLocalizedString(@"Internet connection lost", @"");
        message    = NSLocalizedString(@"Please try again.", @"");
    } else {
        title = NSLocalizedString(@"Unknown Error Occurred", @"");
        message = NSLocalizedString(@"There was an error loading Dropbox. Please try again.", @"");
    }

    if (self.hasLoaded) {
        // If it has loaded, it means it's a form submit, so users can cancel/retry on their own
        NSString *okStr = NSLocalizedString(@"OK", nil);

        [[[[UIAlertView alloc]
           initWithTitle:title message:message delegate:nil cancelButtonTitle:okStr otherButtonTitles:nil]
          autorelease]
         show];
    } else {
        // if the page hasn't loaded, this alert gives the user a way to retry
        NSString *retryStr = NSLocalizedString(@"Retry", @"Retry loading a page that has failed to load");

        [[[[UIAlertView alloc]
           initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:retryStr, nil]
          autorelease]
         show];
    }

    [dbNetworkRequestDelegate networkRequestStopped];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    NSString *appScheme = [[DBSession sharedSession] appScheme];
    if ([[[request URL] scheme] isEqual:appScheme]) {

        UIApplication *app = [UIApplication sharedApplication];
        id<UIApplicationDelegate> delegate = app.delegate;

        if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
            [delegate application:app openURL:[request URL] sourceApplication:@"com.getdropbox.Dropbox" annotation:nil];
        } else if ([delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
            [delegate application:app handleOpenURL:[request URL]];
        }
        [self dismiss];
        return NO;
    } else if (![[[request URL] pathComponents] isEqual:[self.url pathComponents]]) {
        DBConnectController *childController = [[[DBConnectController alloc] initWithUrl:[request URL]] autorelease];

        NSDictionary *queryParams = [DBSession parseURLParams:[[request URL] query]];
        NSString *title = [queryParams objectForKey:@"embed_title"];
        if (title) {
            childController.title = title;
        } else {
            childController.title = self.title;
        }
        childController.navigationItem.rightBarButtonItem = nil;

        [self.navigationController pushViewController:childController animated:YES];
        return NO;
    }
    return YES;
}


#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self loadRequest];
    } else {
        if ([self.navigationController.viewControllers count] > 1) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismiss];
        }
    }
}


#pragma mark private methods

- (void)loadRequest {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20];
    [self.webView loadRequest:urlRequest];
}

- (void)dismiss {
    if ([webView isLoading]) {
        [dbNetworkRequestDelegate networkRequestStopped];
        [webView stopLoading];
        webView.delegate = nil;
    }
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

@end
