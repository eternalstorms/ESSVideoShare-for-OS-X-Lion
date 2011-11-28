# ESSVideoShare.framework for OS X Lion ReadMe

## What is ESSVideoShare.framework?

ESSVideoShare.framework makes it very easy and quick to add uploading functionality for videos to these services:  
[YouTube](http://www.youtube.com), [Vimeo](http://www.vimeo.com), [Facebook](http://www.facebook.com) and [Flickr](http://www.flickr.com).

It was inspired by QuickTime Player X's sharing functionality.

## First, the License Agreement

1) You can use the code in your own products.  
2) You can modify the code as you wish, and use the modified code in your products.  
3) You can redistribute the original, unmodified code, but you have to include the full license text below.  
4) You can redistribute the modified code as you wish (without the full license text below).  
5) In all cases, you must include a credit mentioning Matthias Gansrigler as the original author of the source.  
6) I’m not liable for anything you do with the code, no matter what. So be sensible.  
7) You can’t use my name or other marks to promote your products based on the code.  
8) This framework uses the OAuthConsumer framework code which you can separately download from http://code.google.com/p/oauthconsumer/ which is made available under the MIT License.  
9) If you agree to all of that, go ahead and download the source. Otherwise, don’t.  

## How To Use ESSVideoShare.framework

1) In your project  

    #import <ESSVideoShare/ESSVideoShare.h>  
2) Make sure you copy the ESSVideoShare framework to your app bundle's framework folder in a build copy phase

