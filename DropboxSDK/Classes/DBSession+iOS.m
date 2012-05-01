//
//  DBSession+iOS.m
//  DropboxSDK
//
//  Created by Brian Smith on 3/7/12.
//  Copyright (c) 2012 Dropbox. All rights reserved.
//

#import "DBSession+iOS.h"

#import <CommonCrypto/CommonDigest.h>

#import "DBLog.h"


static NSString *kDBProtocolDropbox = @"dbapi-1";

@implementation DBSession (iOS)

- (NSString *)appScheme {
    NSString *consumerKey = [baseCredentials objectForKey:kMPOAuthCredentialConsumerKey];
    return [NSString stringWithFormat:@"db-%@", consumerKey];
}

- (BOOL)appConformsToScheme {
    NSString *appScheme = [self appScheme];

    NSDictionary *loadedPlist = [[NSBundle mainBundle] infoDictionary];

    NSArray *urlTypes = [loadedPlist objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *urlType in urlTypes) {
        NSArray *schemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        for (NSString *scheme in schemes) {
            if ([scheme isEqual:appScheme]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)linkUserId:(NSString *)userId {
    if (![self appConformsToScheme]) {
        DBLogError(@"DropboxSDK: unable to link; app isn't registered for correct URL scheme (%@)", [self appScheme]);
        return;
    }

    extern NSString *kDBDropboxUnknownUserId;
    NSString *userIdStr = @"";
    if (userId && ![userId isEqual:kDBDropboxUnknownUserId]) {
        userIdStr = [NSString stringWithFormat:@"&u=%@", userId];
    }

    NSString *consumerKey = [baseCredentials objectForKey:kMPOAuthCredentialConsumerKey];

    NSData *consumerSecret =
    [[baseCredentials objectForKey:kMPOAuthCredentialConsumerSecret] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(consumerSecret.bytes, [consumerSecret length], md);
    NSUInteger sha_32 = htonl(((NSUInteger *)md)[CC_SHA1_DIGEST_LENGTH/sizeof(NSUInteger) - 1]);
    NSString *secret = [NSString stringWithFormat:@"%x", sha_32];

    NSString *urlStr = nil;

    NSURL *dbURL =
    [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/connect", kDBProtocolDropbox, kDBDropboxAPIVersion]];
    if ([[UIApplication sharedApplication] canOpenURL:dbURL]) {
        urlStr = [NSString stringWithFormat:@"%@?k=%@&s=%@%@", dbURL, consumerKey, secret, userIdStr];
    } else {
        urlStr = [NSString stringWithFormat:@"%@://%@/%@/connect?k=%@&s=%@%@",
                  kDBProtocolHTTPS, kDBDropboxWebHost, kDBDropboxAPIVersion, consumerKey, secret, userIdStr];
    }

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
}

- (void)link {
    [self linkUserId:nil];
}

/* A private function for parsing URL parameters. */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    NSString *expected = [NSString stringWithFormat:@"%@://%@/", [self appScheme], kDBDropboxAPIVersion];
    if (![[url absoluteString] hasPrefix:expected]) {
        return NO;
    }

    NSArray *components = [[url path] pathComponents];
    NSString *methodName = [components count] > 1 ? [components objectAtIndex:1] : nil;

    if ([methodName isEqual:@"connect"]) {
        NSDictionary *params = [self parseURLParams:[url query]];
        NSString *token = [params objectForKey:@"oauth_token"];
        NSString *secret = [params objectForKey:@"oauth_token_secret"];
        NSString *userId = [params objectForKey:@"uid"];
        [self updateAccessToken:token accessTokenSecret:secret forUserId:userId];
    } else if ([methodName isEqual:@"cancelled"]) {
        DBLogInfo(@"DropboxSDK: user canceled Dropbox link");
    }

    return YES;
}

@end
