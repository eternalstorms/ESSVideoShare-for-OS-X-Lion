//
//  ESSFacebookiOSViewController.m
//  ESSVideoShare
//
//  Created by Matthias Gansrigler on 24.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import "ESSFacebookiOSViewController.h"
#import "ESSFacebook.h"

@interface ESSFacebookiOSViewController ()

@end

@implementation ESSFacebookiOSViewController

@synthesize delegate,navContr,infoTableViewController,uploadingViewController,uploadProgressBarView,percentDoneField,doneViewController,doneImageView,doneTextField,viewButton,appID,videoURL,username,videoTitle,temporaryCookies,titleTVCell,descriptionTVCell,privacyTVCell;

- (id)initWithDelegate:(id)del appID:(NSString *)someID videoURL:(NSURL *)url
{
	NSString *nibName = @"ESSFacebookiOSLoginView_iPhone";
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		nibName = @"ESSFacebookiOSLoginView_iPad";
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.infoTableViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.uploadingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.doneViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	if (self = [super initWithNibName:nibName bundle:nil])
	{
		self.delegate = del;
		self.videoURL = url;
		self.appID = someID;
		
		return self;
	}
	
	return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(facebookLogin:returnedAccessToken:expirationDate:)])
		[self.delegate facebookLogin:nil returnedAccessToken:nil expirationDate:nil];
	
	UITableViewCell *cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	UITextField *videoTitleField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTitleField = (UITextField *)view;
			break;
		}
	}
	[videoTitleField resignFirstResponder];
	cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	UITextField *videoDescField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoDescField = (UITextField *)view;
			break;
		}
	}
	[videoDescField resignFirstResponder];
}

- (void)changeAccount:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(_deauthorize)])
		[(ESSFacebook *)self.delegate _deauthorize];
	
	[self switchToLoginViewWithAnimation:YES];
}

- (void)startUpload:(id)sender
{
	//check for title, it must be present
	UITableViewCell *cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	UITextField *videoTitleField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTitleField = (UITextField *)view;
			break;
		}
	}
	[videoTitleField resignFirstResponder];
	NSString *title = videoTitleField.text;
	
	if (title.length == 0)
	{
		[videoTitleField becomeFirstResponder];
		return;
	}
	
	cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	UITextField *videoDescField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoDescField = (UITextField *)view;
			break;
		}
	}
	[videoDescField resignFirstResponder];
	NSString *description = videoDescField.text;
	
	cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	UISwitch *aSwitch = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UISwitch class]])
		{
			aSwitch = (UISwitch *)view;
			break;
		}
	}
	
	BOOL isPrivate = aSwitch.on;
	
	[self uploadStarted];
	[(ESSFacebook *)self.delegate _uploadVideoAtURL:self.videoURL
												 title:title
										   description:description
											 isPrivate:isPrivate];
}

