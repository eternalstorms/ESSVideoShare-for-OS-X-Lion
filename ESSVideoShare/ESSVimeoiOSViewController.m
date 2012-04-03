//
//  ESSVimeoiOSViewController.m
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 29.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import "ESSVimeoiOSViewController.h"
#import "ESSVimeo.h"

@interface ESSVimeoiOSViewController ()

@end

@implementation ESSVimeoiOSViewController

@synthesize delegate,videoURL,navCtr,username,videoInfoViewController,warningViewController,warningImageView,warningLabel,termsViewController,uploadingViewController,uploadingLabel,uploadingProgressView,doneViewController,doneImageView,doneLabel,doneButton,titleTVCell,descriptionTVCell,tagsTVCell,privacyTVCell;

- (id)initWithVideoURL:(NSURL *)url delegate:(id)del
{
	NSString *nibName = @"ESSVimeoiOSView_iPhone";
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		nibName = @"ESSVimeoiOSView_iPad";
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.videoInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.warningViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.termsViewController.modalPresentationStyle = UIModalPresentationFormSheet;
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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)switchToLoginViewWithAnimation:(BOOL)animate
{
	[self.navCtr popToViewController:self animated:animate];
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSLogin", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(login:)];
	self.navigationItem.rightBarButtonItem = btn;
	[btn release];
	self.navigationItem.title = @"Vimeo";
}

- (void)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(vimeoIsFinished:)])
		[self.delegate vimeoIsFinished:self];
}

- (void)login:(id)sender
{
	self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[(ESSVimeo *)self.delegate _startAuthorization];
}

- (void)resetLoginView
{
	double delayInSeconds = 0.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		self.navigationItem.leftBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem.enabled = YES;
	});
}

- (void)switchToUploadViewWithAnimation:(BOOL)animate
{
	[self.navCtr pushViewController:self.videoInfoViewController animated:animate];
	UIViewController *crCtr = self.videoInfoViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSUpload", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(showTerms:)];
	crCtr.navigationItem.rightBarButtonItem = btn;
	[btn release];
	crCtr.title = @"Vimeo";
}

- (void)showTerms:(id)sender
{
	//only if title is set.
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
	
	[self.navCtr pushViewController:self.termsViewController animated:YES];
	
	UIViewController *crCtr = self.termsViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSUpload", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(startUpload:)];
	crCtr.navigationItem.rightBarButtonItem = btn;
	[btn release];
	crCtr.title = @"Vimeo";
}

- (void)showNoSpaceLeftWarning
{
	self.warningLabel.text = ESSLocalizedString(@"ESSVimeoiOSNoSpaceWarning", nil);
	[self.navCtr pushViewController:self.warningViewController animated:YES];
	
	UIViewController *crCtr = self.videoInfoViewController;
	
	crCtr.title = @"Vimeo";
}

- (void)showNoPlusAccountWarning
{
	self.warningLabel.text = ESSLocalizedString(@"ESSVimeoiOSNoPlusAccountWarning", nil);
	[self.navCtr pushViewController:self.warningViewController animated:YES];
	
	UIViewController *crCtr = self.videoInfoViewController;
	
	crCtr.title = @"Vimeo";
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
	
	[(ESSVimeo *)self.delegate _uploadVideoAtURL:self.videoURL
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
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	crCtr.navigationItem.rightBarButtonItem = nil;
}

- (void)updateUsername:(NSString *)name
{
	self.username = name;
	
	//update videoinfotableview with username
	[(UITableView *)self.videoInfoViewController.view reloadData];
}

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadingProgressView setProgress:(CGFloat)((CGFloat)uploadedBytes/(CGFloat)totalBytes) animated:YES];
	double percentDone = uploadedBytes*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadingLabel.text = [NSString stringWithFormat:ESSLocalizedString(@"ESSVimeoUploadPercentageDone", nil),(NSUInteger)percentDone];
	
	if (uploadedBytes == totalBytes)
		self.uploadingLabel.text = ESSLocalizedString(@"ESSVimeoWaitingForVimeoToVerifyVideo", nil);
}

- (void)uploadFinishedWithURL:(NSURL *)url
{
	if (url == nil)
	{
		//upload failed
		self.doneLabel.text = ESSLocalizedString(@"ESSVimeoUploadFailed", nil);
		[self.doneButton setTitle:nil forState:UIControlStateDisabled];
	} else
	{
		self.doneLabel.text = ESSLocalizedString(@"ESSVimeoUploadSucceeded", nil);
		[self.doneButton setTitle:url.absoluteString forState:UIControlStateDisabled];
	}
	
	[self.navCtr pushViewController:self.doneViewController animated:YES];
	UIViewController *crCtr = self.doneViewController;
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSCancel", nil)
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(cancel:)];
	crCtr.navigationItem.leftBarButtonItem = btn;
	[btn release];
	btn = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSVimeoiOSDone", nil)
										   style:UIBarButtonItemStyleDone
										  target:self
										  action:@selector(cancel:)];
	crCtr.navigationItem.rightBarButtonItem = btn;
	[btn release];
}

- (IBAction)showOnVimeo:(id)sender
{
	NSURL *url = [NSURL URLWithString:[(UIButton *)sender titleForState:UIControlStateDisabled]];
	
	[[UIApplication sharedApplication] openURL:url];
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
	if (section == 0) //facebook name
		return ESSLocalizedString(@"ESSVimeoiOSAccountInfoFooter", nil);
	else if (section == 1) //video info
		return ESSLocalizedString(@"ESSVimeoiOSVideoInfoTagFooter",nil);
	else if (section == 2) //privacy
		return ESSLocalizedString(@"ESSVimeoiOSPrivacyInfoFooter",nil);
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return ESSLocalizedString(@"ESSVimeoiOSAccountInfoHeader", nil);
	else if (section == 1)
		return ESSLocalizedString(@"ESSVimeoiOSVideoInfoHeader", nil);
	else if (section == 2)
		return ESSLocalizedString(@"ESSVimeoiOSPrivacyHeader", nil);
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath indexAtPosition:0] == 0)
	{
		//user name cell
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"userNameCell"];
		cell.textLabel.text = ESSLocalizedString(@"ESSVimeoiOSUsernameTVCellTitle",nil);
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
			self.privacyTVCell.textLabel.text = ESSLocalizedString(@"ESSVimeoiOSPrivateVideoTVCellTitle",nil);
			
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
		cell.textLabel.text = ESSLocalizedString(@"ESSVimeoiOSTitleTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSVimeoiOSRequiredCellTitle", nil);
	} else if ([indexPath indexAtPosition:1] == 1)
	{
		//description
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"ESSVimeoiOSDescriptionTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSVimeoiOSOptionalCellTitle", nil);
	} else
	{
		editableTextField.returnKeyType = UIReturnKeyDone;
		cell.textLabel.text = ESSLocalizedString(@"ESSVimeoiOSTagsTVCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"ESSVimeoiOSOptionalCellTitle", nil);
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
			[(ESSVimeo *)self.delegate _deauthorize];
		
		[self switchToLoginViewWithAnimation:YES];
	}
}

- (void)dealloc
{
	self.delegate = nil;
	self.videoURL = nil;
	self.navCtr = nil;
	self.username = nil;
	self.videoInfoViewController = nil;
	self.warningViewController = nil;
	self.termsViewController = nil;
	self.uploadingViewController = nil;
	self.doneViewController = nil;
	
	[super dealloc];
}

@end
