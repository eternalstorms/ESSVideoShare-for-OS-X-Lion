//
//  ESSVimeo.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 28.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSVimeo.h"

@implementation ESSVimeo

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@synthesize _requestToken,_authToken,_oaconsumer,_sigProv,delegate,plusOnly,_byteSizeOfVideo,_uploader,_uploadTicketID,_title,_description,_isPrivate,_tags,_winCtr;
#else
@synthesize _requestToken,_authToken,_oaconsumer,_sigProv,delegate,plusOnly,_byteSizeOfVideo,_uploader,_uploadTicketID,_title,_description,_isPrivate,_tags,_viewCtr;
#endif

- (id)initWithAPIKey:(NSString *)key
			  secret:(NSString *)secret
 canUploadToPlusOnly:(BOOL)canUploadToPlusOnly
			delegate:(id)del
{
	if (self = [super init])
	{
		self._oaconsumer = [[[OAConsumer alloc] initWithKey:key secret:secret] autorelease];
		self._sigProv = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		self.delegate = (del ? del:[NSApp delegate]);
#else
		self.delegate = (del ? del:[[UIApplication sharedApplication] delegate]);
#endif
		self.plusOnly = canUploadToPlusOnly;
		
		return self;
	}
	
	return nil;
}

- (void)uploadVideoAtURL:(NSURL *)url
{
	if (url == nil)
		return;
	
	self._byteSizeOfVideo = (NSUInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:url.fileReferenceURL.path error:nil] fileSize];
	self._authToken = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"essvimeo" prefix:@"essvimeovideoupload"] autorelease];
	
	NSURL *testURL = [NSURL URLWithString:@"http://vimeo.com/api/v2/oddysseey/info.xml"];
	NSError *err = nil;
	NSData *dat = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:testURL
																		   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
																	   timeoutInterval:60.0] returningResponse:nil error:&err];
	
	if (dat == nil || err != nil)
	{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		NSWindow *win = [NSApp mainWindow];
		if ([self.delegate respondsToSelector:@selector(ESSVimeoNeedsWindowToAttachWindowTo:)])
			win = [self.delegate ESSVimeoNeedsWindowToAttachWindowTo:self];
		if (win != nil)
		{
			NSBeginAlertSheet(ESSLocalizedString(@"ESSVimeoNoInternetConnection",nil),
							  ESSLocalizedString(@"ESSFlickrOKButton",nil),
							  nil,
							  nil,
							  win, nil, nil, nil, nil,
							  ESSLocalizedString(@"ESSVimeoNoInternetConnectionMsg",nil));
		} else
		{
			NSRunAlertPanel(ESSLocalizedString(@"ESSVimeoNoInternetConnection",nil),
							ESSLocalizedString(@"ESSVimeoNoInternetConnectionMsg",nil),
							ESSLocalizedString(@"ESSFlickrOKButton",nil),
							nil, nil);
		}
#else
		UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoNoInternetConnection",nil)
													 message:ESSLocalizedString(@"ESSVimeoNoInternetConnectionMsg",nil)
													delegate:nil
										   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
										   otherButtonTitles:nil];
		
		[aV show];
		[aV release];
#endif
		
		if ([self.delegate respondsToSelector:@selector(ESSVimeoFinished:)])
			[self.delegate ESSVimeoFinished:self];
		
		return;
	}
	
	dat = nil;
	err = nil;
	testURL = nil;
	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._winCtr = [[[ESSVimeoWindowController alloc] initWithVideoURL:url delegate:self] autorelease];
	[self._winCtr loadWindow];
	
	if (self._authToken == nil) //need auth
		[self._winCtr switchToLoginViewWithAnimation:NO];
	else
		[self _getQuotaJustConfirmingLogin:YES];
	
	NSWindow *win = [NSApp mainWindow];
	if ([self.delegate respondsToSelector:@selector(ESSVimeoNeedsWindowToAttachWindowTo:)])
		win = [self.delegate ESSVimeoNeedsWindowToAttachWindowTo:self];
	
	if (win != nil)
		[NSApp beginSheet:self._winCtr.window modalForWindow:win modalDelegate:nil didEndSelector:nil contextInfo:nil];
	else
	{
		[self._winCtr.window center];
		[self._winCtr.window makeKeyAndOrderFront:nil];
	}