- (IBAction)viewOnFacebook:(id)sender
{
	NSURL *url = [NSURL URLWithString:[self.viewButton titleForState:UIControlStateDisabled]];
	
	[[UIApplication sharedApplication] openURL:url];
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

- (void)switchToLoginViewWithAnimation:(BOOL)animate
{
	[self temporarilyDeleteFacebookCookies];
	
	UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancel;
	[cancel release];
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.title = ESSLocalizedString(@"Login to Facebook", nil);
	
	[self.navContr popToViewController:self animated:animate];
	
	//have cancel button in the top left, no button top right.
	cancel = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancel;
	[cancel release];
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.title = ESSLocalizedString(@"Login to Facebook", nil);
	
	[self openAuthorizationURLWithAppID:self.appID];
}

- (void)openAuthorizationURLWithAppID:(NSString *)anID
{
	if (anID == nil)
	{
		if ([self.delegate respondsToSelector:@selector(facebookLogin:returnedAccessToken:expirationDate:)])
			[self.delegate facebookLogin:self returnedAccessToken:nil expirationDate:nil];
		return;
	}
	self.appID = anID;
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?client_id=%@&response_type=token&scope=publish_stream&display=touch&redirect_uri=https://www.facebook.com/connect/login_success.html",self.appID]];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
	UIWebView *webView = (UIWebView *)self.view;
	webView.delegate = self;
	[webView loadRequest:req];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	NSString *urlStr = webView.request.URL.absoluteString;
	
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

- (void)switchToUploadViewWithAnimation:(BOOL)animate
{
	UITableViewCell *cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	UITextField *videoTitleField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTitleField = (UITextField *)view;
			break;
		}
	}
	[videoTitleField resignFirstResponder];
	cell = [((UITableView *)self.infoTableViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	UITextField *videoDescField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoDescField = (UITextField *)view;
			break;
		}
	}
	[videoDescField resignFirstResponder];
	
	//have cancel button top left and upload button top right
	[self.navContr pushViewController:self.infoTableViewController animated:animate];
	[self.infoTableViewController.tableView reloadData];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
	self.infoTableViewController.navigationItem.leftBarButtonItem = button;
	[button release];
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Upload", nil) style:UIBarButtonItemStyleDone target:self action:@selector(startUpload:)];
	self.infoTableViewController.navigationItem.rightBarButtonItem = button;
	[button release];
	self.infoTableViewController.navigationItem.title = ESSLocalizedString(@"Video Info", nil);
	
	[self restoreTemporarilyDeletedFacebookCookies];
}

//table view delegate/data source methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) //user name
		return 1;
	else if (section == 1) //video info - title and description
		return 2;
	else if (section == 2) //privacy
		return 1;
	
	return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) //facebook name
		return ESSLocalizedString(@"Press to log in to a different Facebook account", nil);
	else if (section == 2) //privacy
		return ESSLocalizedString(@"Private videos can only be viewed from your account",nil);
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return ESSLocalizedString(@"Facebook User Info", nil);
	else if (section == 1)
		return ESSLocalizedString(@"VideoInfo", nil);
	else if (section == 2)
		return ESSLocalizedString(@"Privacy", nil);
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath indexAtPosition:0] == 0)
	{
		//user name cell
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"userNameCell"];
		cell.textLabel.text = ESSLocalizedString(@"Facebook Username",nil);
		cell.detailTextLabel.text = self.username;
		return [cell autorelease];
	} else if ([indexPath indexAtPosition:0] == 1)
	{
		//video info
		if ([indexPath indexAtPosition:1] == 0)
		{
			if (self.titleTVCell == nil)
				self.titleTVCell = [self customTVCellForIndexPath:indexPath];
			
			return self.titleTVCell;
		} else
		{
			if (self.descriptionTVCell == nil)
				self.descriptionTVCell = [self customTVCellForIndexPath:indexPath];
			
			return self.descriptionTVCell;
		}
	} else if ([indexPath indexAtPosition:0] == 2)
	{
		//privacy
		if (self.privacyTVCell == nil)
		{
			self.privacyTVCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"privacyCell"] autorelease];
			self.privacyTVCell.accessoryType = UITableViewCellAccessoryNone;
			self.privacyTVCell.selectionStyle = UITableViewCellSelectionStyleNone;
			self.privacyTVCell.textLabel.text = ESSLocalizedString(@"Private Video",nil);
			
			UISwitch *aSwitch = nil;
			if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
				aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(222,10,186,20)];
			else //iPad
				aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(420,10,186,20)];
			aSwitch.on = YES;
			
			[self.privacyTVCell addSubview:aSwitch];
			[aSwitch release];
		}
		
		return self.privacyTVCell;
	}
	
	return nil;
}

