//
//  MainViewController.m
//  Lastfy
//
//  Created by Paul Kuznetsov on 07/05/15.
//  Copyright (c) 2015 Paul Kuznetsov. All rights reserved.
//

#import "MainViewController.h"
#import "LoginViewController.h"

#import "CSAnimationView.h"
#import "KLCPopup.h"

#import "SongsData.h"

#import "AppDelegate.h"

#import <MediaPlayer/MediaPlayer.h>

#import <LastFm/LastFm.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <EFCircularSlider.h>

NSString* const LastfyDidEndScrobblingNotification = @"LastfyDidEndScrobblingNotification";

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet CSAnimationView *userAvatarView;

@property (weak, nonatomic) IBOutlet UIImageView    *userAvatarImageView;
@property (weak, nonatomic) IBOutlet UILabel        *usernameLabel;
@property (strong, nonatomic) IBOutlet UIImageView    *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel        *userScrobblesLabel;
@property (weak, nonatomic) IBOutlet UIButton       *scrobbleButton;
@property (weak, nonatomic) IBOutlet UILabel        *scrobbleLabel;
@property (strong, nonatomic) IBOutlet UIView       *popupView;

@property (strong, nonatomic) EFCircularSlider          *slider;
@property (strong, nonatomic) NSManagedObjectContext    *context;
@property (strong, nonatomic) NSArray                   *mediaQuery;
@property (strong, nonatomic) NSArray                   *songsStoreInData;

- (IBAction)logOutButton:(UIButton *)sender;
- (IBAction)scrobbleButton:(UIButton *)sender;

@end

@implementation MainViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
                self.context = [appDelegate managedObjectContext];
    
    [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] objectForKey:LastFMUserSessionKey];
    self.mediaQuery = [[MPMediaQuery songsQuery] items];
    
    CGRect frame = CGRectMake(self.scrobbleButton.frame.origin.x - 5,
                              self.scrobbleButton.frame.origin.y - 5,
                              self.scrobbleButton.frame.size.width + 10,
                              self.scrobbleButton.frame.size.height + 10);
    
    self.slider = [[EFCircularSlider alloc] initWithFrame:frame];
    
    self.slider.handleColor   = [UIColor clearColor];
    self.slider.unfilledColor = [UIColor clearColor];
    self.slider.filledColor   = [UIColor colorWithWhite:1 alpha:0.5];
    self.slider.lineWidth = 5.f;
    
    //[self.view addSubview:self.slider];
    //[self.slider addTarget:self action:@selector(newValue:) forControlEvents:UIControlEventValueChanged];
    
    //self.slider.hidden = YES;
    
    //NSUserDefaults
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isFirstLaunchKey] isEqual:@0]) {
        
        
        [self initialScan];
        
        //Set "1" to user dafaults
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:isFirstLaunchKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    //popup corner radius
    self.popupView.layer.cornerRadius = 10.f;
    self.popupView.clipsToBounds = YES;
    
    //Start button pulse animation
    [self pulseAnimationForView:self.scrobbleButton animated:YES];
    
    
    //Setting up user avatar and nick
    self.userAvatarView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.f];
    
    self.usernameLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:LastFMUserLoginKey];
    
    [self.userAvatarImageView setImage:[UIImage imageNamed:@"placeholder"]];
    
    self.userAvatarImageView.clipsToBounds = YES;
    self.userAvatarImageView.layer.cornerRadius = 50.f;
    
    __weak typeof(self) weakSelf = self;
    
    //TODO: user avatar cache
    
    [[LastFm sharedInstance] getInfoForUserOrNil:[[NSUserDefaults standardUserDefaults]objectForKey:LastFMUserLoginKey]
                                  successHandler:^(NSDictionary *result) {
                                      
                                      __strong typeof(self) strongSelf = weakSelf;
                                      
                                      SDWebImageManager *manager = [SDWebImageManager sharedManager];
                                      [manager downloadImageWithURL:[result objectForKey:@"image"]
                                                            options:0
                                                           progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                            
    //TODO: progress popup window
                                                               
                                                               
                                                           }
                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                              if (image) {
                                                                  
                                                                  [strongSelf.userAvatarImageView setImage:image];
                                                                  cacheType = SDImageCacheTypeDisk;
                                                                  
                                                                  [strongSelf.userAvatarView setType:CSAnimationTypePopDown];
                                                                  [strongSelf.userAvatarView setDuration:0.4f];
                                                                  [strongSelf.userAvatarView setDelay:0.f];
                                                                  
                                                                  [strongSelf.userAvatarView startCanvasAnimation];
                                                                  
                                                              }
                                                          }];
                                      
                                      strongSelf.userScrobblesLabel.text = [NSString stringWithFormat:@"%@ tracks scrobbled", [result objectForKey:@"playcount"]];
                             
                                      
                                  }
                                  failureHandler:^(NSError *error) {
                                      
                                      NSString* errorString = [error userInfo][@"error"];
                                      NSLog(@"%@", errorString);
                                      
                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPulseAnimation)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrobblingDidFinished)
                                                 name:LastfyDidEndScrobblingNotification
                                               object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint location = [touches.anyObject locationInView:self.userAvatarImageView];
    
    if (CGRectContainsPoint(self.userAvatarImageView.bounds, location)) {
       
        self.popupView.hidden = NO;
        KLCPopup* popup = [KLCPopup popupWithContentView:self.popupView];
        
        [popup show];
    }
    
}

