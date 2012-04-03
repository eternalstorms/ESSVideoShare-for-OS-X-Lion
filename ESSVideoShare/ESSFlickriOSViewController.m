//
//  ESSFlickriOSViewController.m
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 31.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import "ESSFlickriOSViewController.h"
#import "ESSFlickr.h"

@interface ESSFlickriOSViewController ()

@end

@implementation ESSFlickriOSViewController

@synthesize delegate,videoURL,navCtr,username,videoInfoViewController,uploadingViewController,uploadingLabel,uploadingProgressView,doneViewController,doneImageView,doneLabel,doneButton,
titleTVCell,descriptionTVCell,tagsTVCell,privacyTVCell;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url
{
	NSString *nibName = @"ESSFlickriOSView_iPhone";
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		nibName = @"ESSFlickriOSView_iPad";
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.videoInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.uploadingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.doneViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	if (self = [super initWithNibName:nibName bundle:nil])
	{
		self.delegate = del;
		self.videoURL = url;
		
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

- (IBAction)showOnFlickr:(id)sender
{
	NSURL *url = [NSURL URLWithString:[(UIButton *)sender titleForState:UIControlStateDisabled]];
	
	[[UIApplication sharedApplication] openURL:url];
}

- (void)updateUsername:(NSString *)name
{
	self.username = name;
	
	//update videoinfotableview with username
	[(UITableView *)self.videoInfoViewController.view reloadData];
}

//table view delegate/data source methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) //user name
		return 1;
	else if (section == 1) //video info - title and description
		return 3;
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
	if (section == 0) //flickr name
		return ESSLocalizedString(@"ESSFlickriOSAccountInfoFooter", nil);
	else if (section == 1) //video info
		return ESSLocalizedString(@"ESSFlickriOSVideoInfoTagFooter",nil);
	else if (section == 2) //privacy
		return ESSLocalizedString(@"ESSFlickriOSPrivacyInfoFooter",nil);
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return ESSLocalizedString(@"ESSFlickriOSAccountInfoHeader", nil);
	else if (section == 1)
		return ESSLocalizedString(@"ESSFlickriOSVideoInfoHeader", nil);
	else if (section == 2)
		return ESSLocalizedString(@"ESSFlickriOSPrivacyHeader", nil);
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath indexAtPosition:0] == 0)
	{
		//user name cell
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"userNameCell"];
		cell.textLabel.text = ESSLocalizedString(@"ESSFlickriOSUsernameTVCellTitle",nil);
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
		} else if ([indexPath indexAtPosition:1] == 1)
		{
			if (self.descriptionTVCell == nil)
				self.descriptionTVCell = [self customTVCellForIndexPath:indexPath];
			
			return self.descriptionTVCell;
		} else
		{
			if (self.tagsTVCell == nil)
				self.tagsTVCell = [self customTVCellForIndexPath:indexPath];
			
			return self.tagsTVCell;
		}
	} else if ([indexPath indexAtPosition:0] == 2)
	{
		//privacy
		if (self.privacyTVCell == nil)
		{
			self.privacyTVCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"privacyCell"] autorelease];
			self.privacyTVCell.accessoryType = UITableViewCellAccessoryNone;
			self.privacyTVCell.selectionStyle = UITableViewCellSelectionStyleNone;
			self.privacyTVCell.textLabel.text = ESSLocalizedString(@"ESSFlickriOSPrivateVideoTVCellTitle",nil);
			
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
		cell.textLabel.text = ESSLocalizedString(@"ESSFlickriOSTitleTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSFlickriOSRequiredCellTitle", nil);
	} else if ([indexPath indexAtPosition:1] == 1)
	{
		//description
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"ESSFlickriOSDescriptionTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSFlickriOSOptionalCellTitle", nil);
	} else
	{
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"ESSFlickriOSTagsTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSFlickriOSOptionalCellTitle", nil);
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
			[(ESSFlickr *)self.delegate _deauthorize];
		
		[self switchToLoginViewWithAnimation:YES];
	}
}

- (void)switchToLoginViewWithAnimation:(BOOL)animate
{
	[self.navCtr popToViewController:self animated:animate];
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSLogin", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(login:)];
	self.navigationItem.rightBarButtonItem = btn;
	[btn release];
	self.navigationItem.title = @"Flickr";
}

- (void)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(flickrDidCancel:)])
		[self.delegate flickrDidCancel:self];
}

- (void)login:(id)sender
{
	self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[(ESSFlickr *)self.delegate _authorize];
}
- (void)switchToUploadViewWithAnimation:(BOOL)animate
{
	[self.navCtr pushViewController:self.videoInfoViewController animated:animate];
	UIViewController *crCtr = self.videoInfoViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSUpload", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(startUpload:)];
	crCtr.navigationItem.rightBarButtonItem = btn;
	[btn release];
	crCtr.title = @"Flickr";
}

- (void)startUpload:(id)sender
{	
	UITableViewCell *cell = self.titleTVCell;
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
	
	cell = self.descriptionTVCell;
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
	
	if (description.length == 0)
	{
		[videoDescField becomeFirstResponder];
		return;
	}
	
	cell = self.tagsTVCell;
	UITextField *videoTags = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTags = (UITextField *)view;
			break;
		}
	}
	[videoTags resignFirstResponder];
	NSString *tags = videoTags.text;
	
	if (tags.length == 0)
	{
		[videoTags becomeFirstResponder];
		return;
	}
	
	cell = [((UITableView *)self.videoInfoViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
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
	
	[(ESSFlickr *)self.delegate _uploadVideoAtURL:self.videoURL
											title:title
									  description:description
											 tags:tags
									  makePrivate:isPrivate];
}

- (void)uploadStarted
{
	self.uploadingProgressView.progress = 0.0;
	[self.navCtr pushViewController:self.uploadingViewController animated:YES];
	UIViewController *crCtr = self.uploadingViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	crCtr.navigationItem.rightBarButtonItem = nil;
}

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadingProgressView setProgress:(CGFloat)((CGFloat)uploadedBytes/(CGFloat)totalBytes) animated:YES];
	double percentDone = uploadedBytes*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadingLabel.text = [NSString stringWithFormat:ESSLocalizedString(@"ESSFlickrUploadPercentageDone", nil),(NSUInteger)percentDone];
	
	if (uploadedBytes == totalBytes)
		self.uploadingLabel.text = ESSLocalizedString(@"ESSFlickrWaitingForFlickrToVerifyVideo", nil);
}

- (void)uploadFinishedWithURL:(NSURL *)url
{
	if (url == nil)
	{
		//upload failed
		self.doneLabel.text = ESSLocalizedString(@"ESSFlickrUploadFailed", nil);
		[self.doneButton setTitle:nil forState:UIControlStateDisabled];
	} else
	{
		self.doneLabel.text = ESSLocalizedString(@"ESSFlickrUploadSucceeded", nil);
		[self.doneButton setTitle:url.absoluteString forState:UIControlStateDisabled];
	}
	
	[self.navCtr pushViewController:self.doneViewController animated:YES];
	UIViewController *crCtr = self.doneViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSFlickriOSDone", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(cancel:)];
	crCtr.navigationItem.rightBarButtonItem = btn;
	[btn release];
}

- (void)dealloc
{
	self.delegate = nil;
	self.videoURL = nil;
	self.navCtr = nil;
	self.username = nil;
	self.videoInfoViewController = nil;
	self.uploadingViewController = nil;
	self.doneViewController = nil;
	self.titleTVCell = nil;
	self.descriptionTVCell = nil;
	self.tagsTVCell = nil;
	self.privacyTVCell = nil;
	
	[super dealloc];
}

@end
