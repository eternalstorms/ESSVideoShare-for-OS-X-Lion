//
//  ESSYouTube.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 04.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSYouTube.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation ESSYouTube

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@synthesize delegate,_ytWinCtr,developerKey,_authToken,_uploader,_receivedData;
#else
@synthesize delegate,_ytViewCtr,developerKey,_authToken,_uploader,_receivedData;

/*
 the following two functions are taken directly from http://opensource.apple.com/source/CF/CF-635/CFXMLParser.c since it's not available on iOS for a reason unknown to me
 */

CFStringRef CFXMLCreateStringByEscapingEntities(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFMutableStringRef newString = CFStringCreateMutable(allocator, 0); // unbounded mutable string
	CFMutableCharacterSetRef startChars = CFCharacterSetCreateMutable(allocator);
	
	CFStringInlineBuffer inlineBuf;
	CFIndex idx = 0;
	CFIndex mark = idx;
	CFIndex stringLength = CFStringGetLength(string);
	UniChar uc;
	
	CFCharacterSetAddCharactersInString(startChars, CFSTR("&<>'\""));
	
	CFStringInitInlineBuffer(string, &inlineBuf, CFRangeMake(0, stringLength));
	for(idx = 0; idx < stringLength; idx++) {
		uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, idx);
		if(CFCharacterSetIsCharacterMember(startChars, uc)) {
			CFStringRef previousSubstring = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
			CFStringAppend(newString, previousSubstring);
			CFRelease(previousSubstring);
			switch(uc) {
				case '&':
					CFStringAppend(newString, CFSTR("&amp;"));
					break;
				case '<':
					CFStringAppend(newString, CFSTR("&lt;"));
					break;
				case '>':
					CFStringAppend(newString, CFSTR("&gt;"));
					break;
				case '\'':
					CFStringAppend(newString, CFSTR("&apos;"));
					break;
				case '"':
					CFStringAppend(newString, CFSTR("&quot;"));
					break;
			}
			mark = idx + 1;
		}
	}
	// Copy the remainder to the output string before returning.
	CFStringRef remainder = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
	if (NULL != remainder) {
		CFStringAppend(newString, remainder);
		CFRelease(remainder);
	}
	
	CFRelease(startChars);
	return newString;
}

CFStringRef CFXMLCreateStringByUnescapingEntities(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFStringInlineBuffer inlineBuf; /* use this for fast traversal of the string in question */
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
		  developerKey:(NSString *)key
{
	if (self = [super init])
	{
		self.delegate = del;
		self.developerKey = key;
		
		return self;
	}
	
	return nil;
}

- (void)uploadVideoAtURL:(NSURL *)url
{
	if (self.developerKey == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[url path]])
		return;
	
	NSURL *testURL = [NSURL URLWithString:@"http://gdata.youtube.com/feeds/api/users/oddysseey"];
	NSError *err = nil;
	NSData *dat = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:testURL] returningResponse:nil error:&err];
	
	if (dat == nil || err != nil)
	{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		NSWindow *win = [NSApp mainWindow];
		if ([self.delegate respondsToSelector:@selector(ESSYouTubeNeedsWindowToAttachTo:)])
			win = [self.delegate ESSYouTubeNeedsWindowToAttachTo:self];
		if (win != nil)
		{
			NSBeginAlertSheet(ESSLocalizedString(@"ESSYouTubeNoInternetConnection",nil),
							  ESSLocalizedString(@"ESSFlickrOKButton",nil),
							  nil,
							  nil,
							  win, nil, nil, nil, nil,
							  ESSLocalizedString(@"ESSYouTubeNoInternetConnectionMsg",nil));
		} else
		{
			NSRunAlertPanel(ESSLocalizedString(@"ESSYouTubeNoInternetConnection",nil),
							ESSLocalizedString(@"ESSYouTubeNoInternetConnectionMsg",nil),
							ESSLocalizedString(@"ESSFlickrOKButton",nil),
							nil, nil);
		}
#else
		UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeNoInternetConnection",nil)
													 message:ESSLocalizedString(@"ESSYouTubeNoInternetConnectionMsg",nil)
													delegate:nil
										   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
										   otherButtonTitles:nil];
		
		[aV show];
		[aV release];
#endif
		
		if ([self.delegate respondsToSelector:@selector(ESSYouTubeDidFinish:)])
			[self.delegate ESSYouTubeDidFinish:self];
		
		return;
	}
	
	dat = nil;
	err = nil;
	testURL = nil;
	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._ytWinCtr = [[[ESSYouTubeWindowController alloc] initWithDelegate:self videoURL:url] autorelease];
	[self._ytWinCtr loadWindow];
	[self._ytWinCtr.uploadNextButton setEnabled:NO];