#pragma mark - Work with music library

- (void)initialScan {
    
    self.scrobbleLabel.text = NSLocalizedString(@"Scanning...", nil);
    
    //Analyzing whole user media library and save current state in CoreData
    for (MPMediaItem* item in self.mediaQuery) {
        
        NSNumber* playCount  = [item valueForProperty:MPMediaItemPropertyPlayCount];
        NSString* songTitle  = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString* albumTitle = [item valueForKey:MPMediaItemPropertyAlbumTitle];
        NSString* artist     = [item valueForProperty:MPMediaItemPropertyArtist];
        NSNumber* duration   = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
        
        //NSLog(@"Album %@ song %@ has: %@",albumTitle ,songTitle, playCount);
        [self saveSongDataToPersistentStoreWithArtist:artist
                                           albumTitle:albumTitle
                                            songTitle:songTitle
                                             duration:duration
                                         andPlayCount:playCount];
    }
    [self performSelector:@selector(defaultScrobbleLabelText) withObject:self afterDelay:5.f];
    
}

- (void)scanLibraryForNewPlayCount {
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"SongsData" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    NSError* requestError = nil;
    
    NSInteger scrobbleCount = 0;//var for number of the new songs to scrobble
    
    self.songsStoreInData = [self.context executeFetchRequest:fetchRequest error:&requestError];//getting all songs from CoreData
    
    if ([self.songsStoreInData count] > 0) {
        
        for (SongsData* currentSongInData in self.songsStoreInData) {
            
            MPMediaItem* currentLibrarySong = [self findItemWithArtist:currentSongInData.artist
                                                            albumTitle:currentSongInData.albumTitle
                                                             songTitle:currentSongInData.songTitle];
            if (currentLibrarySong != nil) {
                
                //NSLog(@"Song has found!");
                
                NSUInteger currentPlayCount = [[currentLibrarySong valueForProperty:MPMediaItemPropertyPlayCount]unsignedIntegerValue];
                NSUInteger storedPlayCount  = [currentSongInData.songPlayCount unsignedIntegerValue];
                
                //Save changes in playCount
                
                [currentSongInData setValue:[NSNumber numberWithUnsignedInteger:currentPlayCount] forKey:@"songPlayCount"];
                
                NSError* error = nil;
                if([self.context save:&error]) {
                    //NSLog(@"Song update: %@ - old count %d and new %d", currentSongInData.songTitle, storedPlayCount, currentPlayCount);
                }
                else {
                    //NSLog(@"error: %@", error);
                }
                
                //NSLog(@"Stored play count: %lu new: %lu", (unsigned long)storedPlayCount, (unsigned long)currentPlayCount);
                
                if (storedPlayCount < currentPlayCount) {
                    
                    currentPlayCount -= storedPlayCount;
                    
                    NSNumber* playCount = [NSNumber numberWithUnsignedInteger:currentPlayCount];
                    
                    [self scrobbleTrackWithArtist:currentSongInData.artist
                                       albumTitle:currentSongInData.albumTitle
                                        songTitle:currentSongInData.songTitle
                                         duration:currentSongInData.duration
                                     andPlayCount:playCount];
                    
                    scrobbleCount++;
                    
                }
            }
            
        }
    }
    else {
        NSLog(@"Could not find any SongsData entity in context");
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LastfyDidEndScrobblingNotification object:nil];
    
    self.scrobbleLabel.text = [NSString stringWithFormat:@"Found %ld scrobbles", (long)scrobbleCount];
    
    [self pulseAnimationForView:self.scrobbleButton animated:YES];
    
    scrobbleCount = 0;
    
}