- (UITableViewCell *)customTVCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"videoInfoCell"];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	UITextField *editableTextField = nil;
	if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
		editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(120,11,186,22)];
	else
		editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(145,11,360,22)];
	editableTextField.adjustsFontSizeToFitWidth = YES;
	editableTextField.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
	editableTextField.backgroundColor = cell.backgroundColor;
	editableTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
	editableTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
	editableTextField.textAlignment = UITextAlignmentLeft;
	editableTextField.tag = 0;
	editableTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	editableTextField.enabled = YES;
	editableTextField.keyboardType = UIKeyboardTypeDefault;
	editableTextField.delegate = self;
	[cell addSubview:editableTextField];
	if ([indexPath indexAtPosition:1] == 0)
	{
		//title
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"Title",nil);
		editableTextField.placeholder = ESSLocalizedString(@"required", nil);
	} else
	{
		//description
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"Description",nil);
		editableTextField.placeholder = ESSLocalizedString(@"optional", nil);
	}
	[editableTextField release];
	return [cell autorelease];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{	
	[textField resignFirstResponder];
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ([indexPath indexAtPosition:0] == 0)
	{
		if ([self.delegate respondsToSelector:@selector(_deauthorize)])
			[(ESSFacebook *)self.delegate _deauthorize];
		
		[self switchToLoginViewWithAnimation:YES];
	}
}

- (void)updateUsername:(NSString *)name
{
	self.username = name;
	
	[self.infoTableViewController.tableView reloadData];
}

- (void)updateVideoTitle:(NSString *)title
{
	self.videoTitle = title;
	
	[self.infoTableViewController.tableView reloadData];
}

//upload updates
- (void)uploadStarted
{
	[self.navContr pushViewController:self.uploadingViewController animated:YES];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
	self.uploadingViewController.navigationItem.leftBarButtonItem = button;
	[button release];
	self.uploadingViewController.navigationItem.rightBarButtonItem = nil;
	self.uploadingViewController.navigationItem.title = ESSLocalizedString(@"PublishingToFacebook", nil);
	self.uploadProgressBarView.progress = 0.0;
}

- (void)uploadUpdatedWithBytes:(NSInteger)bytesUploaded ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadProgressBarView setProgress:(CGFloat)((CGFloat)bytesUploaded/(CGFloat)totalBytes) animated:YES];
	double percentDone = bytesUploaded*100/totalBytes;
	percentDone = round(percentDone);
	
	self.percentDoneField.text = [NSString stringWithFormat:ESSLocalizedString(@"ESSFacebookUploadPercentageDone", nil),(NSUInteger)percentDone];
}

- (void)uploadFinishedWithFacebookVideoURL:(NSURL *)url
{
	if (url == nil)
	{
		self.doneTextField.text = ESSLocalizedString(@"FacebookErrorUpload", nil);
		self.viewButton.hidden = YES;
	} else
	{
		self.doneTextField.text = ESSLocalizedString(@"FacebookSuccessfulUpload", nil);
		self.viewButton.hidden = NO;
	}
	
	self.viewButton.enabled = YES;
	[self.viewButton setTitle:url.absoluteString forState:UIControlStateDisabled]; //must never be disabled
	
	[self.navContr pushViewController:self.doneViewController animated:YES];
	self.doneViewController.navigationItem.title = ESSLocalizedString(@"UploadDone", nil);
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Cancel",nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
	button.enabled = NO;
	self.doneViewController.navigationItem.leftBarButtonItem = button;
	[button release];
	
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"Done",nil) style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
	self.doneViewController.navigationItem.rightBarButtonItem = button;
	[button release];
}

- (void)dealloc
{
	self.delegate = nil;
	self.appID = nil;
	self.videoURL = nil;
	self.username = nil;
	self.videoTitle = nil;
	self.temporaryCookies = nil;
	self.infoTableViewController = nil;
	self.uploadingViewController = nil;
	self.doneViewController = nil;
	self.titleTVCell = nil;
	self.descriptionTVCell = nil;
	self.privacyTVCell = nil;
	
	[super dealloc];
}

@end