#else
	self._viewCtr = [[[ESSVimeoiOSViewController alloc] initWithVideoURL:url delegate:self] autorelease];
	self._viewCtr.delegate = self;
	UINavigationController *navCtr = [[[UINavigationController alloc] initWithRootViewController:self._viewCtr] autorelease];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
		navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
	self._viewCtr.navCtr = navCtr;
	
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSVimeoNeedsViewControllerToAttachTo:)])
		currVCtr = [self.delegate ESSVimeoNeedsViewControllerToAttachTo:self];
	
	[currVCtr presentViewController:self._viewCtr.navCtr animated:YES completion:nil];
	
	if (self._authToken == nil)
		[self._viewCtr switchToLoginViewWithAnimation:NO];
	else
		[self _getQuotaJustConfirmingLogin:YES];
#endif
}

#pragma mark -
#pragma mark Authorization

- (void)_startAuthorization
{	
	//#if !TARGET_OS_IPHONE
	//this is just for MAC OS.
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"essvimeo", (CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleGetFlickrOAuthURL:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
	//end mac os code
	//#endif
#endif
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSURL *url = [NSURL URLWithString:VIMEO_OAUTH_REQUEST_TOKEN_URL];
		OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:url consumer:self._oaconsumer token:nil realm:nil signatureProvider:self._sigProv];
		[req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
		[req setHTTPMethod:@"GET"];
		[req setOAuthParameterName:@"oauth_callback" withValue:@"oob"]; //oob
		/*OARequestParameter *par = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"essvimeo:"]; //oob
		 NSMutableArray *params = [NSMutableArray arrayWithArray:[req parameters]];
		 [params addObject:par];
		 [par release];
		 [req setParameters:params];*/
		[req prepare];
		
		NSError *err = nil;
		NSURLResponse *resp = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
		[req release];
		if (data == nil || resp == nil || err != nil)
		{
			//start auth over.
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._winCtr.loginStatusField setHidden:YES];
				[self._winCtr.loginStatusProgressIndicator setHidden:YES];
				[self._winCtr.authorizeButton setEnabled:YES];
				[self._winCtr.authorizeButton setHidden:NO];
#else
				[self._viewCtr resetLoginView];
#endif
			});
		} else //got result
		{
			if ([(NSHTTPURLResponse *)resp statusCode] < 400)
			{
				NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				if (result == nil)
				{
					//start auth over
					dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
						[self._winCtr.loginStatusField setHidden:YES];
						[self._winCtr.loginStatusProgressIndicator setHidden:YES];
						[self._winCtr.authorizeButton setEnabled:YES];
						[self._winCtr.authorizeButton setHidden:NO];
#else
						[self._viewCtr resetLoginView];
#endif
					});
					return;
				}
				self._requestToken = [[[OAToken alloc] initWithHTTPResponseBody:result] autorelease];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString *urlStr = [NSString stringWithFormat:@"%@?%@&permission=write&oauth_callback=essvimeo",VIMEO_OAUTH_AUTH_URL,result];
					NSURL *url = [NSURL URLWithString:urlStr];
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
					[[NSWorkspace sharedWorkspace] openURL:url];
#else
					[[UIApplication sharedApplication] openURL:url];
