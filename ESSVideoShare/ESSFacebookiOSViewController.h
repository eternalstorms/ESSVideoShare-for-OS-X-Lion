//
//  ESSFacebookiOSViewController.h
//  ESSVideoShare
//
//  Created by Matthias Gansrigler on 24.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESSFacebookiOSViewController;

@protocol ESSFacebookiOSViewControllerDelegate <NSObject>

@required
- (void)facebookLogin:(ESSFacebookiOSViewController *)login returnedAccessToken:(NSString *)token expirationDate:(NSDate *)expDate;

@end

@interface ESSFacebookiOSViewController : UIViewController <UIWebViewDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (assign) id delegate;

@property (retain) NSString *appID;
@property (retain) NSURL *videoURL;

@property (retain) NSString *username;
@property (retain) NSString *videoTitle;

@property (retain) NSMutableArray *temporaryCookies;

@property (retain) UINavigationController *navContr;

@property (retain) IBOutlet UITableViewController *infoTableViewController;

@property (retain) IBOutlet UIViewController *uploadingViewController;
@property (assign) IBOutlet UIProgressView *uploadProgressBarView;
@property (assign) IBOutlet UILabel *percentDoneField;

@property (retain) IBOutlet UIViewController *doneViewController;
@property (assign) IBOutlet UIImageView *doneImageView;
@property (assign) IBOutlet UILabel *doneTextField;
@property (assign) IBOutlet UIButton *viewButton;

- (id)initWithDelegate:(id)del appID:(NSString *)someID videoURL:(NSURL *)url;

- (void)openAuthorizationURLWithAppID:(NSString *)anID;

- (void)cancel:(id)sender;
- (void)changeAccount:(id)sender;
- (void)startUpload:(id)sender;
- (IBAction)viewOnFacebook:(id)sender;

- (void)switchToLoginViewWithAnimation:(BOOL)animate; //shows uiwebview
- (void)switchToUploadViewWithAnimation:(BOOL)animate; //shows infoTableView

- (void)updateUsername:(NSString *)name;
- (void)updateVideoTitle:(NSString *)title;

- (void)temporarilyDeleteFacebookCookies;
- (void)restoreTemporarilyDeletedFacebookCookies;

- (void)uploadStarted;
- (void)uploadUpdatedWithBytes:(NSInteger)bytesUploaded ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithFacebookVideoURL:(NSURL *)url;

@end
