//
//  ESSFlickr.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 07.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSFlickr.h"

@implementation ESSFlickr

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@synthesize delegate,_oaconsumer,_sigProv,_authToken,_requestToken,_flWinCtr,_uploader,_resultData;
#else
@synthesize delegate,_oaconsumer,_sigProv,_authToken,_requestToken,_viewCtr,_uploader,_resultData;

/*
 the following two functions are taken directly from http://opensource.apple.com/source/CF/CF-635/CFXMLParser.c since it's not available on iOS for a reason unknown to me
 */

CFStringRef CFXMLCreateStringByUnescapingEntitiesFlickr(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFStringInlineBuffer inlineBuf;
	CFStringRef sub;
	CFIndex lastChunkStart, length = CFStringGetLength(string);
	CFIndex i, entityStart;
	UniChar uc;
	UInt32 entity;
	int base;
	CFMutableDictionaryRef fullReplDict = entitiesDictionary ? CFDictionaryCreateMutableCopy(allocator, 0, entitiesDictionary) : CFDictionaryCreateMutable(allocator, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("amp"), (const void *)CFSTR("&"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("quot"), (const void *)CFSTR("\""));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("lt"), (const void *)CFSTR("<"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("gt"), (const void *)CFSTR(">"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("apos"), (const void *)CFSTR("'"));
	
	CFStringInitInlineBuffer(string, &inlineBuf, CFRangeMake(0, length - 1));
	CFMutableStringRef newString = CFStringCreateMutable(allocator, 0);
	
	lastChunkStart = 0;
	// Scan through the string in its entirety
	for(i = 0; i < length; ) {
		uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;	// grab the next character and move i.
		
		if(uc == '&') {
			entityStart = i - 1;
			entity = 0xFFFF;	// set this to a not-Unicode character as sentinel
			// we've hit the beginning of an entity. Copy everything from lastChunkStart to this point.
			if(lastChunkStart < i - 1) {
				sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(lastChunkStart, (i - 1) - lastChunkStart));
				CFStringAppend(newString, sub);
				CFRelease(sub);
			}
			
			uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;	// grab the next character and move i.
			// Now we can process the entity reference itself
			if(uc == '#') {	// this is a numeric entity.
				base = 10;
				entity = 0;
				uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
				
				if(uc == 'x') {	// only lowercase x allowed. Translating numeric entity as hexadecimal.
					base = 16;
					uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
				}
				
				// process the provided digits 'til we're finished
				while(true) {
					if (uc >= '0' && uc <= '9')
						entity = entity * base + (uc-'0');
					else if (uc >= 'a' && uc <= 'f' && base == 16)
						entity = entity * base + (uc-'a'+10);
					else if (uc >= 'A' && uc <= 'F' && base == 16)
						entity = entity * base + (uc-'A'+10);
					else break;
					
					if (i < length) {
						uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
					}
					else
						break;
				}
			}
			
			// Scan to the end of the entity
			while(uc != ';' && i < length) {
				uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
			}
			
			if(0xFFFF != entity) { // it was numeric, and translated.
				// Now, output the result fo the entity
				if(entity >= 0x10000) {
					UniChar characters[2] = { ((entity - 0x10000) >> 10) + 0xD800, ((entity - 0x10000) & 0x3ff) + 0xDC00 };
					CFStringAppendCharacters(newString, characters, 2);
				} else {
					UniChar character = entity;
					CFStringAppendCharacters(newString, &character, 1);
				}
			} else {	// it wasn't numeric.
				sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(entityStart + 1, (i - entityStart - 2))); // This trims off the & and ; from the string, so we can use it against the dictionary itself.
				CFStringRef replacementString = (CFStringRef)CFDictionaryGetValue(fullReplDict, sub);
				if(replacementString) {
					CFStringAppend(newString, replacementString);
				} else {
					CFRelease(sub); // let the old substring go, since we didn't find it in the dictionary
					sub =  CFStringCreateWithSubstring(allocator, string, CFRangeMake(entityStart, (i - entityStart))); // create a new one, including the & and ;
					CFStringAppend(newString, sub); // ...and append that.
				}
				CFRelease(sub); // in either case, release the most-recent "sub"
			}
			
			// move the lastChunkStart to the beginning of the next chunk.
			lastChunkStart = i;
		}
	}
	if(lastChunkStart < length) { // we've come out of the loop, let's get the rest of the string and tack it on.
		sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(lastChunkStart, i - lastChunkStart));
		CFStringAppend(newString, sub);
		CFRelease(sub);
	}
	
	CFRelease(fullReplDict);
	
	return newString;
}