#endif
				});
				
				[result release];
			} else
			{
				//start auth over
				dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
					[self._winCtr.loginStatusField setHidden:YES];
					[self._winCtr.loginStatusProgressIndicator setHidden:YES];
					[self._winCtr.authorizeButton setEnabled:YES];
					[self._winCtr.authorizeButton setHidden:NO];
#else
					[self._viewCtr resetLoginView];
#endif
				});
			}
		}
	});
}

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (void)handleGetFlickrOAuthURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	__block NSString *retStr = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] retain];
	
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"essvimeo", (CFStringRef)@"at.EternalStorms.nonexistent");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSRange oauthTokenRange = [retStr rangeOfString:@"oauth_token="];
		NSRange verifierRange = [retStr rangeOfString:@"oauth_verifier="];
		
		if (oauthTokenRange.location == NSNotFound || verifierRange.location == NSNotFound)
		{
			//start auth over
			[self._winCtr.loginStatusField setHidden:YES];
			[self._winCtr.loginStatusProgressIndicator setHidden:YES];
			[self._winCtr.authorizeButton setEnabled:YES];
			[self._winCtr.authorizeButton setHidden:NO];
		} else
		{
			NSString *oauth_token = [retStr substringFromIndex:oauthTokenRange.location + oauthTokenRange.length];
			oauth_token = [oauth_token substringToIndex:[oauth_token rangeOfString:@"&"].location];
			NSString *oauth_verifier = [retStr substringFromIndex:verifierRange.location + verifierRange.length];
			
			NSURL *authorizeURL = [NSURL URLWithString:VIMEO_OAUTH_ACCESS_TOKEN_URL];
			OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:authorizeURL
																	   consumer:self._oaconsumer
																		  token:self._requestToken
																		  realm:nil
															  signatureProvider:self._sigProv];
			[req setHTTPMethod:@"GET"];
			[req setOAuthParameterName:@"oauth_verifier" withValue:oauth_verifier];
			OARequestParameter *par = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:oauth_verifier];
			NSArray *arr = [NSArray arrayWithObject:par];
			[req setParameters:arr];
			[par release];
			[req prepare];
			NSError *err = nil;
			NSURLResponse *resp = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
			[req release];
			self._requestToken = nil;
			if (data == nil || resp == nil || err != nil)
			{
				//start auth over
				[self._winCtr.loginStatusField setHidden:YES];
				[self._winCtr.loginStatusProgressIndicator setHidden:YES];
				[self._winCtr.authorizeButton setEnabled:YES];
				[self._winCtr.authorizeButton setHidden:NO];
			} else
			{
				if ([(NSHTTPURLResponse *)resp statusCode] < 400)
				{
					NSString *authTokenStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					
					if (authTokenStr == nil)
					{
						//start auth over
						[self._winCtr.loginStatusField setHidden:YES];
						[self._winCtr.loginStatusProgressIndicator setHidden:YES];
						[self._winCtr.authorizeButton setEnabled:YES];
						[self._winCtr.authorizeButton setHidden:NO];
						return;
					}
					
					self._authToken = [[[OAToken alloc] initWithHTTPResponseBody:authTokenStr] autorelease];
					[self._authToken storeInUserDefaultsWithServiceProviderName:@"essvimeo" prefix:@"essvimeovideoupload"];
					
					[authTokenStr release];
					
					if (self._authToken == nil)
					{
						//start auth over
						[self._winCtr.loginStatusField setHidden:YES];
						[self._winCtr.loginStatusProgressIndicator setHidden:YES];
						[self._winCtr.authorizeButton setEnabled:YES];
						[self._winCtr.authorizeButton setHidden:NO];
					} else
					{
						//auth good, getQuota
						dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
							[self _getQuotaJustConfirmingLogin:NO];
						});
					}
				} else
				{
					//start auth over
					[self._winCtr.loginStatusField setHidden:YES];
					[self._winCtr.loginStatusProgressIndicator setHidden:YES];
					[self._winCtr.authorizeButton setEnabled:YES];
					[self._winCtr.authorizeButton setHidden:NO];
				}
			}
		}
		[retStr release];
	});
}
#else
- (void)handleiOSURL:(NSURL *)url
{
	[url retain];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[url autorelease];
		NSString *retStr = [url.absoluteString retain];
		NSRange oauthTokenRange = [retStr rangeOfString:@"oauth_token="];
		NSRange verifierRange = [retStr rangeOfString:@"oauth_verifier="];
		
		if (oauthTokenRange.location == NSNotFound || verifierRange.location == NSNotFound)
		{
			//start auth over
			[self._viewCtr resetLoginView];
		} else
		{
			NSString *oauth_token = [retStr substringFromIndex:oauthTokenRange.location + oauthTokenRange.length];
			oauth_token = [oauth_token substringToIndex:[oauth_token rangeOfString:@"&"].location];
			NSString *oauth_verifier = [retStr substringFromIndex:verifierRange.location + verifierRange.length];
			
			NSURL *authorizeURL = [NSURL URLWithString:VIMEO_OAUTH_ACCESS_TOKEN_URL];
			OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:authorizeURL
																	   consumer:self._oaconsumer
																		  token:self._requestToken
																		  realm:nil
															  signatureProvider:self._sigProv];
			[req setHTTPMethod:@"GET"];
			[req setOAuthParameterName:@"oauth_verifier" withValue:oauth_verifier];
			[req prepare];
			NSError *err = nil;
			NSURLResponse *resp = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
			[req release];
			self._requestToken = nil;
			if (data == nil || resp == nil || err != nil)
			{
				//start auth over
				[self._viewCtr resetLoginView];
			} else
			{
				if ([(NSHTTPURLResponse *)resp statusCode] < 400)
				{
					NSString *authTokenStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					
					if (authTokenStr == nil)
					{
						//start auth over
						[self._viewCtr resetLoginView];
						[retStr release];
						return;
					}
					
					self._authToken = [[[OAToken alloc] initWithHTTPResponseBody:authTokenStr] autorelease];
					[self._authToken storeInUserDefaultsWithServiceProviderName:@"essvimeo" prefix:@"essvimeovideoupload"];
					
					[authTokenStr release];
					
					if (self._authToken == nil)
					{
						//start auth over
						[self._viewCtr resetLoginView];
					} else
					{
						//auth good, getQuota
						dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
							[self _getQuotaJustConfirmingLogin:NO];
						});
					}
				} else
				{
					//start auth over
					[self._viewCtr resetLoginView];
				}
			}
		}
		[retStr release];
	});
}
#endif

