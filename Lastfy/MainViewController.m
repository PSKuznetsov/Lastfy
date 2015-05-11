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

#import "SongsData.h"

#import "AppDelegate.h"

#import <MediaPlayer/MediaPlayer.h>

#import <LastFm/LastFm.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet CSAnimationView *userAvatarView;
@property (weak, nonatomic) IBOutlet UIImageView *userAvatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSArray* mediaQuery;
@property (strong, nonatomic) NSArray* songsStoreInData;

- (IBAction)logOutButton:(UIButton *)sender;
- (IBAction)scrobbleButton:(UIButton *)sender;

@end

@implementation MainViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate* appDelegate        = [[UIApplication sharedApplication] delegate];
    [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] objectForKey:LastFMUserSessionKey];
    
    self.context    = [appDelegate managedObjectContext];
    self.mediaQuery = [[MPMediaQuery songsQuery] items];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isFirstLaunchKey] isEqual:@0]) {
        
        [self initialScan];
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:isFirstLaunchKey];
        
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.userAvatarView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.f];
    
    __weak typeof(self) weakSelf = self;
    
    //TODO: set user avatar outside the block(couse of animation bug);
    
    [[LastFm sharedInstance] getInfoForUserOrNil:[[NSUserDefaults standardUserDefaults]objectForKey:LastFMUserLoginKey]
                                  successHandler:^(NSDictionary *result) {
                                      
                                      __strong typeof(self) strongSelf = weakSelf;
                                      
                                      [strongSelf.userAvatarImageView sd_setImageWithURL:[result objectForKey:@"image"]];
                                      
                                      strongSelf.userAvatarImageView.layer.cornerRadius = 50.f;
                                      strongSelf.userAvatarImageView.clipsToBounds = YES;
                                      
                                      strongSelf.usernameLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:LastFMUserLoginKey];
                                      
                                      //Setting Up Canvas animation for view
                                      
                                      [strongSelf.userAvatarView setType:CSAnimationTypePopDown];
                                      [strongSelf.userAvatarView setDuration:0.3f];
                                      [strongSelf.userAvatarView setDelay:0.f];
                                      
                                      [strongSelf.userAvatarView startCanvasAnimation];
                                      
                                  }
                                  failureHandler:^(NSError *error) {
                                      
                                      NSString* errorString = [error userInfo][@"error"];
                                      NSLog(@"%@", errorString);
                                      
                                  }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

#pragma mark - Work with music library

- (void)initialScan {
    
    for (MPMediaItem* item in self.mediaQuery) {
        
        NSNumber* playCount  = [item valueForProperty:MPMediaItemPropertyPlayCount];
        NSString* songTitle  = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString* albumTitle = [item valueForKey:MPMediaItemPropertyAlbumTitle];
        NSString* artist     = [item valueForProperty:MPMediaItemPropertyArtist];
        NSNumber* duration   = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
        
        //NSLog(@"Album %@ song %@ has: %@",albumTitle ,songTitle, playCount);
        [self saveSongDataToPersistentStoreWithArtist:artist albumTitle:albumTitle songTitle:songTitle duration:duration andPlayCount:playCount];
    }
    
    
    
}

- (void)scanLibraryForNewPlayCount {
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"SongsData" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    NSError* requestError = nil;
    
    self.songsStoreInData = [self.context executeFetchRequest:fetchRequest error:&requestError];
    
    if ([self.songsStoreInData count] > 0) {
        
        for (SongsData* currentSongInData in self.songsStoreInData) {
            
            MPMediaItem* currentLibrarySong = [self findItemWithArtist:currentSongInData.artist
                                                            albumTitle:currentSongInData.albumTitle
                                                             songTitle:currentSongInData.songTitle];
            if (currentLibrarySong != nil) {
                
                NSLog(@"Song has found!");
                
                NSUInteger currentPlayCount = [[currentLibrarySong valueForProperty:MPMediaItemPropertyPlayCount]unsignedIntegerValue];
                NSUInteger storedPlayCount  = [currentSongInData.songPlayCount unsignedIntegerValue];
                
                NSLog(@"Stored play count: %lu new: %lu", (unsigned long)storedPlayCount, (unsigned long)currentPlayCount);
                
                if (storedPlayCount < currentPlayCount) {
                    
                    currentPlayCount -= storedPlayCount;
                    NSNumber* playCount = [NSNumber numberWithUnsignedInteger:currentPlayCount];
                    [self scrobbleTrackWithArtist:currentSongInData.artist
                                       albumTitle:currentSongInData.albumTitle
                                        songTitle:currentSongInData.songTitle
                                         duration:currentSongInData.duration
                                     andPlayCount:playCount];
                }
            }
        }
        
    }
    else {
        NSLog(@"Could not find any SongsData entity in context");
    }
    
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
    [self saveSongDataToPersistentStoreWithArtist:artist albumTitle:album songTitle:song duration:duration andPlayCount:playCount];
    
    
}

#pragma mark - Actions

- (IBAction)logOutButton:(UIButton *)sender {
    
    [[LastFm sharedInstance] logout];
    [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:isFirstLaunchKey];
    [self performSegueWithIdentifier:@"logoutToLoginVCSegue" sender:self];
}

- (IBAction)scrobbleButton:(UIButton *)sender {
    
    [self scanLibraryForNewPlayCount];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

#pragma mark - Helpers


@end