- (MPMediaItem *)findItemWithArtist:(NSString *)artist albumTitle:(NSString *)album songTitle:(NSString *)song {
    
    MPMediaPropertyPredicate* artistPredicate = [MPMediaPropertyPredicate predicateWithValue:artist
                                                                                 forProperty:MPMediaItemPropertyArtist
                                                                              comparisonType:MPMediaPredicateComparisonContains];
    
    MPMediaPropertyPredicate* albumPredicate = [MPMediaPropertyPredicate predicateWithValue:album
                                                                                forProperty:MPMediaItemPropertyAlbumTitle
                                                                             comparisonType:MPMediaPredicateComparisonContains];
    
    MPMediaPropertyPredicate* songPredicate = [MPMediaPropertyPredicate predicateWithValue:song
                                                                               forProperty:MPMediaItemPropertyTitle
                                                                            comparisonType:MPMediaPredicateComparisonContains];
    
    NSSet* predicates = [NSSet setWithObjects:artistPredicate, albumPredicate, songPredicate, nil];
    
    MPMediaQuery* songQuery = [[MPMediaQuery alloc] initWithFilterPredicates:predicates];
    
    NSArray* songsArr = [songQuery items];
    
    if ([songsArr count] == 1) {
        return songsArr[0];
    }
    
    return nil;
}


#pragma mark - Data operations

- (void)saveSongDataToPersistentStoreWithArtist:(NSString *)artist albumTitle:(NSString *)album
                                      songTitle:(NSString *)song duration:(NSNumber *)duration
                                   andPlayCount:(NSNumber *)playCount {
   
    SongsData* newSong = [NSEntityDescription insertNewObjectForEntityForName:@"SongsData"
                                                       inManagedObjectContext:self.context];
    
    if (newSong == nil) {
        NSLog(@"Error creating new SongsData");
    }
    
    newSong.artist        = artist;
    newSong.albumTitle    = album;
    newSong.songTitle     = song;
    newSong.duration      = duration;
    newSong.songPlayCount = playCount;
    
    NSError* savingError = nil;
    
    if (![self.context save:&savingError]) {
        NSLog(@"%@",savingError);
    }
    
}

#pragma mark - Scrobbling

- (void)scrobbleTrackWithArtist:(NSString *)artist albumTitle:(NSString *)album
                       songTitle:(NSString *)song duration:(NSNumber *)duration
                                              andPlayCount:(NSNumber *)playCount {
    
   
        [[LastFm sharedInstance] sendScrobbledTrack:song
                                           byArtist:artist
                                            onAlbum:album
                                       withDuration:[duration floatValue]
                                        atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
                                     successHandler:^(NSDictionary *result) {
                                     
                                         NSLog(@"result: %@", result);
                                     }
                                     failureHandler:^(NSError *error) {
                                     
                                         NSLog(@"error: %@", error);
                                     }];
    
}

#pragma mark - Actions
//TODO: Alert View for logout button
- (IBAction)logOutButton:(UIButton *)sender {
    
    [[LastFm sharedInstance] logout];
    
    [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:isFirstLaunchKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [KLCPopup dismissAllPopups];
    [self performSegueWithIdentifier:@"logoutToLoginVCSegue" sender:self];
}

- (IBAction)scrobbleButton:(UIButton *)sender {
    
    [self pulseAnimationForView:self.scrobbleButton animated:NO];
    
    self.scrobbleLabel.text = @"Searching...";
    
    self.mediaQuery = [[MPMediaQuery songsQuery] items];
    
    [self performSelectorInBackground:@selector(scanLibraryForNewPlayCount) withObject:nil];
}

#pragma mark - Animation

- (void)pulseAnimationForView:(UIView *)view animated:(BOOL)animated {
    
    //Pulse animation
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    theAnimation.duration     = 0.9f;
    theAnimation.repeatCount  = HUGE_VALF;
    theAnimation.autoreverses = YES;
    
    theAnimation.fromValue = [NSNumber numberWithFloat: 1.0f];
    theAnimation.toValue   = [NSNumber numberWithFloat: 1.05f];
    
    if (animated) {
       
        [view.layer addAnimation:theAnimation forKey:@"animateOpacity"];
        
    }
    else {
        
        [view.layer removeAnimationForKey:@"animateOpacity"];
    }
    
}

- (void)startPulseAnimation {
    
    [self pulseAnimationForView:self.scrobbleButton animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

#pragma mark - Helpers

- (void)defaultScrobbleLabelText {
    
    self.scrobbleLabel.text = @"Touch to Scrobble";
}

- (void)scrobblingDidFinished {
    
    [self performSelector:@selector(defaultScrobbleLabelText) withObject:nil afterDelay:13.f];;
    
}

@end