- (void)_getQuotaJustConfirmingLogin:(BOOL)confirming
{
	NSString *serverResponse = [self _executeMethod:@"vimeo.videos.upload.getQuota" withParameters:nil];
	if (serverResponse == nil)
	{
		//error, handle it, reauthorize
		[self _deauthorize];
		
		//show auth view in window
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		[self._winCtr.loginStatusField setHidden:YES];
		[self._winCtr.loginStatusProgressIndicator setHidden:YES];
		[self._winCtr.authorizeButton setEnabled:YES];
		[self._winCtr.authorizeButton setHidden:NO];
#else
		[self._viewCtr resetLoginView];
#endif
		
		return;
	} else
	{
		NSString *resp = (NSString *)serverResponse;
		NSRange userIDRange = [resp rangeOfString:@"<user id=\""];
		NSRange isPlusRange = [resp rangeOfString:@" is_plus=\""];
		NSRange freeRange = [resp rangeOfString:@"<upload_space free=\""];
		NSRange maxRange = [resp rangeOfString:@"\" max=\""];
		NSRange hdQuotaRange = [resp rangeOfString:@"<hd_quota>"];
		NSRange sdQuotaRange = [resp rangeOfString:@"<sd_quota>"];
		if (userIDRange.location == NSNotFound || isPlusRange.location == NSNotFound || freeRange.location == NSNotFound || maxRange.location == NSNotFound ||
			hdQuotaRange.location == NSNotFound || sdQuotaRange.location == NSNotFound)
		{
			//error, handle it, reauthorize.
			[self _deauthorize];
			
			//show auth view in window
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr.loginStatusField setHidden:YES];
			[self._winCtr.loginStatusProgressIndicator setHidden:YES];
			[self._winCtr.authorizeButton setEnabled:YES];
			[self._winCtr.authorizeButton setHidden:NO];
			
			[self._winCtr switchToLoginViewWithAnimation:!confirming];
#else
			[self._viewCtr switchToLoginViewWithAnimation:!confirming];
#endif
			
			return;
		}
		
		NSString *userID = [resp substringFromIndex:userIDRange.location + userIDRange.length];
		userID = [userID substringToIndex:[userID rangeOfString:@"\""].location];
		NSString *isPlusStr = [resp substringFromIndex:isPlusRange.location + isPlusRange.length];
		isPlusStr = [isPlusStr substringToIndex:[isPlusStr rangeOfString:@"\""].location];
		BOOL isPlus = [isPlusStr boolValue];
		NSString *freeSpaceStr = [resp substringFromIndex:freeRange.location + freeRange.length];
		freeSpaceStr = [freeSpaceStr substringToIndex:[freeSpaceStr rangeOfString:@"\""].location];
		NSUInteger freeSpaceBytes = (NSUInteger)[freeSpaceStr integerValue];
		NSString *maxSpaceStr = [resp substringFromIndex:maxRange.location + maxRange.length];
		maxSpaceStr = [maxSpaceStr substringToIndex:[maxSpaceStr rangeOfString:@"\""].location];
		NSUInteger maxBytes = (NSUInteger)[maxSpaceStr integerValue];
		NSString *hdQuotaStr = [resp substringFromIndex:hdQuotaRange.location + hdQuotaRange.length];
		hdQuotaStr = [hdQuotaStr substringToIndex:[hdQuotaStr rangeOfString:@"</hd"].location];
		NSUInteger hdQuota = (NSUInteger)[hdQuotaStr integerValue];
		NSString *sdQuotaStr = [resp substringFromIndex:sdQuotaRange.location + sdQuotaRange.length];
		sdQuotaStr = [sdQuotaStr substringToIndex:[sdQuotaStr rangeOfString:@"</sd"].location];
		NSUInteger sdQuota = (NSUInteger)[sdQuotaStr integerValue];
		
		if (self.plusOnly && !isPlus && !confirming)
		{
			//the key has plus-access only, but we are not plus, so return error.
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr showNoPlusAccountWarning];
#else
			[self._viewCtr showNoPlusAccountWarning];
#endif
			return;
		} else if (self.plusOnly && !isPlus && confirming)
		{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr switchToLoginViewWithAnimation:NO];