#endif

- (id)initWithDelegate:(id)del
		applicationKey:(NSString *)key
	 applicationSecret:(NSString *)secret
{
	if (self = [super init])
	{
		self.delegate = del;
		self._oaconsumer = [[[OAConsumer alloc] initWithKey:key secret:secret] autorelease];
		self._sigProv = [[[OAPlaintextSignatureProvider alloc] init] autorelease];
		
		return self;
	}
	
	return nil;
}

- (void)uploadVideoAtURL:(NSURL *)url
{
	if (url == nil)
		return;
	
	//check length of video
	//if longer than 90 secs, refuse and show alert
	AVURLAsset *vid = [[[AVURLAsset alloc] initWithURL:url options:nil] autorelease];
	CGFloat duration = vid.duration.value/vid.duration.timescale;
	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	NSWindow *attachWindow = [NSApp mainWindow];
	if ([self.delegate respondsToSelector:@selector(ESSFlickrNeedsWindowToAttachTo:)])
		attachWindow = [self.delegate ESSFlickrNeedsWindowToAttachTo:self];
	
	if (duration > 90.0)
	{
		if (attachWindow != nil)
		{
			NSBeginAlertSheet(ESSLocalizedString(@"ESSFlickrMovieTooLongTitle",nil),
							  ESSLocalizedString(@"ESSFlickrOKButton",nil),
							  nil,
							  nil,
							  attachWindow, nil, nil, nil, nil,
							  ESSLocalizedString(@"ESSFlickrMovieTooLongMessage",nil));
		} else
		{
			NSRunAlertPanel(ESSLocalizedString(@"ESSFlickrMovieTooLongTitle",nil),
							ESSLocalizedString(@"ESSFlickrMovieTooLongMessage",nil),
							ESSLocalizedString(@"ESSFlickrOKButton",nil),
							nil,
							nil);
		}
		if ([self.delegate respondsToSelector:@selector(ESSFlickrDidFinish:)])
			[self.delegate ESSFlickrDidFinish:self];
		return;
	}
#else	
	if (duration > 90.0)
	{
		UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSFlickrMovieTooLongTitle",nil)
													 message:ESSLocalizedString(@"ESSFlickrMovieTooLongMsg",nil)
													delegate:nil
										   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
										   otherButtonTitles:nil];
		
		[aV show];
		[aV release];
		
		if ([self.delegate respondsToSelector:@selector(ESSFlickrDidFinish:)])
			[self.delegate ESSFlickrDidFinish:self];
		return;
	}
#endif
	
	//initiate window controller
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._flWinCtr = [[[ESSFlickrWindowController alloc] initWithDelegate:self videoURL:url] autorelease];
	[self._flWinCtr loadWindow];
#else
	self._viewCtr = [[[ESSFlickriOSViewController alloc] initWithDelegate:self videoURL:url] autorelease];
	[self._viewCtr loadView];
	
	UINavigationController *navCtr = [[[UINavigationController alloc] initWithRootViewController:self._viewCtr] autorelease];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
		navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
	self._viewCtr.navCtr = navCtr;
	
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSFlickrNeedsViewController:)])
		currVCtr = [self.delegate ESSFlickrNeedsViewController:self];