#else
	//iOS
	self._ytViewCtr = [[[ESSYouTubeiOSViewController alloc] initWithDelegate:self videoURL:url] autorelease];
	[self._ytViewCtr loadView];
	UINavigationController *navCtr = [[[UINavigationController alloc] initWithRootViewController:self._ytViewCtr] autorelease];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
		navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
	self._ytViewCtr.navContr = navCtr;
#endif
	
	[self _authorize];
}

- (void)_authorize //checks if we have a token saved. if so, skip ahead to upload view of windowcontroller. if not, present user with login in windowcontroller.
{
	NSDictionary *authDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"essyoutubeauth"];
	if (authDict == nil)
	{
		//start authorization
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		[self._ytWinCtr switchToLoginWithAnimation:NO];
#else
		[self._ytViewCtr switchToLoginViewWithAnimation:NO];
#endif
	} else //got auth already
	{
		self._authToken = [authDict objectForKey:@"authToken"];
		if (self._authToken == nil)
		{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			[self._ytWinCtr switchToLoginWithAnimation:NO];
#else
			//ios
			[self._ytViewCtr switchToLoginViewWithAnimation:NO];
#endif
		} else
		{
			//check if valid
			BOOL errorConnecting = NO;
			NSString *name = [self _nameForLoggedInUserErrorConnecting:&errorConnecting]; //just used to check if the key we got is still valid
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			if (errorConnecting)
			{
				NSWindow *attachWindow = [NSApp mainWindow];
				if ([self.delegate respondsToSelector:@selector(ESSYouTubeNeedsWindowToAttachTo:)])
					attachWindow = [self.delegate ESSYouTubeNeedsWindowToAttachTo:self];
				if (attachWindow != nil)
				{
					NSBeginAlertSheet(ESSLocalizedString(@"ESSYouTubeNoInternetConnection",nil),
									  ESSLocalizedString(@"ESSFlickrOKButton",nil),
									  nil,
									  nil,
									  attachWindow, nil, nil, nil, nil,
									  ESSLocalizedString(@"ESSYouTubeNoInternetConnectionMsg",nil));
				} else
				{
					NSRunAlertPanel(ESSLocalizedString(@"ESSYouTubeNoInternetConnection",nil),
									ESSLocalizedString(@"ESSYouTubeNoInternetConnectionMsg",nil),
									ESSLocalizedString(@"ESSFlickrOKButton",nil),
									nil, nil);
				}
				
				if ([self.delegate respondsToSelector:@selector(ESSYouTubeDidFinish:)])
					[self.delegate ESSYouTubeDidFinish:self];
				
				return;
			}
			if (name == nil)
			{
				//not valid
				[self _deauthorize];
				[self._ytWinCtr switchToLoginWithAnimation:NO];
			} else
			{
				self._ytWinCtr.uploadUsernameField.stringValue = name;
				[self._ytWinCtr switchToUploadWithAnimation:NO];
				
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					__block NSDictionary *dict = [[self _categoriesDictionary] retain];
					dispatch_async(dispatch_get_main_queue(), ^{
						[self._ytWinCtr setupCategoriesPopUpButtonWithCategoriesDictionary:dict];
						[dict release];
					});
				});
			}
#else
			//iOS
			
			if (errorConnecting)
			{
				UIAlertView *aV = [[UIAlertView alloc] initWithTitle:ESSLocalizedString(@"ESSFlickrNoInternetConnection",nil)
															 message:ESSLocalizedString(@"ESSFlickrNoInternetConnectionMsg",nil)
															delegate:nil
												   cancelButtonTitle:ESSLocalizedString(@"ESSFlickrOKButton", nil)
												   otherButtonTitles:nil];
				
				[aV show];
				[aV release];
				
				return;
			}
			
			if (name == nil)
			{
				[self _deauthorize];
				[self._ytViewCtr switchToLoginViewWithAnimation:NO];
			} else
			{
				[self._ytViewCtr updateUsername:name];
				[self._ytViewCtr switchToInfoViewWithAnimation:NO];
				
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					__block NSDictionary *dict = [[self _categoriesDictionary] retain];
					dispatch_async(dispatch_get_main_queue(), ^{
						[self._ytViewCtr updateCategories:dict];
						[dict release];
					});
				});
			}
