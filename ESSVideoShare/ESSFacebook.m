//
//  ESSFacebook.m
//  FacebookMac
//
//  Created by Matthias Gansrigler on 29.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSFacebook.h"

@implementation ESSFacebook

@synthesize delegate,appID,appSecret,_accessToken,_uploader,_uploadedObjectID,_username,_fbWinCtr,_receivedData;

- (id)initWithDelegate:(id)del appID:(NSString *)anID appSecret:(NSString *)secret
{
	if (self = [super init])
	{
		self.delegate = del;
		self.appID = anID;
		self.appSecret = secret;
		self._username = nil;
		
		NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
		[[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
		
		return self;
	}
	
	return nil;
}

- (void)uploadVideoAtURL:(NSURL *)videoURL
{
	if (self.appID == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[videoURL path]])
		return;
	
	self._fbWinCtr = [[[ESSFacebookWindowController alloc] initWithDelegate:self appID:self.appID videoURL:videoURL] autorelease];
	[self._fbWinCtr loadWindow];
	
	if (self._accessToken == nil)
		[self _authorize]; //if we have no auth key saved from a previous session, this will take care of showing the login panel for us
}

- (void)_authorize
{
	if (self.appID == nil)
	{
		NSLog(@"appID == nil");
		return;
	}
	//first look in user-defaults if we have the access Token.
	NSDictionary *authDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"essfacebookauth"];
	if (authDict != nil)
	{
		NSDate *now = [NSDate date];
		if ([[authDict objectForKey:@"expirationDate"] laterDate:now] == now || [authDict objectForKey:@"expirationDate"] == nil)
		{
			authDict = nil;
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essfacebookauth"];
		}
		
		//make sure the key is still valid
		if (authDict != nil)
		{
			NSURL *nameURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",[authDict objectForKey:@"token"]]];
			NSData *retData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:nameURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0] returningResponse:nil error:nil];
			if (retData != nil)
			{
				NSString *retStr = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
				
				NSRange nameRange = [retStr rangeOfString:@"\"error\":"];
				if (nameRange.location != NSNotFound)
					authDict = nil;
				
				[retStr release];
			} else
				authDict = nil;
		}
	}
	
	NSWindow *baseWin = [NSApp mainWindow];
	if ([self.delegate respondsToSelector:@selector(ESSFacebookNeedsWindowToAttachTo:)])
		baseWin = [self.delegate ESSFacebookNeedsWindowToAttachTo:self];
	
	if (authDict != nil)
	{
		self._accessToken = [authDict objectForKey:@"token"];
		self._username = [authDict objectForKey:@"name"];
		self._fbWinCtr.usernameField.stringValue = self._username;
		if (self._fbWinCtr.titleField.stringValue.length == 0)
			self._fbWinCtr.titleField.stringValue = ESSLocalizedString(@"ESSFacebookDefaultTitle",nil);
		
		[self._fbWinCtr switchToUploadViewWithAnimation:NO];
	} else //need to show webview
	{
		self._accessToken = nil;
		self._username = nil;
		
		[self._fbWinCtr switchToLoginViewWithAnimation:NO];
	}
	
	if (baseWin != nil)
		[NSApp beginSheet:self._fbWinCtr.window modalForWindow:baseWin modalDelegate:self didEndSelector:@selector(facebookWin:didEndWithCode:context:) contextInfo:nil];
	else
	{
		[self._fbWinCtr.window center];
		[self._fbWinCtr.window makeKeyAndOrderFront:nil];
	}
}

- (void)facebookWin:(NSWindow *)window didEndWithCode:(NSUInteger)code context:(id)ctx
{
	double delayInSeconds = 0.55;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		if ([self.delegate respondsToSelector:@selector(ESSFacebookDidFinish:)])
			[self.delegate ESSFacebookDidFinish:self];
	});
}

- (void)_deauthorize
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essfacebookauth"];
	if (self._accessToken == nil)
		return;
	
	NSString *deletePermissionsAppURLStr = [NSString stringWithFormat:@"https://graph.facebook.com/me/permissions?access_token=%@",self._accessToken];
	NSURL *url = [NSURL URLWithString:deletePermissionsAppURLStr];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
	[req setHTTPMethod:@"DELETE"];
	
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
	data = nil;
	self._accessToken = nil;
}