#endif
	
	//get authToken from Prefs
	self._authToken = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"essflickr" prefix:@"essflickrvideoupload"] autorelease];
	if (self._authToken != nil)
	{
		BOOL tokenInvalid = NO;
		BOOL canUpload = [self _canUploadVideosKeyInvalidCheck:&tokenInvalid];
		if (canUpload)
		{
			//token valid
			//show window with upload options
			NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"essflickrvideouploadUsername"];
			if (username == nil)
				username = ESSLocalizedString(@"ESSFlickrUnknownUsername", nil);
			//set username
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			self._flWinCtr.usernameField.stringValue = username;
			[self._flWinCtr switchToUploadViewWithAnimation:NO];
#else
			[self._viewCtr updateUsername:username];
			[self._viewCtr switchToUploadViewWithAnimation:NO];
#endif
		} else
		{
			if (tokenInvalid)
			{
				//show auth window
				[self _deauthorize];
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
#else
				[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
			} else if (!tokenInvalid)
			{
				//user is over quota. dismiss and show alert sheet
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				if (attachWindow != nil)
				{
					NSBeginAlertSheet(ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil),
									  ESSLocalizedString(@"ESSFlickrOKButton",nil),
									  nil,
									  nil,
									  attachWindow, nil, nil, nil, nil,
									  ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil));
				} else
				{
					NSRunAlertPanel(ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil),
									ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil),
									ESSLocalizedString(@"ESSFlickrOKButton",nil),
									nil, nil);
				}
#else
				[currVCtr dismissViewControllerAnimated:YES completion:nil];
				UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil)
															 message:ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil)
															delegate:nil
												   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
												   otherButtonTitles:nil];
				
				[aV show];
				[aV release];
#endif
				
				if ([self.delegate respondsToSelector:@selector(ESSFlickrDidFinish:)])
					[self.delegate ESSFlickrDidFinish:self];
				return;
			}
		}
	} else //authToken == nil
	{
		//show window with login notice for website redirection
		//authorization started by user by clicking a button
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
#else
		[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
	}
	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	if (attachWindow != nil)
		[NSApp beginSheet:self._flWinCtr.window modalForWindow:attachWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	else
	{
		[self._flWinCtr.window center];
		[self._flWinCtr.window makeKeyAndOrderFront:nil];
	}
#else
	[currVCtr presentViewController:self._viewCtr.navCtr animated:YES completion:nil];
#endif
}


#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (void)flickrWindowDidCancel:(ESSFlickrWindowController *)flickrWinCtr
{
	[self._uploader cancel];
	self._uploader = nil;
	
	
	
	if ([self.delegate respondsToSelector:@selector(ESSFlickrDidFinish:)])
		[self.delegate ESSFlickrDidFinish:self];
}
#else
- (void)flickrDidCancel:(ESSFlickriOSViewController *)flickrCtr
{
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSVimeoNeedsViewControllerToAttachTo:)])
		currVCtr = [self.delegate ESSFlickrNeedsViewController:self];
	
	[currVCtr dismissViewControllerAnimated:YES completion:^{
		if ([self.delegate respondsToSelector:@selector(ESSFlickrDidFinish:)])
			[self.delegate ESSFlickrDidFinish:self];
	}];
}
#endif

