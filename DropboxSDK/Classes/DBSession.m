//
//  DBSession.m
//  DropboxSDK
//
//  Created by Brian Smith on 4/8/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBSession.h"

#import "DBLog.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPOAuthSignatureParameter.h"

NSString *kDBSDKVersion = @"1.2"; // TODO: parameterize from build system

NSString *kDBDropboxAPIHost = @"api.dropbox.com";
NSString *kDBDropboxAPIContentHost = @"api-content.dropbox.com";
NSString *kDBDropboxWebHost = @"www.dropbox.com";
NSString *kDBDropboxAPIVersion = @"1";

NSString *kDBRootDropbox = @"dropbox";
NSString *kDBRootAppFolder = @"sandbox";

NSString *kDBProtocolHTTPS = @"https";

NSString *kDBDropboxUnknownUserId = @"unknown";

static DBSession *_sharedSession = nil;
static NSString *kDBDropboxSavedCredentialsOld = @"kDBDropboxSavedCredentialsKey";
static NSString *kDBDropboxSavedCredentials = @"kDBDropboxSavedCredentials";
static NSString *kDBDropboxUserCredentials = @"kDBDropboxUserCredentials";
static NSString *kDBDropboxUserId = @"kDBDropboxUserId";


@interface DBSession ()

- (NSDictionary*)savedCredentials;
- (void)saveCredentials;
- (void)clearSavedCredentials;
- (void)setAccessToken:(NSString *)token accessTokenSecret:(NSString *)secret forUserId:(NSString *)userId;

@end


@implementation DBSession

+ (DBSession *)sharedSession {
    return _sharedSession;
}

+ (void)setSharedSession:(DBSession *)session {
    if (session == _sharedSession) return;
    [_sharedSession release];
    _sharedSession = [session retain];
}

- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret root:(NSString *)theRoot {
    if ((self = [super init])) {
        
        baseCredentials = 
            [[NSDictionary alloc] initWithObjectsAndKeys:
                key, kMPOAuthCredentialConsumerKey,
                secret, kMPOAuthCredentialConsumerSecret, 
                kMPOAuthSignatureMethodPlaintext, kMPOAuthSignatureMethod, nil];
                
        credentialStores = [NSMutableDictionary new];
        
        NSDictionary *oldSavedCredentials =
            [[NSUserDefaults standardUserDefaults] objectForKey:kDBDropboxSavedCredentialsOld];
        if (oldSavedCredentials) {
            if ([key isEqual:[oldSavedCredentials objectForKey:kMPOAuthCredentialConsumerKey]]) {
                NSString *token = [oldSavedCredentials objectForKey:kMPOAuthCredentialAccessToken];
                NSString *secret = [oldSavedCredentials objectForKey:kMPOAuthCredentialAccessTokenSecret];
                [self setAccessToken:token accessTokenSecret:secret forUserId:kDBDropboxUnknownUserId];
            }
        }
        
        NSDictionary *savedCredentials = [self savedCredentials];
        if (savedCredentials != nil) {
            if ([key isEqualToString:[savedCredentials objectForKey:kMPOAuthCredentialConsumerKey]]) {
            
                NSArray *allUserCredentials = [savedCredentials objectForKey:kDBDropboxUserCredentials];
                for (NSDictionary *userCredentials in allUserCredentials) {
                    NSString *userId = [userCredentials objectForKey:kDBDropboxUserId];
                    NSString *token = [userCredentials objectForKey:kMPOAuthCredentialAccessToken];
                    NSString *secret = [userCredentials objectForKey:kMPOAuthCredentialAccessTokenSecret];
                    [self setAccessToken:token accessTokenSecret:secret forUserId:userId];
                }
            } else {
                [self clearSavedCredentials];
            }
        }
        
        root = [theRoot retain];
    }
    return self;
}

- (void)dealloc {
    [baseCredentials release];
    [credentialStores release];
    [anonymousStore release];
    [root release];
    [super dealloc];
}

@synthesize root;
@synthesize delegate;

- (void)updateAccessToken:(NSString *)token accessTokenSecret:(NSString *)secret forUserId:(NSString *)userId {
    [self setAccessToken:token accessTokenSecret:secret forUserId:userId];
    [self saveCredentials];
}

- (void)setAccessToken:(NSString *)token accessTokenSecret:(NSString *)secret forUserId:(NSString *)userId {
    MPOAuthCredentialConcreteStore *credentialStore = [credentialStores objectForKey:userId];
    if (!credentialStore) {
        credentialStore = 
            [[MPOAuthCredentialConcreteStore alloc] initWithCredentials:baseCredentials];
        [credentialStores setObject:credentialStore forKey:userId];
        [credentialStore release];
        
        if (![userId isEqual:kDBDropboxUnknownUserId] && [credentialStores objectForKey:kDBDropboxUnknownUserId]) {
            // If the unknown user is in credential store, replace it with this new entry
            [credentialStores removeObjectForKey:kDBDropboxUnknownUserId];
        }
    }
    credentialStore.accessToken = token;
    credentialStore.accessTokenSecret = secret;
}

- (BOOL)isLinked {
    return [credentialStores count] != 0;
}

- (void)unlinkAll {
    [credentialStores removeAllObjects];
    [self clearSavedCredentials];
}

- (void)unlinkUserId:(NSString *)userId {
    [credentialStores removeObjectForKey:userId];
    [self saveCredentials];
}

- (MPOAuthCredentialConcreteStore *)credentialStoreForUserId:(NSString *)userId {
    if (!userId) {
        if (!anonymousStore) {
            anonymousStore = [[MPOAuthCredentialConcreteStore alloc] initWithCredentials:baseCredentials];
        }
        return anonymousStore;
    }
    return [credentialStores objectForKey:userId];
}

- (NSArray *)userIds {
    return [credentialStores allKeys];
}


#pragma mark private methods

- (NSDictionary *)savedCredentials {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDBDropboxSavedCredentials];
}

- (void)saveCredentials {
    NSMutableDictionary *credentials = [NSMutableDictionary dictionaryWithDictionary:baseCredentials];
    NSMutableArray *allUserCredentials = [NSMutableArray array];
    for (NSString *userId in [credentialStores allKeys]) {
        MPOAuthCredentialConcreteStore *store = [credentialStores objectForKey:userId];
        NSMutableDictionary *userCredentials = [NSMutableDictionary new];
        [userCredentials setObject:userId forKey:kDBDropboxUserId];
        [userCredentials setObject:store.accessToken forKey:kMPOAuthCredentialAccessToken];
        [userCredentials setObject:store.accessTokenSecret forKey:kMPOAuthCredentialAccessTokenSecret];
        [allUserCredentials addObject:userCredentials];
        [userCredentials release];
    }
    [credentials setObject:allUserCredentials forKey:kDBDropboxUserCredentials];
    
    [[NSUserDefaults standardUserDefaults] setObject:credentials forKey:kDBDropboxSavedCredentials];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDBDropboxSavedCredentialsOld];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearSavedCredentials {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDBDropboxSavedCredentials];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