- (void)facebookLogin:(ESSFacebookWindowController *)login
  returnedAccessToken:(NSString *)token
	   expirationDate:(NSDate *)expDate
{
	if (self._uploader != nil)
	{
		[self._uploader cancel];
		self._uploader = nil;
		
		if (login.window.parentWindow != nil)
			[NSApp endSheet:login.window];
		[login.window orderOut:nil];
		
		return;
	}
	
	if (token == nil)
	{	
		if (login.window.parentWindow != nil)
			[NSApp endSheet:login.window];
		[login.window orderOut:nil];
		
		return;
	}
	
	[token retain];
	self._accessToken = token;
	//retrieve name for current user
	NSURL *nameURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",self._accessToken]];
	NSData *retData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:nameURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0] returningResponse:nil error:nil];
	NSString *name = nil;
	if (retData != nil)
	{
		NSString *retStr = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
		
		NSRange nameRange = [retStr rangeOfString:@"\"name\":\""];
		if (nameRange.location == NSNotFound)
			nameRange = [retStr rangeOfString:@"\"name\": \""];
		if (nameRange.location != NSNotFound)
		{
			name = [retStr substringFromIndex:nameRange.location+nameRange.length];
			name = [name substringToIndex:[name rangeOfString:@"\""].location];
		}
		[retStr release];
	}
	self._username = name;
	
	[login switchToUploadViewWithAnimation:YES];
	if (self._username != nil)
		login.usernameField.stringValue = self._username;
	else
		login.usernameField.stringValue = ESSLocalizedString(@"ESSFacebookUnknownUsername",nil);
	login.titleField.stringValue = ESSLocalizedString(@"ESSFacebookDefaultTitle", nil);
	[token release];
	
	if (self._accessToken != nil)
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:self._accessToken forKey:@"token"];
		[dict setObject:expDate forKey:@"expirationDate"];
		if (name)
			[dict setObject:name forKey:@"name"];
		[[NSUserDefaults standardUserDefaults] setObject:dict
												  forKey:@"essfacebookauth"];
	} else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essfacebookauth"];
}

- (void)_uploadVideoAtURL:(NSURL *)videoURL
				   title:(NSString *)title
			 description:(NSString *)description
			   isPrivate:(BOOL)isPrivate
{
	if (videoURL == nil || self._accessToken == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[videoURL path]] || self._uploader != nil)
	{
		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self._fbWinCtr uploadFinishedWithFacebookVideoURL:nil];
		});
		return;
	}
	
	if (title == nil)
		title = @"";
	if (description == nil)
		description = @"";
	NSString *urlEscTitle = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)title, NULL, NULL, kCFStringEncodingUTF8);
	NSString *urlEscDesc = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)description, NULL, NULL, kCFStringEncodingUTF8);
	NSString *baseString = [NSString stringWithFormat:@"https://graph-video.facebook.com/me/videos?title=%@&description=%@&access_token=%@",urlEscTitle,urlEscDesc,self._accessToken];
	[urlEscTitle release];
	[urlEscDesc release];
	if (isPrivate)
		baseString = [baseString stringByAppendingString:@"&privacy=%7B%22value%22%3A%22SELF%22%7D"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
	[req setHTTPMethod:@"POST"];
	
	//first, re-write the data of videoURL combined with the MIME-stuff to disk again
	NSString *beginString = @"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"video\"; filename=\"filename.mov\"\r\nContent-Type: multipart/form-data\r\n\r\n";
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
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
	NSInputStream *iStr = [NSInputStream inputStreamWithURL:videoURL];
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
	
	NSString *endString = @"\r\n--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\n";
	UTF8String = [endString UTF8String];
	writeLength = strlen(UTF8String);
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
	if (actualWrittenLength != writeLength)
		NSLog(@"error writing ending of file");
	[oStr close];
	
	unsigned long long fileSize = -1;
	fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:uploadTempFilename error:nil] fileSize];
	[req setValue:@"multipart/form-data; boundary=3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f" forHTTPHeaderField:@"Content-Type"];
	[req setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[req setHTTPBodyStream:inStr];
	
	self._uploader = [[[NSURLConnection alloc] initWithRequest:req delegate:self] autorelease];
	[self._uploader start];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self._receivedData == nil)
		self._receivedData = [NSMutableData data];
	[self._receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *retStr = [[NSString alloc] initWithData:self._receivedData encoding:NSUTF8StringEncoding];
	self._receivedData = nil;
	NSRange idRange = [retStr rangeOfString:@"{\"id\":\""];
	if (idRange.location == NSNotFound)
		idRange = [retStr rangeOfString:@"{\"id\": \""];
	if (idRange.location == NSNotFound)
		self._uploadedObjectID = nil;
	else
	{
		self._uploadedObjectID = [retStr substringFromIndex:idRange.location+idRange.length];
		self._uploadedObjectID = [self._uploadedObjectID substringToIndex:[self._uploadedObjectID rangeOfString:@"\""].location];
	}
	[retStr release];
	
	self._uploader = nil;
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
	[[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
	
	if (self._uploadedObjectID == nil)
	{
		//error uploading
		[self._fbWinCtr uploadFinishedWithFacebookVideoURL:nil];
	} else
	{
		NSString *urlStr = [NSString stringWithFormat:@"https://www.facebook.com/video/video.php?v=%@",self._uploadedObjectID];
		NSURL *url = [NSURL URLWithString:urlStr];
		[self._fbWinCtr uploadFinishedWithFacebookVideoURL:url];
	}
	self._uploadedObjectID = nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	[self._fbWinCtr uploadUpdatedWithBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self._fbWinCtr uploadFinishedWithFacebookVideoURL:nil];
}

- (void)dealloc
{
	self.delegate = nil;
	self.appID = nil;
	self.appSecret = nil;
	self._accessToken = nil;
	self._uploader = nil;
	self._uploadedObjectID = nil;
	self._fbWinCtr = nil;
	self._receivedData = nil;
	
	[super dealloc];
}

@end