- (void)_authorize
{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	//this is just for MAC OS.
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"essflickrvideoupload", (CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleGetFlickrOAuthURL:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
	//end mac os code
#endif
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSURL *url = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"];
		OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:url consumer:self._oaconsumer token:nil realm:nil signatureProvider:self._sigProv];
		[req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
		[req setHTTPMethod:@"GET"];
		[req setOAuthParameterName:@"oauth_callback" withValue:@"essflickrvideoupload:"];
		[req prepare];
		
		NSError *err = nil;
		NSURLResponse *resp = nil;
		__block NSData *data = [[NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err] retain];
		[req release];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (data == nil || resp == nil || err != nil)
			{
				//show something wrent wrong in our window
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
#else
				[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
			} else //got result
			{
				if ([(NSHTTPURLResponse *)resp statusCode] < 400)
				{
					NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					if (result == nil)
					{
						//show something wrent wrong in our window
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
						[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
#else
						[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
					} else
					{
						self._requestToken = [[[OAToken alloc] initWithHTTPResponseBody:result] autorelease];
						
						//bug fix by Jean-Pierre Rizzi (added another retain to avoid crash later on)
						[result retain];
						dispatch_async(dispatch_get_main_queue(), ^{
							NSString *urlStr = [NSString stringWithFormat:@"http://www.flickr.com/services/oauth/authorize?%@&perms=write",result];
							NSURL *url = [NSURL URLWithString:urlStr];
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
							[[NSWorkspace sharedWorkspace] openURL:url];
#else
							[[UIApplication sharedApplication] openURL:url];
#endif
							[result release];
						});
					}
					
					[result release];
				} else
				{
					//show something wrent wrong in our window
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
					[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
#else
					[self._viewCtr switchToLoginViewWithAnimation:NO];
#endif
				}
			}
			[data release];
		});
	});
}

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (void)handleGetFlickrOAuthURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	__block NSString *retStr = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] retain];
	
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"essflickrvideoupload", (CFStringRef)@"com.EternalStorms.notavailable");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSRange oauthTokenRange = [retStr rangeOfString:@"oauth_token="];
		NSRange verifierRange = [retStr rangeOfString:@"oauth_verifier="];
		
		if (oauthTokenRange.location == NSNotFound || verifierRange.location == NSNotFound)
		{
			//show something wrent wrong in our window
			[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
		} else
		{
			NSString *oauth_token = [retStr substringFromIndex:oauthTokenRange.location + oauthTokenRange.length];
			oauth_token = [oauth_token substringToIndex:[oauth_token rangeOfString:@"&"].location];
			NSString *oauth_verifier = [retStr substringFromIndex:verifierRange.location + verifierRange.length];
			
			NSURL *authorizeURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/access_token"];
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
			__block NSData *data = [[NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err] retain];
			[req release];
			[retStr retain];
			dispatch_async(dispatch_get_main_queue(), ^{
				self._requestToken = nil;
				if (data == nil || resp == nil || err != nil)
				{
					//show something wrent wrong in our window
					[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
				} else
				{
					if ([(NSHTTPURLResponse *)resp statusCode] < 400)
					{
						NSString *authTokenStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
						if (authTokenStr == nil)
						{
							//show something wrent wrong in our window
							[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
						} else
						{
							self._authToken = [[[OAToken alloc] initWithHTTPResponseBody:authTokenStr] autorelease];
							[self._authToken storeInUserDefaultsWithServiceProviderName:@"essflickr" prefix:@"essflickrvideoupload"];
							
							NSString *name = nil;
							NSRange fullnameRange = [authTokenStr rangeOfString:@"fullname="];
							NSRange usernameRange = [authTokenStr rangeOfString:@"username="];
							if (fullnameRange.location != NSNotFound)
							{
								name = [authTokenStr substringFromIndex:fullnameRange.location + fullnameRange.length];
								name = [name substringToIndex:[name rangeOfString:@"&"].location];
								name = [self _unescapedString:name];
							} else if (usernameRange.location != NSNotFound)
								name = [authTokenStr substringFromIndex:usernameRange.location + usernameRange.length];
							
							if (name != nil)
								[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"essflickrvideouploadUsername"];
							else
								name = ESSLocalizedString(@"ESSFlickrUnknownUsername", nil);
							
							if (self._authToken == nil)
							{
								//show something wrent wrong in our window
								[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
							} else
							{
								//auth worked
								if ([self _canUploadVideosKeyInvalidCheck:nil] == YES)
								{
									//let windowobject know about it, show upload settings
									//set name
									self._flWinCtr.usernameField.stringValue = name;
									[self._flWinCtr switchToUploadViewWithAnimation:YES];
								} else
								{
									//can't upload video because user's over ratio
									__block NSWindow *attachWindow = [NSApp mainWindow];
									if ([self.delegate respondsToSelector:@selector(ESSFlickrNeedsWindowToAttachTo:)])
										attachWindow = [self.delegate ESSFlickrNeedsWindowToAttachTo:self];
									[attachWindow retain];
									[self._flWinCtr cancel:nil];
									double delayInSeconds = 0.8;
									dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
									dispatch_after(popTime, dispatch_get_main_queue(), ^(void){			
										if (attachWindow != nil)
										{
											NSBeginAlertSheet(ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil),
															  ESSLocalizedString(@"ESSFlickrOKButton",nil),
															  nil,
															  nil,
															  attachWindow, nil, nil, nil, nil,
															  ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil));
											[attachWindow release];
										} else
										{
											NSRunAlertPanel(ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil),
															ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil),
															ESSLocalizedString(@"ESSFlickrOKButton",nil),
															nil, nil);
										}
									});
								}
							}
						}
						
						[authTokenStr release];
					} else
					{
						//show something wrent wrong in our window
						[self._flWinCtr switchToAuthorizeViewWithAnimation:NO];
					}
				}
				
				[retStr release];
			});
		}
		[retStr release];
	});
}
#else
- (void)handleOpenURL:(NSURL *)url
{
	__block NSString *retStr = [url.absoluteString retain];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSRange oauthTokenRange = [retStr rangeOfString:@"oauth_token="];
		NSRange verifierRange = [retStr rangeOfString:@"oauth_verifier="];
		
		if (oauthTokenRange.location == NSNotFound || verifierRange.location == NSNotFound)
		{
			//show something wrent wrong in our window
			[self._viewCtr switchToLoginViewWithAnimation:NO];
		} else
		{
			NSString *oauth_token = [retStr substringFromIndex:oauthTokenRange.location + oauthTokenRange.length];
			oauth_token = [oauth_token substringToIndex:[oauth_token rangeOfString:@"&"].location];
			NSString *oauth_verifier = [retStr substringFromIndex:verifierRange.location + verifierRange.length];
			
			NSURL *authorizeURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/access_token"];
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
			__block NSData *data = [[NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err] retain];
			[req release];
			[retStr retain];
			dispatch_async(dispatch_get_main_queue(), ^{
				self._requestToken = nil;
				if (data == nil || resp == nil || err != nil)
				{
					//show something wrent wrong in our window
					[self._viewCtr switchToLoginViewWithAnimation:NO];
				} else
				{
					if ([(NSHTTPURLResponse *)resp statusCode] < 400)
					{
						NSString *authTokenStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
						if (authTokenStr == nil)
						{
							//show something wrent wrong in our window
							[self._viewCtr switchToLoginViewWithAnimation:NO];
						} else
						{
							self._authToken = [[[OAToken alloc] initWithHTTPResponseBody:authTokenStr] autorelease];
							[self._authToken storeInUserDefaultsWithServiceProviderName:@"essflickr" prefix:@"essflickrvideoupload"];
							
							NSString *name = nil;
							NSRange fullnameRange = [authTokenStr rangeOfString:@"fullname="];
							NSRange usernameRange = [authTokenStr rangeOfString:@"username="];
							if (fullnameRange.location != NSNotFound)
							{
								name = [authTokenStr substringFromIndex:fullnameRange.location + fullnameRange.length];
								name = [name substringToIndex:[name rangeOfString:@"&"].location];
								name = [self _unescapedString:name];
							} else if (usernameRange.location != NSNotFound)
								name = [authTokenStr substringFromIndex:usernameRange.location + usernameRange.length];
							
							if (name != nil)
								[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"essflickrvideouploadUsername"];
							else
								name = ESSLocalizedString(@"ESSFlickrUnknownUsername", nil);
							
							if (self._authToken == nil)
							{
								//show something wrent wrong in our window
								[self._viewCtr switchToLoginViewWithAnimation:NO];
							} else
							{
								//auth worked
								if ([self _canUploadVideosKeyInvalidCheck:nil] == YES)
								{
									//let windowobject know about it, show upload settings
									//set name
									[self._viewCtr updateUsername:name];
									[self._viewCtr switchToUploadViewWithAnimation:YES];
								} else
								{
									//can't upload video because user's over ratio
									[self._viewCtr switchToLoginViewWithAnimation:NO];
									
									UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSFlickrUserOverVideoQuota",nil)
																				 message:ESSLocalizedString(@"ESSFlickrUserOverVideoQuotaMsg",nil)
																				delegate:nil
																	   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
																	   otherButtonTitles:nil];
									
									[aV show];
									[aV release];
								}
							}
						}
						
						[authTokenStr release];
					} else
					{
						//show something wrent wrong in our window
						[self._viewCtr switchToLoginViewWithAnimation:NO];
					}
				}
				
				[retStr release];
			});
		}
		[retStr release];
	});
}
#endif