#endif
		}
	}
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	NSWindow *win = [NSApp mainWindow];
	if ([self.delegate respondsToSelector:@selector(ESSYouTubeNeedsWindowToAttachTo:)])
		win = [self.delegate ESSYouTubeNeedsWindowToAttachTo:self];
	
	if (win != nil)
		[NSApp beginSheet:self._ytWinCtr.window modalForWindow:win modalDelegate:nil didEndSelector:nil contextInfo:nil];
	else
	{
		[self._ytWinCtr.window center];
		[self._ytWinCtr.window makeKeyAndOrderFront:nil];
	}
#else
	//iOS
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSYouTubeNeedsCurrentViewControllerToAttachTo:)])
		currVCtr = [self.delegate ESSYouTubeNeedsCurrentViewControllerToAttachTo:self];
	
	[currVCtr presentViewController:self._ytViewCtr.navContr animated:YES completion:nil];
#endif
}

- (void)_authorizeWithUsername:(NSString *)username password:(NSString *)password //does the actual authorization
{
	if (username == nil || password == nil || self.developerKey == nil)
		return;
	
	__block NSString *_username = (NSString *)[(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)username, NULL, NULL, kCFStringEncodingUTF8) autorelease];
	__block NSString *_password = (NSString *)[(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)password, NULL, NULL, kCFStringEncodingUTF8) autorelease];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSURL *url = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
		NSString *bodyString = [NSString stringWithFormat:@"Email=%@&Passwd=%@&service=youtube&source=essyoutube",_username,_password];
		[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		[req setHTTPMethod:@"POST"];
		[req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		
		NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
		__block NSString *authToken = nil;
		if (retData != nil)
			authToken = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
		dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
			if (authToken == nil)
			{
				//error, let our windowcontroller know
				self._ytWinCtr.usernameField.stringValue = @"";
				self._ytWinCtr.passwordField.stringValue = @"";
				[self._ytWinCtr.signingInProgWheel setHidden:YES];
				[self._ytWinCtr.signingInStatusField setHidden:YES];
				[self._ytWinCtr.signInButton setEnabled:YES];
				[self._ytWinCtr.loginCancelButton setHidden:NO];
				return;
			}
			
			if ([authToken rangeOfString:@"Error=" options:NSCaseInsensitiveSearch].location != NSNotFound)
			{
				//error, let windowcontroller know
				self._ytWinCtr.usernameField.stringValue = @"";
				self._ytWinCtr.passwordField.stringValue = @"";
				[self._ytWinCtr.signingInProgWheel setHidden:YES];
				[self._ytWinCtr.signingInStatusField setHidden:YES];
				[self._ytWinCtr.signInButton setEnabled:YES];
				[self._ytWinCtr.loginCancelButton setHidden:NO];
				self._authToken = nil;
				[authToken release];
				return;
			}
			
			self._authToken = authToken;
			[authToken release];
			
			NSRange authRange = [self._authToken rangeOfString:@"Auth="];
			if (authRange.location == NSNotFound)
			{
				//let windowcontr know something went wrong
				self._ytWinCtr.usernameField.stringValue = @"";
				self._ytWinCtr.passwordField.stringValue = @"";
				[self._ytWinCtr.signingInProgWheel setHidden:YES];
				[self._ytWinCtr.signingInStatusField setHidden:YES];
				[self._ytWinCtr.signInButton setEnabled:YES];
				[self._ytWinCtr.loginCancelButton setHidden:NO];
				self._authToken = nil;
				return;
			}
			
			//NSString *name = [self nameForLoggedInUser];
			NSString *name = _username;
			if (name == nil)
			{
				//let windowcontroller know something went wrong
				self._ytWinCtr.usernameField.stringValue = @"";
				self._ytWinCtr.passwordField.stringValue = @"";
				[self._ytWinCtr.signingInProgWheel setHidden:YES];
				[self._ytWinCtr.signingInStatusField setHidden:YES];
				[self._ytWinCtr.signInButton setEnabled:YES];
				[self._ytWinCtr.loginCancelButton setHidden:NO];
				self._authToken = nil;
				return;
			}
			
			[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"username",self._authToken,@"authToken", nil] forKey:@"essyoutubeauth"];
			
			NSDictionary *dict = [self _categoriesDictionary];
			[self._ytWinCtr setupCategoriesPopUpButtonWithCategoriesDictionary:dict];
			self._ytWinCtr.uploadUsernameField.stringValue = name;
			[self._ytWinCtr switchToUploadWithAnimation:YES];
			[self._ytWinCtr.signInButton setEnabled:YES];
#else
			//iOS
			if (authToken == nil)
			{
				//error, let our windowcontroller know
				[self._ytViewCtr resetLoginInfo];
				return;
			}
			
			if ([authToken rangeOfString:@"Error=" options:NSCaseInsensitiveSearch].location != NSNotFound)
			{
				//error, let windowcontroller know
				[self._ytViewCtr resetLoginInfo];
				
				self._authToken = nil;
				[authToken release];
				return;
			}
			
			self._authToken = authToken;
			[authToken release];
			
			NSRange authRange = [self._authToken rangeOfString:@"Auth="];
			if (authRange.location == NSNotFound)
			{
				//let windowcontr know something went wrong
				[self._ytViewCtr resetLoginInfo];
				
				self._authToken = nil;
				return;
			}
			
			//NSString *name = [self nameForLoggedInUser];
			NSString *name = _username;
			if (name == nil)
			{
				//let windowcontroller know something went wrong
				[self._ytViewCtr resetLoginInfo];
				
				self._authToken = nil;
				return;
			}
			
			[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"username",self._authToken,@"authToken", nil] forKey:@"essyoutubeauth"];
			
			NSDictionary *dict = [self _categoriesDictionary];
			[self._ytViewCtr updateCategories:dict];
			[self._ytViewCtr updateUsername:name];
			[self._ytViewCtr switchToInfoViewWithAnimation:YES];