#else
			[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
			return;
		}
		
		if (sdQuota <= 0 && hdQuota <= 0 && !confirming)
		{
			//no uploads left.
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr showNoSpaceLeftWarning];
#else
			[self._viewCtr showNoSpaceLeftWarning];
#endif
			return;
		} else if (sdQuota <= 0 && hdQuota <= 0 && confirming)
		{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr switchToLoginViewWithAnimation:NO];
#else
			[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
			return;
		}
		
		if ((self._byteSizeOfVideo > freeSpaceBytes || self._byteSizeOfVideo > maxBytes) && !confirming)
		{
			//video too large for upload
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr showNoSpaceLeftWarning];
#else
			[self._viewCtr showNoSpaceLeftWarning];
#endif
			return;
		} else if ((self._byteSizeOfVideo > freeSpaceBytes || self._byteSizeOfVideo > maxBytes) && confirming)
		{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr switchToLoginViewWithAnimation:NO];
#else
			[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
			return;
		}
		
		//everything alright, now get username.
		NSString *username = ESSLocalizedString(@"ESSVimeoUnknownUsername",nil);
		serverResponse = [self _executeMethod:@"vimeo.people.getInfo" withParameters:[NSDictionary dictionaryWithObject:userID forKey:@"user_id"]];
		if (serverResponse != nil)
		{			
			resp = (NSString *)serverResponse;
			NSRange usernameRange = [resp rangeOfString:@"<display_name>"];
			if (usernameRange.location == NSNotFound)
				usernameRange = [resp rangeOfString:@"<username>"];
			if (usernameRange.location != NSNotFound)
			{
				username = [resp substringFromIndex:usernameRange.location + usernameRange.length];
				username = [username substringToIndex:[username rangeOfString:@"</"].location];
			}
		}
		
		//got username, continue.
		
		//set username to window's usernamefield, switch to upload info view
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		self._winCtr.usernameField.stringValue = username;
		self._winCtr.titleField.stringValue = ESSLocalizedString(@"ESSVimeoDefaultTitle", nil);
		[self._winCtr switchToUploadViewWithAnimation:!confirming];
#else
		[self._viewCtr updateUsername:username];
		[self._viewCtr switchToUploadViewWithAnimation:!confirming];
#endif
	}
}

