//
//  ESSFacebookLoginWindowController.m
//  FacebookMac
//
//  Created by Matthias Gansrigler on 29.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSFacebookWindowController.h"
#import "ESSFacebook.h"

@implementation ESSFacebookWindowController
@synthesize uploadButton;
@synthesize uploadView;
@synthesize usernameField;
@synthesize titleField;
@synthesize descriptionField;
@synthesize makePrivateButton;
@synthesize uploadProgressBar;
@synthesize uploadProgressField;
@synthesize uploadProgressView;
@synthesize uploadResultView;
@synthesize resultImageView;
@synthesize resultTextField;
@synthesize cancelButton;
@synthesize viewOnFBButton;
@synthesize webView,delegate,reactToCancel,appID;
@synthesize temporaryCookies,videoURL;

- (id)initWithDelegate:(id)del appID:(NSString *)appIDString videoURL:(NSURL *)url
{
	if (self = [super initWithWindowNibName:@"ESSFacebookWindow"])
	{
		self.delegate = del;
		self.appID = appIDString;
		self.videoURL = url;
		
		return self;
	}
	
	return nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate
{
	[self.webView removeFromSuperview];
	self.uploadButton.alphaValue = 0.0;
	[self.uploadButton setHidden:NO];
	[self.uploadButton setEnabled:YES];
	
	if (!shouldAnimate)
	{
		self.cancelButton.alphaValue = 1.0;
		self.uploadButton.alphaValue = 1.0;
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.window.frame.size.width, self.uploadView.frame.size.height+67+48+22/*titlebarheight*/) display:YES];
		self.uploadView.frame = NSMakeRect(0, 48, self.window.frame.size.width, self.uploadView.frame.size.height);
		[self.window.contentView addSubview:self.uploadView];
	} else
	{
		[self.cancelButton.animator setAlphaValue:1.0];
		[self.uploadButton.animator setAlphaValue:1.0];
		self.uploadView.frame = NSMakeRect(0, 48, self.window.frame.size.width, self.uploadView.frame.size.height);
		self.uploadView.alphaValue = 0.0;
		[self.window.contentView addSubview:self.uploadView];
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.window.frame.size.width, self.uploadView.frame.size.height+67+48/*+22*//*titlebarheight*/) display:YES animate:YES];
		[self.uploadView.animator setAlphaValue:1.0];
	}
	
	[self restoreTemporarilyDeletedFacebookCookies];
}

- (void)switchToLoginViewWithAnimation:(BOOL)shouldAnimate
{
	[self.uploadView removeFromSuperview];
	
	[self temporarilyDeleteFacebookCookies];
	
	if (!shouldAnimate)
	{
		self.cancelButton.alphaValue = 0.0;
		[self.uploadButton setHidden:YES];
		[self.uploadButton setEnabled:NO];
		
		[self.window setContentSize:NSMakeSize(self.window.frame.size.width, self.webView.frame.size.height+67+48)];
		self.webView.frame = NSMakeRect(0, 48, self.window.frame.size.width, self.webView.frame.size.height);
		[self.window.contentView addSubview:self.webView];
	} else
	{
		[self.cancelButton.animator setAlphaValue:0.0];
		[self.uploadButton.animator setAlphaValue:0.0];
		[self.uploadButton setEnabled:NO];
		double delayInSeconds = 0.6;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self.uploadButton setHidden:YES];
		});
		
		self.webView.frame = NSMakeRect(0, 48, self.window.frame.size.width, self.webView.frame.size.height);
		self.webView.alphaValue = 0.0;
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.window.frame.size.width, self.webView.frame.size.height+67+48/*+22*//*titlebarheight*/) display:YES animate:YES];
		[self.webView.animator setAlphaValue:1.0];
		[self.window.contentView performSelector:@selector(addSubview:) withObject:self.webView afterDelay:0.55];
	}
	
	[self openAuthorizationURLWithAppID:self.appID];
}

- (void)openAuthorizationURLWithAppID:(NSString *)anID
{
	self.reactToCancel = NO;
	if (anID == nil)
	{
		if ([self.delegate respondsToSelector:@selector(facebookLogin:returnedAccessToken:expirationDate:)])
			[self.delegate facebookLogin:self returnedAccessToken:nil expirationDate:nil];
		return;
	}
	self.appID = anID;
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?client_id=%@&response_type=token&scope=publish_stream&display=popup&redirect_uri=https://www.facebook.com/connect/login_success.html",self.appID]];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
	[[self.webView mainFrame] loadRequest:req];
}

- (IBAction)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(facebookLogin:returnedAccessToken:expirationDate:)])
		[self.delegate facebookLogin:self returnedAccessToken:nil expirationDate:nil];
}

- (NSRect)webViewFrame:(WebView *)sender
{
	return self.webView.frame;
}

- (void)webView:(WebView *)webView setFrame:(NSRect)frame
{
	[self.webView setFrame:self.webView.frame];
}

- (IBAction)changeAccount:(id)sender
{
	[self.cancelButton.animator setAlphaValue:0.0];
	[sender setEnabled:NO];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"essfacebookauth"];
	
	if ([self.delegate respondsToSelector:@selector(_deauthorize)])
		[(ESSFacebook *)self.delegate _deauthorize];
	
	[self switchToLoginViewWithAnimation:YES];
	[sender setEnabled:YES];
}

- (IBAction)startUpload:(id)sender
{
	if (self.titleField.stringValue.length == 0)
	{
		[self.window makeFirstResponder:self.titleField];
		NSBeep();
		return;
	}
	
	//switch to upload view
	[self uploadStarted];
	
	[(ESSFacebook *)self.delegate _uploadVideoAtURL:self.videoURL
											 title:self.titleField.stringValue
									   description:self.descriptionField.stringValue
										 isPrivate:(self.makePrivateButton.state == NSOnState)];
}