#endif
		});
	});
}

- (NSDictionary *)_categoriesDictionary
{
	NSString *urlString = ESSLocalizedString(@"ESSYouTubeCategoryURLString",nil);
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
	[req setHTTPMethod:@"GET"];
	
	NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
	if (retData == nil)
		return nil;
	NSString *retStr = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSRange range = [retStr rangeOfString:@"<atom:category term='"];
	while (range.location != NSNotFound)
	{
		@autoreleasepool
		{
			NSString *catStr = [retStr substringFromIndex:range.location];
			catStr = [catStr substringToIndex:[catStr rangeOfString:@"</atom:category"].location];
			
			retStr = [[[retStr autorelease] substringFromIndex:range.location+range.length] retain];
			range = [retStr rangeOfString:@"<atom:category term='"];
			
			NSRange deprecatedRange = [catStr rangeOfString:@"<yt:deprecated/>"];
			if (deprecatedRange.location == NSNotFound)
			{
				NSRange assignableRange = [catStr rangeOfString:@"<yt:assignable/>"];
				if (assignableRange.location != NSNotFound)
				{
					//is not deprecated and is assignable
					NSRange _range = [catStr rangeOfString:@"<atom:category term='"];
					if (_range.location != NSNotFound)
					{
						NSString *term = [catStr substringFromIndex:_range.location+_range.length];
						term = [term substringToIndex:[term rangeOfString:@"'"].location];
						_range = [catStr rangeOfString:@"' label='"];
						if (_range.location != NSNotFound)
						{
							NSString *label = [catStr substringFromIndex:_range.location+_range.length];
							label = [label substringToIndex:[label rangeOfString:@"'"].location];
							
							term = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)term, NULL) autorelease];
							label = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)label, NULL) autorelease];
							
							[dict setObject:term forKey:label];
						}
					}
				}
			}
		}
	}
	
	[retStr release];
	
	return dict;
}