- (void)_uploadVideoAtURL:(NSURL *)url
					title:(NSString *)vidTitle
			  description:(NSString *)descr
					 tags:(NSString *)vidTags
			  makePrivate:(BOOL)makePrivate
{
	if (url == nil || self._authToken == nil || self._oaconsumer == nil || self._uploader != nil)
		return;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		self._description = descr;
		self._title = vidTitle;
		self._isPrivate = makePrivate;
		self._tags = vidTags;
		
		//get upload ticket.
		self._uploadTicketID = nil;
		NSString *response = [self _executeMethod:@"vimeo.videos.upload.getTicket" withParameters:[NSDictionary dictionaryWithObject:@"streaming" forKey:@"upload_method"]];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (response == nil)
			{
				//error uploading
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._winCtr uploadFinishedWithURL:nil];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
				return;
			}
			
			NSRange ticketRange = [response rangeOfString:@"<ticket endpoint=\""];
			NSRange ticketIDRange = [response rangeOfString:@"\" id=\""];
			if (ticketRange.location == NSNotFound || ticketIDRange.location == NSNotFound)
			{
				//error getting ticket.
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._winCtr uploadFinishedWithURL:nil];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
				return;
			}
			
			NSString *endpoint = [response substringFromIndex:ticketRange.location+ticketRange.length];
			endpoint = [endpoint substringToIndex:[endpoint rangeOfString:@"\""].location];
			self._uploadTicketID = [response substringFromIndex:ticketIDRange.location+ticketIDRange.length];
			self._uploadTicketID = [self._uploadTicketID substringToIndex:[self._uploadTicketID rangeOfString:@"\""].location];
			
			NSURL *uploadURL = [NSURL URLWithString:endpoint];
			OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:uploadURL consumer:self._oaconsumer token:self._authToken realm:nil signatureProvider:self._sigProv];
			[req setTimeoutInterval:60.0];
			[req setHTTPMethod:@"PUT"];
			[req setValue:[NSString stringWithFormat:@"%ld",self._byteSizeOfVideo] forHTTPHeaderField:@"Content-Length"];
			NSString *ext = url.pathExtension.lowercaseString;
			NSString *contType = @"video/quicktime";
			if ([ext isEqualToString:@"mov"])
				contType = @"video/quicktime";
			else if ([ext isEqualToString:@"mpg"])
				contType = @"video/mpeg";
			else if ([ext isEqualToString:@"3gp"])
				contType = @"video/3gpp";
			else if ([ext isEqualToString:@"mp4"])
				contType = @"video/mp4";
			else if ([ext isEqualToString:@"avi"])
				contType = @"video/avi";
			else if ([ext isEqualToString:@"wmv"])
				contType = @"video/x-ms-wmv";
			else if ([ext isEqualToString:@"mpeg2"])
				contType = @"video/mpeg2";
			[req setValue:contType forHTTPHeaderField:@"Content-Type"];
			
			NSInputStream *iStr = [NSInputStream inputStreamWithURL:url];
			[req setHTTPBodyStream:iStr];
			
			self._uploader = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES] autorelease];
			[req release];
		});
	});
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	[self._winCtr uploadFinishedWithURL:nil];
#else
	[self._viewCtr uploadFinishedWithURL:nil];
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	[self._winCtr uploadUpdatedWithBytes:totalBytesWritten ofTotal:totalBytesExpectedToWrite];
#else
	[self._viewCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//(verify and) finish upload
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		NSString *response = [self _executeMethod:@"vimeo.videos.upload.complete"
								   withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[self._winCtr.videoURL lastPathComponent],@"filename",self._uploadTicketID,@"ticket_id", nil]];
#else
		NSString *response = [self _executeMethod:@"vimeo.videos.upload.complete"
								   withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[self._viewCtr.videoURL lastPathComponent],@"filename",self._uploadTicketID,@"ticket_id", nil]];