Before you can start uploading to [YouTube](http://www.youtube.com), [Vimeo](http://www.vimeo.com), [Facebook](http://www.facebook.com) and [Flickr](http://www.flickr.com), you'll have to get API access for each service you'd like to use.  

### Links to get API Access to YouTube, Vimeo, Facebook and Flickr
[YouTube API Access](http://code.google.com/apis/youtube/dashboard/gwt/)

[Vimeo API Access](http://vimeo.com/api/applications/new) - Link only works when already logged in to Vimeo

[Facebook API Access](https://developers.facebook.com/apps)

[Flickr API Access](http://www.flickr.com/services/apps/create/apply/?)

## The Code

Once you have the appropriate API keys for the services you'd like to use, you can start using ESSVideoShare.framework.  

There are four classes you can use:  

    ESSYouTube
    ESSVimeo
    ESSFacebook
    ESSFlickr

---

### ESSYouTube

Initialize a ESSYouTube object  

    id delegate = self;
    NSString *youTubeAPIKey = @"yourAPIKey";
    ESSYouTube *youTube = [[ESSYouTube alloc] initWithDelegate:delegate
													developerKey:youTubeAPIKey];

Now on to implementing the delegate methods. There are two:

    - (NSWindow *)ESSYouTubeNeedsWindowToAttachTo:(ESSYouTube *)youtube
    {
	    //ESSYouTube will show a window as a sheet, attached to the window you return here.
	    //Not returning a window might result in unexpected behavior.
        return self.window;
    }

and

    - (void)ESSYouTubeDidFinish:(ESSYouTube *)youtube
    {
	    //this gets called whenever the user clicks on Cancel
        //it is also called when the user clicks on Done after the upload has finished.
        //usually, what you want to do here is just autorelease youtube if you don't keep a pointer to the youtube object yourself
        [youtube autorelease];
    }

Once you've implemented the delegate methods, you can finally start an upload session:

    NSURL *urlToVideoOnHardDisk = [NSURL fileURLWithPath:@"/path/to/the/video.mp4"];
    [youTube uploadVideoAtURL:urlToVideoOnHardDisk];

That's it. The rest is done by the framework and the user.  
In a similar fashion, we'll continue

### ESSVimeo
Initialize the ESSVimeo object  

    id delegate = self;
    NSString *vimeoAPIKey = @"yourVimeoAPIKey";
    NSString *vimeoAPISecret = @"yourVimeoAPISecret";
    ESSVimeo *vimeo = [[ESSVimeo alloc] initWithAPIKey:vimeoAPIKey
													secret:vimeoAPISecret
									   canUploadToPlusOnly:NO
												  delegate:delegate];
												
Something you will notice is the BOOL you have to pass into canUploadToPlusOnly:. If your API key can only upload for users who have Vimeo PLUS accounts, pass YES. If your API key can upload to free Vimeo accounts as well, pass NO.

Again, implement the necessary delegate methods, which are pretty much the same as for YouTube:

    - (NSWindow *)ESSVimeoNeedsWindowToAttachWindowTo:(ESSVimeo *)uploader
	{
		//ESSVimeo will show a window as a sheet, attached to the window you return here.
	    //Not returning a window might result in unexpected behavior.
		return self.window;
	}  
	
and  

	- (void)ESSVimeoFinished:(ESSVimeo *)uploader
	{
		//this gets called whenever the user clicks on Cancel
        //it is also called when the user clicks on Done after the upload has finished.
        //usually, what you want to do here is just autorelease youtube if you don't keep a pointer to the vimeo object yourself
		[uploader autorelease];
	}

And to start the upload session:  

    NSURL *urlToVideoOnHardDisk = [NSURL fileURLWithPath:@"/path/to/the/video.mp4"];
    [vimeo uploadVideoAtURL:urlToVideoOnHardDisk];

That's it. The rest is taken care of by the framework and the user.  
Let's continue with

### ESSFacebook

By now, I think you get the hang of it:  

    id delegate = self;
    NSString *facebookAppID = @"yourFacebookAppID";
    NSString *facebookAppSecret = @"yourFacebookAppSecret";
    ESSFacebook *facebook = [[ESSFacebook alloc] initWithDelegate:delegate appID:facebookAppID appSecret:facebookAppSecret];

Implement the two delegate methods:

    - (NSWindow *)ESSFacebookNeedsWindowToAttachTo:(ESSFacebook *)facebook
	{
		//ESSFacebook will show a window as a sheet, attached to the window you return here.
	    //Not returning a window might result in unexpected behavior.
		return self.window;
	}

	- (void)ESSFacebookDidFinish:(ESSFacebook *)fb
	{
		//this gets called whenever the user clicks on Cancel
        //it is also called when the user clicks on Done after the upload has finished.
        //usually, what you want to do here is just autorelease youtube if you don't keep a pointer to the facebook object yourself
		[fb autorelease];
	}
	
And to start the upload session:  

    NSURL *urlToVideoOnHardDisk = [NSURL fileURLWithPath:@"/path/to/the/video.mp4"];
    [facebook uploadVideoAtURL:urlToVideoOnHardDisk];

As before, the rest is taken care of by the framework and the user.

On to the last part:
### ESSFlickr

Initialize the object:

    id delegate = self;
    NSString *flickrAppKey = @"yourFlickrAppKey";
    NSString *flickrAppSecret = @"yourFlickrAppSecret";
    ESSFlickr *flickr = [[ESSFlickr alloc] initWithDelegate:self applicationKey:flickrAppKey applicationSecret:flickrAppSecret];

Implement the delegate methods:

    - (NSWindow *)ESSFlickrNeedsWindowToAttachTo:(ESSFlickr *)flickr
	{
		//ESSFacebook will show a window as a sheet, attached to the window you return here.
	    //Not returning a window might result in unexpected behavior.
		return self.window;
	}

and

	- (void)ESSFlickrDidFinish:(ESSFlickr *)flickr
	{
		//this gets called whenever the user clicks on Cancel
        //it is also called when the user clicks on Done after the upload has finished.
        //usually, what you want to do here is just autorelease youtube if you don't keep a pointer to the flickr object yourself
		[flickr autorelease];
	}
	
And start the upload session like so:

    NSURL *urlToVideoOnHardDisk = [NSURL fileURLWithPath:@"/path/to/the/video.mp4"];
    [flickr uploadVideoAtURL:urlToVideoOnHardDisk];

# ESSVideoShare in Action

## ESSYouTube

![Login](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/1.png "Login")  
![Meta Data](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/2.png "Movie meta data")  
![Terms of Use](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/3.png "Terms of Use")  
![Upload Progress](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/4.png "Upload progress")  
![Waiting For Processing](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/5.png "Waiting for Processing")  
![Done](http://www.eternalstorms.at/opensource/ESSVideoShare/youtube/6.png "Done")  

## ESSVimeo

![Login](http://www.eternalstorms.at/opensource/ESSVideoShare/vimeo/1.png "Login")  
![Meta Data](http://www.eternalstorms.at/opensource/ESSVideoShare/vimeo/2.png "Movie meta data")  
![Terms of Use](http://www.eternalstorms.at/opensource/ESSVideoShare/vimeo/3.png "Terms of Use")  
![Upload Progress](http://www.eternalstorms.at/opensource/ESSVideoShare/vimeo/4.png "Upload progress")  
![Done](http://www.eternalstorms.at/opensource/ESSVideoShare/vimeo/5.png "Done")  

## ESSFacebook

![Login](http://www.eternalstorms.at/opensource/ESSVideoShare/facebook/1.png "Login")  
![Confirm Login](http://www.eternalstorms.at/opensource/ESSVideoShare/facebook/2.png "Confirm Login")  
![Movie Metadata](http://www.eternalstorms.at/opensource/ESSVideoShare/facebook/3.png "Movie metadata")  
![Upload Progress](http://www.eternalstorms.at/opensource/ESSVideoShare/facebook/4.png "Upload progress")  
![Done](http://www.eternalstorms.at/opensource/ESSVideoShare/facebook/5.png "Done")  

## ESSFlickr

![Login](http://www.eternalstorms.at/opensource/ESSVideoShare/flickr/1.png "Login")  
![Movie metadata](http://www.eternalstorms.at/opensource/ESSVideoShare/flickr/2.png "Movie metadata")  
![Upload Progress](http://www.eternalstorms.at/opensource/ESSVideoShare/flickr/3.png "Movie metadata")  
![Waiting for Processing](http://www.eternalstorms.at/opensource/ESSVideoShare/flickr/4.png "Waiting for Processing")  
![Done](http://www.eternalstorms.at/opensource/ESSVideoShare/flickr/5.png "Done")

## Requirements
This code works on OS X Lion and later.

## Support
The framework and code is provided as-is, but if you need help or have suggestions, you can contact me anytime at [opensource@eternalstorms.at](mailto:opensource@eternalstorms.at)