- (NSString *)_nameForLoggedInUserErrorConnecting:(BOOL *)errorConnecting
{
	if (errorConnecting != nil)
		*errorConnecting = NO;
	if (self.developerKey == nil || self._authToken == nil)
		return nil;
	
	NSString *justAuth = [self._authToken substringFromIndex:[self._authToken rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://gdata.youtube.com/feeds/api/users/default?v=2&key=%@&format=xml",self.developerKey]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
	[req setHTTPMethod:@"GET"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];
	
	NSError *error = nil;
	NSData *retDat = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&error];
	if (retDat == nil)
	{
		*errorConnecting = YES;
		return nil;
	}
	
	NSString *retStr = [[[NSString alloc] initWithData:retDat encoding:NSUTF8StringEncoding] autorelease];
	NSRange userNameRange = [retStr rangeOfString:@"<yt:username "];
	if (userNameRange.location == NSNotFound)
		return nil;
	
	//changes by Jean-Pierre Rizzi
	NSString *username = nil;
	username = [retStr substringFromIndex:userNameRange.location+userNameRange.length];
	username = [username substringFromIndex:[username rangeOfString:@">"].location+1];
	username = [username substringToIndex:[username rangeOfString:@"</yt:username"].location];
	
	return username;
}

- (void)_deauthorize //removes authorization token from userdefaults
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essyoutubeauth"];
}

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (void)youtubeWindowControllerDidDismiss:(ESSYouTubeWindowController *)ytWCtr
{
	[self._uploader cancel];
	self._uploader = nil;
	self._ytWinCtr = nil;
	
	if ([self.delegate respondsToSelector:@selector(ESSYouTubeDidFinish:)])
		[self.delegate performSelector:@selector(ESSYouTubeDidFinish:) withObject:self afterDelay:0.5];
}
#else
- (void)youtubeiOSViewControllerDidDismiss:(ESSYouTubeiOSViewController *)ytViewCtr
{
	[self._uploader cancel];
	self._uploader = nil;
	self._ytViewCtr = nil;
	
	UIViewController *currVCtr = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	if ([self.delegate respondsToSelector:@selector(ESSYouTubeNeedsCurrentViewControllerToAttachTo:)])
		currVCtr = [self.delegate ESSYouTubeNeedsCurrentViewControllerToAttachTo:self];
	
	[currVCtr dismissViewControllerAnimated:YES completion:^{
		if ([self.delegate respondsToSelector:@selector(ESSYouTubeDidFinish:)])
			[self.delegate ESSYouTubeDidFinish:self];
	}];
}
#endif