- (BOOL)_canUploadVideosKeyInvalidCheck:(BOOL *)keyInvalid
{
	if (keyInvalid)
		*keyInvalid = NO;
	
	if (self._authToken == nil)
		return NO;
	
	OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest"]
															   consumer:self._oaconsumer
																  token:self._authToken
																  realm:nil
													  signatureProvider:self._sigProv];
	[req setTimeoutInterval:60.0];
	
	[req setHTTPMethod:@"GET"];
	
	NSMutableArray *oaparams = [NSMutableArray array];
	OARequestParameter *mPar = [[OARequestParameter alloc] initWithName:@"method" value:@"flickr.people.getUploadStatus"];
	[oaparams addObject:mPar];
	[mPar release];
	OARequestParameter *fPar = [[OARequestParameter alloc] initWithName:@"format" value:@"rest"];
	[oaparams addObject:fPar];
	[fPar release];
	
	[req setParameters:oaparams];
	[req prepare];
	
	NSURLResponse *resp = nil;
	NSError *err = nil;
	NSData *retDat = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
	[req release];
	
	if (err != nil || retDat == nil)
		return NO;
	
	NSString *str = [[[NSString alloc] initWithData:retDat encoding:NSUTF8StringEncoding] autorelease];
	
	NSRange videosRange = [str rangeOfString:@"<videos "];
	if (videosRange.location == NSNotFound)
	{
		if (keyInvalid)
			*keyInvalid = YES;
		return NO;
	}
	
	str = [str substringFromIndex:videosRange.location+videosRange.length];
	NSRange remainingRange = [str rangeOfString:@" remaining=\""];
	if (remainingRange.location == NSNotFound)
		return NO;
	str = [str substringFromIndex:remainingRange.location+remainingRange.length];
	str = [str substringToIndex:[str rangeOfString:@"\""].location];
	
	if ([str rangeOfString:@"lots" options:NSCaseInsensitiveSearch].location == NSNotFound)
	{
		NSUInteger amount = [str integerValue];
		return (amount > 0);
	}
	
	return YES;
}

