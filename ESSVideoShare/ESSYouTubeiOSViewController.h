//
//  ESSYouTubeiOSViewController.h
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 27.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESSYouTubeiOSViewController;

@protocol ESSYouTubeiOSViewControllerDelegate <NSObject>

@required
- (void)youtubeiOSViewControllerDidDismiss:(ESSYouTubeiOSViewController *)ytVCtr;

@end

@interface ESSYouTubeiOSViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UIActionSheetDelegate,UIPopoverControllerDelegate>

@property (assign) id delegate;
@property (retain) NSURL *videoURL;
@property (retain) NSString *username;
@property (retain) NSDictionary *categoriesDict;

@property (retain) UITableViewCell *titleTVCell;
@property (retain) UITableViewCell *categoryTVCell;
@property (retain) UITableViewCell *descriptionTVCell;
@property (retain) UITableViewCell *tagsTVCell;
@property (retain) UITableViewCell *privacyTVCell;

@property (retain) UIPickerView *picker;

@property (retain) UINavigationController *navContr;

@property (retain) IBOutlet UITableViewController *videoInfoViewController;

@property (retain) IBOutlet UIViewController *termsViewController;

@property (retain) IBOutlet UIViewController *uploadingViewController;
@property (assign) IBOutlet UIProgressView *uploadProgressView;
@property (assign) IBOutlet UILabel *uploadLabel;

@property (retain) IBOutlet UIViewController *doneViewController;
@property (assign) IBOutlet UIImageView *doneImageView;
@property (assign) IBOutlet UILabel *doneLabel;
@property (assign) IBOutlet UIButton *viewButton;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url;

- (void)cancel;
- (void)login:(id)sender;
- (void)beginUploadProcess;
- (void)startUpload;
- (void)uploadStarted;

- (void)updateUsername:(NSString *)name;
- (void)updateCategories:(NSDictionary *)dict;

- (void)resetLoginInfo; //used when login fails, enable login button

- (IBAction)showOnYouTube:(id)sender;

- (void)switchToLoginViewWithAnimation:(BOOL)animate;
- (void)switchToInfoViewWithAnimation:(BOOL)animate;

- (UITableViewCell *)customTVCellForIndexPath:(NSIndexPath *)indexPath;

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithYouTubeVideoURL:(NSURL *)url;

@end