#endif
		if (response == nil)
		{
			//error finishing / upload
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._winCtr uploadFinishedWithURL:nil];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
			});
			return;
		}
		
		NSRange videoIDRange = [response rangeOfString:@"\" video_id=\""];
		if (videoIDRange.location == NSNotFound)
		{
			//error with upload
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._winCtr uploadFinishedWithURL:nil];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
			});
			return;
		}
		
		NSString *videoID = [response substringFromIndex:videoIDRange.location + videoIDRange.length];
		videoID = [videoID substringToIndex:[videoID rangeOfString:@"\""].location];
		
		//set title, privacy and description
		if (self._title != nil) //set title
			[self _executeMethod:@"vimeo.videos.setTitle" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self._title,@"title",videoID,@"video_id", nil]];
		if (self._description != nil)
			[self _executeMethod:@"vimeo.videos.setDescription" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self._description,@"description",videoID,@"video_id", nil]];
		if (self._isPrivate)
			[self _executeMethod:@"vimeo.videos.setPrivacy" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"nobody",@"privacy",videoID,@"video_id", nil]];
		if (self._tags != nil && self._tags.length > 0)
			[self _executeMethod:@"vimeo.videos.addTags" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self._tags,@"tags",videoID,@"video_id", nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			//now let window know we're done.
			NSURL *_videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://vimeo.com/%@",videoID]];
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._winCtr uploadFinishedWithURL:_videoURL];
#else
			[self._viewCtr uploadFinishedWithURL:_videoURL];
#endif
		});
	});
}

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (void)vimeoWindowIsFinished:(ESSVimeoWindowController *)ctr
{
	[self._uploader cancel];
	self._uploader = nil;
	
	if ([self.delegate respondsToSelector:@selector(ESSVimeoFinished:)])
		[self.delegate ESSVimeoFinished:self];
}
#else
- (void)vimeoIsFinished:(ESSVimeoiOSViewController *)ctr
{
	[self._uploader cancel];
	self._uploader = nil;
	
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSVimeoNeedsViewControllerToAttachTo:)])
		currVCtr = [self.delegate ESSVimeoNeedsViewControllerToAttachTo:self];
	
	[currVCtr dismissViewControllerAnimated:YES completion:^{
		if ([self.delegate respondsToSelector:@selector(ESSVimeoFinished:)])
			[self.delegate ESSVimeoFinished:self];
	}];
}
#endif

- (NSString *)_executeMethod:(NSString *)method
			  withParameters:(NSDictionary *)parameters
{
	if (method == nil)
		return nil;
	NSLog(@"executeMethod: %@",method);
	[method retain];
	[parameters retain];
	
	OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:VIMEO_API_CALL_URL]
															   consumer:self._oaconsumer
																  token:self._authToken
																  realm:nil
													  signatureProvider:self._sigProv];
	[req setTimeoutInterval:60.0];
	
	[req setHTTPMethod:@"GET"];
	
	NSMutableArray *oaparams = [NSMutableArray array];
	OARequestParameter *mPar = [[OARequestParameter alloc] initWithName:@"method" value:method];
	[oaparams addObject:mPar];
	[mPar release];
	OARequestParameter *fPar = [[OARequestParameter alloc] initWithName:@"format" value:@"rest"];
	[oaparams addObject:fPar];
	[fPar release];
	
	if (parameters != nil && [[parameters allKeys] count] > 0)
	{
		for (NSString *key in parameters)
		{
			NSString *value = [parameters objectForKey:key];
			OARequestParameter *par = [[OARequestParameter alloc] initWithName:key value:value];
			[oaparams addObject:par];
			[par release];
		}
	}
	
	[req setParameters:oaparams];
	[req prepare];
	
	NSURLResponse *resp = nil;
	NSError *err = nil;
	NSData *retDat = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
	[req release];
	[parameters release];
	[method release];
	
	if (retDat == nil || resp == nil || err != nil)
		return nil;
	else
	{
		NSString *retStr = [[NSString alloc] initWithData:retDat encoding:NSUTF8StringEncoding];
		if (retStr == nil)
			return nil;
		
		return [retStr autorelease];
	}
	
	return nil;
}

- (void)_deauthorize
{
	//[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essvimeoUsername"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OAUTH_essvimeovideoupload_essvimeo_KEY"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OAUTH_essvimeovideoupload_essvimeo_SECRET"];
	self._authToken = nil;
}

- (void)dealloc
{
	self._uploader = nil;
	self._requestToken = nil;
	self._authToken = nil;
	self._oaconsumer = nil;
	self._sigProv = nil;
	self.delegate = nil;
	self._uploadTicketID = nil;
	self._title = nil;
	self._description = nil;
	self._tags = nil;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._winCtr = nil;
#else
	self._viewCtr = nil;
#endif
	
	[super dealloc];
}

@end
