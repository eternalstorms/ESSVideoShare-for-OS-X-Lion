//
//  ESSVimeo.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 28.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"
#import "ESSVimeoWindowController.h"

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSVimeo;

#define VIMEO_API_CALL_URL @"http://vimeo.com/api/rest/v2/"

#define VIMEO_OAUTH_REQUEST_TOKEN_URL @"http://vimeo.com/oauth/request_token"
#define VIMEO_OAUTH_AUTH_URL @"http://vimeo.com/oauth/authorize"
#define VIMEO_OAUTH_ACCESS_TOKEN_URL @"http://secure.vimeo.com/oauth/access_token"

@protocol ESSVimeoDelegate <NSObject>

@required
- (NSWindow *)ESSVimeoNeedsWindowToAttachWindowTo:(ESSVimeo *)uploader;
- (void)ESSVimeoFinished:(ESSVimeo *)uploader;

@end

@interface ESSVimeo : NSObject <ESSVimeoWindowDelegate>

@property (assign) id delegate;
@property (retain) ESSVimeoWindowController *_winCtr;
@property (assign) BOOL plusOnly;
@property (retain) OAToken *_requestToken;
@property (retain) OAToken *_authToken;
@property (retain) OAConsumer *_oaconsumer;
@property (retain) OAHMAC_SHA1SignatureProvider *_sigProv;
@property (assign) NSUInteger _byteSizeOfVideo;
@property (retain) NSURLConnection *_uploader;
@property (retain) NSString *_uploadTicketID;
@property (retain) NSString *_description;
@property (retain) NSString *_title;
@property (assign) BOOL _isPrivate;
@property (retain) NSString *_tags;

- (id)initWithAPIKey:(NSString *)key
			  secret:(NSString *)secret
 canUploadToPlusOnly:(BOOL)canUploadToPlusOnly //if the key you have has plus-upload-access only, pass canUploadToPlusOnly -> YES
			delegate:(id)del;

- (void)uploadVideoAtURL:(NSURL *)url;

//private

- (void)_uploadVideoAtURL:(NSURL *)url
					title:(NSString *)vidTitle
			  description:(NSString *)descr
					 tags:(NSString *)vidTags
			  makePrivate:(BOOL)makePrivate;

#pragma mark -
#pragma mark Authorization

- (void)_startAuthorization; //√ callback addition in format oauthcallback?

- (void)_deauthorize;

#pragma mark -
#pragma mark Upload

- (void)_getQuotaJustConfirmingLogin:(BOOL)confirming;

#pragma mark -
#pragma mark Private Methods

- (NSString *)_executeMethod:(NSString *)method
			  withParameters:(NSDictionary *)parameters;

@end