- (void)_uploadVideoAtURL:(NSURL *)url
				withTitle:(NSString *)title
			  description:(NSString *)description
			  makePrivate:(BOOL)makePrivate
				 keywords:(NSString *)keywords
				 category:(NSString *)category //category will be omitted and automatically set <yt:incomplete>, privacy is <yt:private/> and <yt:accessControl action='list' permission='denied'>
{
	if (self.developerKey == nil || self._authToken == nil || url == nil || title == nil || self._uploader != nil)
		return;
	
	if (description == nil)
		description = @"";
	if (keywords == nil)
		keywords = @"";
	
	description = (NSString *)[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)description, NULL) autorelease];
	keywords = (NSString *)[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)keywords, NULL) autorelease];
	title = (NSString *)[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)title, NULL) autorelease];
	
	NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://uploads.gdata.youtube.com/feeds/api/users/default/uploads?v=2&key=%@",self.developerKey]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:uploadURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
	NSString *justAuth = [self._authToken substringFromIndex:[self._authToken rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	[req setHTTPMethod:@"POST"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];
	[req setValue:[[url path] lastPathComponent] forHTTPHeaderField:@"Slug"];
	[req setValue:@"multipart/related; boundary=\"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\"" forHTTPHeaderField:@"Content-Type"];
	[req setValue:@"close" forHTTPHeaderField:@"Connection"];
	
	//first, re-write the data of videoURL combined with the MIME-stuff to disk again
	NSString *beginString = [NSString stringWithFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: application/atom+xml; charset=UTF-8\r\n\r\n<?xml version=\"1.0\"?><entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:media=\"http://search.yahoo.com/mrss/\" xmlns:yt=\"http://gdata.youtube.com/schemas/2007\"><media:group><yt:incomplete/><media:category scheme=\"http://gdata.youtube.com/schemas/2007/categories.cat\">%@</media:category><media:title type=\"plain\">%@</media:title><media:description type=\"plain\">%@</media:description><media:keywords>%@</media:keywords>",category,title,description,keywords];
	if (makePrivate)
		beginString = [beginString stringByAppendingString:@"<yt:private/><yt:accessControl action=\"list\" permission=\"denied\"/>"];
	beginString = [beginString stringByAppendingString:@"</media:group></entry>\r\n\r\n"];
	
	//beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: video/quicktime\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: application/octet-stream\r\n\r\n"];
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essyoutubeTempVideoUpload"];
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
	[req setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[req setHTTPBodyStream:inStr];
	
	self._uploader = [[[NSURLConnection alloc] initWithRequest:req delegate:self] autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self._uploader cancel];
	self._uploader = nil;
	
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	NSString *statusString = nil;
	NSImage *image = nil;
	statusString = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
	NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
	image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	self._ytWinCtr.doneImageView.image = image;
	self._ytWinCtr.doneStatusField.stringValue = statusString;
	
	[self._ytWinCtr uploadFinishedWithYouTubeVideoURL:nil];
#else
	//iOS
	[self._ytViewCtr uploadFinishedWithYouTubeVideoURL:nil];
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self._receivedData == nil)
		self._receivedData = [NSMutableData data];
	
	[self._receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	[self._ytWinCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
#else
	//iOS
	[self._ytViewCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *resp = [[NSString alloc] initWithData:self._receivedData encoding:NSUTF8StringEncoding];
	self._receivedData = nil;
	
	NSRange URLRange = [resp rangeOfString:@":video:"];
	if (URLRange.location == NSNotFound)
	{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		NSString *statusString = nil;
		NSImage *image = nil;
		statusString = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
		NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
		image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		self._ytWinCtr.doneImageView.image = image;
		self._ytWinCtr.doneStatusField.stringValue = statusString;
		
		[self._ytWinCtr uploadFinishedWithYouTubeVideoURL:nil];
#else
		//iOS
		[self._ytViewCtr uploadFinishedWithYouTubeVideoURL:nil];
#endif
	} else
	{
		NSString *vidID = [resp substringFromIndex:URLRange.location + URLRange.length];
		vidID = [vidID substringToIndex:[vidID rangeOfString:@"</id>"].location];
		
		[self _checkProcessingOnYouTubeWithVideoID:vidID];
	}
	
	[resp release];
	
	[self._uploader cancel];
	self._uploader = nil;
}

- (void)_checkProcessingOnYouTubeWithVideoID:(NSString *)vidID
{
	[vidID retain];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		BOOL failed = NO;
		BOOL finished = [self _videoUploadWithID:vidID isFinishedWithError:&failed];
		if (!finished)
		{
			[vidID retain];
			double delayInSeconds = 15.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[self _checkProcessingOnYouTubeWithVideoID:vidID];
				[vidID release];
			});
		} else //isfinished
		{
			[vidID retain];
			dispatch_async(dispatch_get_main_queue(), ^{
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
				NSString *statusString = nil;
				NSImage *image = nil;
				if (failed)
				{
					//set failed icon and string
					statusString = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
					NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
					image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
				} else //didn't fail
				{
					//set success icon and string
					statusString = ESSLocalizedString(@"ESSYouTubeUploadSucceeded", nil);
					NSString *imgPath = @"/System/Library/CoreServices/Installer.app/Contents/PlugIns/Summary.bundle/Contents/Resources/Success.png";
					image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
				}
				
				self._ytWinCtr.doneImageView.image = image;
				self._ytWinCtr.doneStatusField.stringValue = statusString;
				
				[self._ytWinCtr uploadFinishedWithYouTubeVideoURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",vidID]]];
#else
				//iOS
				if (failed)
					[self._ytViewCtr uploadFinishedWithYouTubeVideoURL:nil];
				else
					[self._ytViewCtr uploadFinishedWithYouTubeVideoURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",vidID]]];
#endif
				
				[vidID release];
			});
		}
		
		[vidID release];
	});
}

- (BOOL)_videoUploadWithID:(NSString *)videoID isFinishedWithError:(BOOL *)uploadFailed
{
	if (videoID == nil)
		return YES;
	
	if (uploadFailed)
		*uploadFailed = NO;
	
	NSString *urlString = [NSString stringWithFormat:@"https://gdata.youtube.com/feeds/api/users/default/uploads/%@",videoID];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
	NSString *justAuth = [self._authToken substringFromIndex:[self._authToken rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	[req setHTTPMethod:@"GET"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
	if (data == nil)
	{
		if (uploadFailed)
			*uploadFailed = YES;
		return YES;
	}
	
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	NSRange stateRange = [str rangeOfString:@"<yt:state"];
	if (stateRange.location == NSNotFound)
	{
		if (uploadFailed)
			*uploadFailed = NO;
	} else
	{
		NSString *state = [str substringFromIndex:stateRange.location+stateRange.length];
		NSRange nameRange = [state rangeOfString:@" name='"];
		if (nameRange.location != NSNotFound)
		{
			state = [state substringFromIndex:nameRange.location + nameRange.length];
			state = [state substringToIndex:[state rangeOfString:@"'"].location];
			
			if ([state rangeOfString:@"processing" options:NSCaseInsensitiveSearch].location != NSNotFound)
				return NO; //still processing
			else
			{
				if (uploadFailed)
					*uploadFailed = YES;
			}
		}
	}
	
	return YES;
}

- (void)dealloc
{
	self.delegate = nil;
	self._uploader = nil;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	self._ytWinCtr = nil;
#else
	self._ytViewCtr = nil;
#endif
	self.developerKey = nil;
	self._authToken = nil;
	self._receivedData = nil;
	
	[super dealloc];
}

@end