- (void)_deauthorize
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essflickrvideouploadUsername"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_KEY",@"essflickrvideoupload",@"essflickr"]];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_SECRET",@"essflickrvideoupload",@"essflickr"]];
}

- (NSString *)_unescapedString:(NSString *)aString
{
	[aString retain];
	if (aString == nil || aString.length == 0)
		return nil;
	
	NSString *bString = [aString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	if (bString != nil)
	{
		[aString release];
		aString = [bString retain];
	}

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	NSString *returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#else
	NSString *returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntitiesFlickr(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#endif
	
	if (returnString == nil)
		returnString = aString;
	else
	{
		aString = [returnString retain];
		
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#else
		returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntitiesFlickr(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#endif
		if (returnString == nil)
			returnString = aString;
	}
	
	return returnString;
}

- (void)_uploadVideoAtURL:(NSURL *)url
					title:(NSString *)title
			  description:(NSString *)description
					 tags:(NSString *)tags
			  makePrivate:(BOOL)makePrivate
{
	if (url == nil || self._authToken == nil || self._oaconsumer == nil || self._uploader != nil)
		return;
	
	NSURL *reqURL = [NSURL URLWithString:@"http://api.flickr.com/services/upload/"];
	OAMutableURLRequest *signatureReq = [[[OAMutableURLRequest alloc] initWithURL:reqURL
																		 consumer:self._oaconsumer
																			token:self._authToken
																			realm:nil
																signatureProvider:self._sigProv] autorelease];
	[signatureReq setHTTPMethod:@"POST"];
	[signatureReq setTimeoutInterval:60.0];
	NSMutableArray *params = [NSMutableArray array];
	OARequestParameter *par = [[OARequestParameter alloc] initWithName:@"title" value:title];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"description" value:description];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"is_public" value:(makePrivate ? @"0":@"1")];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"hidden" value:(makePrivate ? @"2":@"1")];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"async" value:@"0"];
	[params addObject:par];
	[par release];
	
	NSArray *tagsArr = [tags componentsSeparatedByString:@","];
	NSString *tagsString = @"";
	for (NSString *tag in tagsArr)
	{
		tagsString = [tagsString stringByAppendingFormat:@"\"%@\" ",tag];
	}
	
	par = [[OARequestParameter alloc] initWithName:@"tags" value:tagsString];
	[params addObject:par];
	[par release];
	
	[signatureReq setParameters:params];
	[signatureReq prepare];
	//NSString *sig = [signatureReq signature];
	[signatureReq setValue:@"multipart/form-data; boundary=\"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\"" forHTTPHeaderField:@"Content-Type"];
	
	NSString *beginString = [NSString stringWithFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\n%@\r\n",title];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"description\"\r\n\r\n%@\r\n",description];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"tags\"\r\n\r\n%@\r\n",tagsString];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"is_public\"\r\n\r\n%ld\r\n",(!makePrivate)];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"hidden\"\r\n\r\n%@\r\n",(makePrivate ? @"2":@"1")];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"async\"\r\n\r\n0\r\n"];
	
	//beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"speedSlideshow\"\r\nContent-Type: video/quicktime\r\n\r\n"];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"movie\"\r\n\r\n"];
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essflickrTempVideoUpload"];
	[[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
	
	NSOutputStream *oStr = [NSOutputStream outputStreamToFileAtPath:uploadTempFilename append:NO];
	[oStr open];
	const char *UTF8String;
	size_t writeLength;
	UTF8String = [beginString UTF8String];
	writeLength = strlen(UTF8String);
	size_t __unused actualWrittenLength;
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
	if (actualWrittenLength != writeLength)
		NSLog(@"error writing beginning");
	
	const size_t bufferSize = 65536;
	size_t readSize = 0;
	uint8_t *buffer = (uint8_t *)calloc(1, bufferSize);
	NSInputStream *iStr = [NSInputStream inputStreamWithURL:url];
	[iStr open];
	while ([iStr hasBytesAvailable])
	{
		if (!(readSize = [iStr read:buffer maxLength:bufferSize]))
			break;
		
		size_t __unused actualWrittenLength;
		actualWrittenLength = [oStr write:buffer maxLength:readSize];
		if (actualWrittenLength != readSize)
			NSLog(@"error reading the file data and writing it to new one");
	}
	[iStr close];
	free(buffer);
	
	NSString *endString = @"\r\n--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f--\r\n";
	UTF8String = [endString UTF8String];
	writeLength = strlen(UTF8String);
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
	if (actualWrittenLength != writeLength)
		NSLog(@"error writing ending of file");
	[oStr close];
	
	unsigned long long fileSize = -1;
	fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:uploadTempFilename error:nil] fileSize];
	[signatureReq setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[signatureReq setHTTPBodyStream:inStr];
	
	self._uploader = [[[NSURLConnection alloc] initWithRequest:signatureReq delegate:self] autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	self._uploader = nil;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
	[self._viewCtr uploadFinishedWithURL:nil];
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self._resultData == nil)
		self._resultData = [NSMutableData data];
	
	[self._resultData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	[self._flWinCtr uploadUpdatedWithBytes:totalBytesWritten ofTotal:totalBytesExpectedToWrite];
#else
	[self._viewCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *result = [[NSString alloc] initWithData:self._resultData encoding:NSUTF8StringEncoding];
	self._resultData = nil;
	
	if ([result rangeOfString:@"<rsp stat=\"fail"].location != NSNotFound ||
		[result rangeOfString:@"<err code=\""].location != NSNotFound)
	{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
		[self._viewCtr uploadFinishedWithURL:nil];
#endif
	} else
	{
		NSRange photoIDRange = [result rangeOfString:@"<photoid>"];
		if (photoIDRange.location == NSNotFound)
		{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
			[self._viewCtr uploadFinishedWithURL:nil];
#endif
			[result release];
			return;
		}
		
		NSString *photoID = [result substringFromIndex:photoIDRange.location+photoIDRange.length];
		photoID = [photoID substringToIndex:[photoID rangeOfString:@"</photo"].location];
		
		[self _checkPhotoID:photoID];
	}
	
	[result release];
	self._uploader = nil;
}

- (void)_checkPhotoID:(NSString *)photoID
{
	if (photoID == nil)
	{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
		[self._viewCtr uploadFinishedWithURL:nil];
#endif
		return;
	}
	
	[photoID retain];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[photoID autorelease];
		
		OAMutableURLRequest *req = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest"]
																   consumer:self._oaconsumer
																	  token:self._authToken
																	  realm:nil
														  signatureProvider:self._sigProv];
		[req setTimeoutInterval:60.0];
		
		[req setHTTPMethod:@"GET"];
		
		NSMutableArray *oaparams = [NSMutableArray array];
		OARequestParameter *mPar = [[OARequestParameter alloc] initWithName:@"method" value:@"flickr.photos.getInfo"];
		[oaparams addObject:mPar];
		[mPar release];
		OARequestParameter *fPar = [[OARequestParameter alloc] initWithName:@"format" value:@"rest"];
		[oaparams addObject:fPar];
		[fPar release];
		fPar = [[OARequestParameter alloc] initWithName:@"photo_id" value:photoID];
		[oaparams addObject:fPar];
		[fPar release];
		
		[req setParameters:oaparams];
		[req prepare];
		
		NSURLResponse *resp = nil;
		NSError *err = nil;
		NSData *retDat = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
		[req release];
		
		if (retDat == nil || err != nil)
		{
			NSLog(@"err");
			//error
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
			});
			return;
		}
		
		NSString *retStr = [[[NSString alloc] initWithData:retDat encoding:NSUTF8StringEncoding] autorelease];
		
		if ([retStr rangeOfString:@"<rsp stat=\"fail"].location != NSNotFound ||
			[retStr rangeOfString:@"<err code=\""].location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
			});
			return;
		}
		
		NSRange pendingRange = [retStr rangeOfString:@"pending=\"1"];
		if (pendingRange.location != NSNotFound)
		{
			[photoID retain];
			double delayInSeconds = 15.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[self _checkPhotoID:[photoID autorelease]];
			});
			return;
		}
		
		NSRange failedRange = [retStr rangeOfString:@"failed=\"1"];
		if (failedRange.location != NSNotFound)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
#else
				[self._viewCtr uploadFinishedWithURL:nil];
#endif
			});
			return;
		}
		
		NSRange successRange = [retStr rangeOfString:@"ready=\"1"];
		if (successRange.location != NSNotFound)
		{
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.flickr.com/photos/upload/edit/?ids=%@",photoID]];
			
			[url retain];
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				[self._flWinCtr uploadFinishedWithFlickrURL:[url autorelease] success:YES];
#else
				[self._viewCtr uploadFinishedWithURL:[url autorelease]];
#endif
			});
			return;
		}
	});
}

- (void)dealloc
{
	self.delegate = nil;
	self._oaconsumer = nil;
	self._sigProv = nil;
	self._authToken = nil;
	self._requestToken = nil;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._flWinCtr = nil;
#else
	self._viewCtr = nil;
#endif
	self._uploader = nil;
	self._resultData = nil;
	
	[super dealloc];
}

@end