- (IBAction)viewOnFacebook:(id)sender
{
	NSURL *url = [NSURL URLWithString:((NSButton *)sender).alternateTitle];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)uploadStarted
{
	[self.window makeFirstResponder:nil];
	[self.uploadProgressBar setIndeterminate:YES];
	[self.uploadProgressBar startAnimation:nil];
	[self.uploadProgressView setAlphaValue:0.0];
	self.uploadProgressView.frame = self.uploadView.frame;
	[self.window.contentView addSubview:self.uploadProgressView];
	[self.uploadView.animator setAlphaValue:0.0];
	[self.uploadProgressView.animator setAlphaValue:1.0];
	
	[self.uploadButton setEnabled:NO];
	[self.uploadButton.animator setAlphaValue:0.0];
	
	double delayInSeconds = 0.6;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.uploadView removeFromSuperview];
		self.uploadButton.title = ESSLocalizedString(@"ESSFacebookButtonDone",nil);
		self.uploadButton.action = @selector(cancel:);
	});
}

- (void)uploadUpdatedWithBytes:(NSInteger)bytesUploaded ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadProgressBar setMinValue:0.0];
	[self.uploadProgressBar setMaxValue:totalBytes];
	[self.uploadProgressBar setDoubleValue:bytesUploaded];
	[self.uploadProgressBar setIndeterminate:NO];
	
	double percentDone = bytesUploaded*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadProgressField.stringValue = [NSString stringWithFormat:ESSLocalizedString(@"ESSFacebookUploadPercentageDone",nil),(NSUInteger)percentDone];
}

- (void)uploadFinishedWithFacebookVideoURL:(NSURL *)url
{
	//set view up
	NSImage *statusImage = nil;
	NSString *statusString = nil;
	self.viewOnFBButton.alternateTitle = [url absoluteString];
	[self.cancelButton.animator setAlphaValue:0.0];
	double delayInSeconds = 0.55;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.cancelButton setHidden:YES];
	});
	if (url != nil) //set green check image for uploadResultImageView and set according text
	{
		[self.uploadButton setEnabled:YES];
		[self.uploadButton.animator setAlphaValue:1.0];
		
		statusString = ESSLocalizedString(@"ESSFacebookUploadSucceeded",nil);
		NSString *imgPath = @"/System/Library/CoreServices/Installer.app/Contents/PlugIns/Summary.bundle/Contents/Resources/Success.png";
		statusImage = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		[self.viewOnFBButton setHidden:NO];
	} else //there's been an error, set red fail image and according text
	{
		statusString = ESSLocalizedString(@"ESSFacebookUploadFailed",nil);
		
		NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
		statusImage = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		[self.viewOnFBButton setHidden:YES];
	}
	self.resultTextField.stringValue = statusString;
	self.resultImageView.image = statusImage;
	
	//switch to result view	
	self.uploadResultView.frame = self.uploadProgressView.frame;
	self.uploadResultView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.uploadResultView];
	[self.uploadProgressView.animator setAlphaValue:0.0];
	[self.uploadResultView.animator setAlphaValue:1.0];
}

- (void)webView:(WebView *)sender
	   resource:(id)identifier
didReceiveResponse:(NSURLResponse *)response
 fromDataSource:(WebDataSource *)dataSource
{
	NSString *urlStr = [response.URL absoluteString];
	
	if ([urlStr rangeOfString:@"#access_token="].location != NSNotFound && [urlStr rangeOfString:@"&expires_in="].location != NSNotFound)
	{
		//got auth
		NSRange authRange = [urlStr rangeOfString:@"#access_token="];
		NSString *authToken = [urlStr substringFromIndex:authRange.location + authRange.length];
		authToken = [authToken substringToIndex:[authToken rangeOfString:@"&expires_in="].location];
		NSRange expRange = [urlStr rangeOfString:@"&expires_in="];
		NSString *expSecs = [urlStr substringFromIndex:expRange.location + expRange.length];
		NSDate *date = [NSDate dateWithTimeIntervalSinceNow:[expSecs integerValue]];
		
		if ([self.delegate respondsToSelector:@selector(facebookLogin:returnedAccessToken:expirationDate:)])
			[self.delegate facebookLogin:self returnedAccessToken:authToken expirationDate:date];
	} else if ([urlStr rangeOfString:@"error_reason="].location != NSNotFound || [urlStr rangeOfString:@"error_description="].location != NSNotFound)
		[self cancel:nil];
}

- (void)temporarilyDeleteFacebookCookies
{
	if (self.temporaryCookies != nil)
	{
		for (NSHTTPCookie *ck in self.temporaryCookies)
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:ck];
	}
	
	self.temporaryCookies = [NSMutableArray array];
	for (NSHTTPCookie *ck in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
	{
		if ([[ck domain] rangeOfString:@"facebook.com"].location != NSNotFound)
			[self.temporaryCookies addObject:ck];
	}
	
	for (NSHTTPCookie *ck in self.temporaryCookies)
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:ck];
}

- (void)restoreTemporarilyDeletedFacebookCookies
{
	if (self.temporaryCookies != nil)
	{
		for (NSHTTPCookie *ck in self.temporaryCookies)
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:ck];
	}
}

- (void)dealloc
{
	self.delegate = nil;
	self.appID = nil;
	self.webView = nil;
	self.uploadView = nil;
	self.temporaryCookies = nil;
	self.videoURL = nil;
	
	[super dealloc];
}

@end
