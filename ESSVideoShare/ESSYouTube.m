//
//  ESSYouTube.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 04.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSYouTube.h"

@implementation ESSYouTube

@synthesize delegate,_ytWinCtr,developerKey,_authToken,_uploader,_receivedData;

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
	
	self._ytWinCtr = [[[ESSYouTubeWindowController alloc] initWithDelegate:self videoURL:url] autorelease];
	[self._ytWinCtr loadWindow];
	[self._ytWinCtr.uploadNextButton setEnabled:NO];
	
	[self _authorize];
}

- (void)_authorize //checks if we have a token saved. if so, skip ahead to upload view of windowcontroller. if not, present user with login in windowcontroller.
{
	NSDictionary *authDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"essyoutubeauth"];
	if (authDict == nil)
	{
		//start authorization
		[self._ytWinCtr switchToLoginWithAnimation:NO];
	} else //got auth already
	{
		self._authToken = [authDict objectForKey:@"authToken"];
		if (self._authToken == nil)
		{
			[self._ytWinCtr switchToLoginWithAnimation:NO];
		} else
		{
			//check if valid
			NSString *name = [self _nameForLoggedInUser]; //just used to check if the key we got is still valid
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
		}
	}
	
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

- (NSString *)_nameForLoggedInUser
{
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
		return nil;
	
	NSString *retStr = [[[NSString alloc] initWithData:retDat encoding:NSUTF8StringEncoding] autorelease];
	
	NSRange userNameRange = [retStr rangeOfString:@":user:"];
	if (userNameRange.location == NSNotFound)
		userNameRange = [retStr rangeOfString:@":username"];
	if (userNameRange.location == NSNotFound)
		return nil;
	
	//changes by Jean-Pierre Rizzi
	NSString *username = nil;
	if (userNameRange.length <= 6) //:user:
	{
		username = [retStr substringFromIndex:userNameRange.location+userNameRange.length];
		username = [username substringToIndex:[username rangeOfString:@"</"].location];
	} else //:username:
	{
		NSString *usernameSubStr = [retStr substringFromIndex:userNameRange.location+userNameRange.length];
		userNameRange = [usernameSubStr rangeOfString:@"'>"];
		
		NSString *username = [usernameSubStr substringFromIndex:userNameRange.location+userNameRange.length];
		username = [username substringToIndex:[username rangeOfString:@"</"].location];
	}
	
	return username;
}

- (void)_deauthorize //removes authorization token from userdefaults
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essyoutubeauth"];
}

- (void)youtubeWindowControllerDidDismiss:(ESSYouTubeWindowController *)ytWCtr
{
	[self._uploader cancel];
	self._uploader = nil;
	self._ytWinCtr = nil;
	
	if ([self.delegate respondsToSelector:@selector(ESSYouTubeDidFinish:)])
		[self.delegate performSelector:@selector(ESSYouTubeDidFinish:) withObject:self afterDelay:0.5];
}

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
	
	NSString *statusString = nil;
	NSImage *image = nil;
	statusString = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
	NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
	image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	self._ytWinCtr.doneImageView.image = image;
	self._ytWinCtr.doneStatusField.stringValue = statusString;
	
	[self._ytWinCtr uploadFinishedWithYouTubeVideoURL:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self._receivedData == nil)
		self._receivedData = [NSMutableData data];
	
	[self._receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	[self._ytWinCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *resp = [[NSString alloc] initWithData:self._receivedData encoding:NSUTF8StringEncoding];
	self._receivedData = nil;
	
	NSRange URLRange = [resp rangeOfString:@":video:"];
	if (URLRange.location == NSNotFound)
	{
		NSString *statusString = nil;
		NSImage *image = nil;
		statusString = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
		NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
		image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		self._ytWinCtr.doneImageView.image = image;
		self._ytWinCtr.doneStatusField.stringValue = statusString;
		
		[self._ytWinCtr uploadFinishedWithYouTubeVideoURL:nil];
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
	self._ytWinCtr = nil;
	self.developerKey = nil;
	self._authToken = nil;
	self._receivedData = nil;
	
	[super dealloc];
}

@end
