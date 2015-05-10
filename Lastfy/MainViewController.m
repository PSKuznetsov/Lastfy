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
#import "AppDelegate.h"

#import <MediaPlayer/MediaPlayer.h>
#import <LastFm/LastFm.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet CSAnimationView *userAvatarView;
@property (weak, nonatomic) IBOutlet UIImageView *userAvatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

- (IBAction)logOutButton:(UIButton *)sender;

@end

@implementation MainViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray* mediaQuery = [[MPMediaQuery songsQuery]items];
    
    for (MPMediaItem* item in mediaQuery) {
        NSNumber* playCount  = [item valueForProperty:MPMediaItemPropertyPlayCount];
        NSString* songTitle  = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString* albumTitle = [item valueForKey:MPMediaItemPropertyAlbumTitle];
        
        //NSLog(@"Album %@ song %@ has: %@",albumTitle ,songTitle, playCount);
        [self saveSongDataToPersistentStoreWithAlbum:albumTitle
                                           songTitle:songTitle
                                        andPlayCount:playCount];
    }
    
  /*  [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] objectForKey:LastFMUserSessionKey];
    
    [[LastFm sharedInstance] sendScrobbledTrack:@"Wish You Were Here" byArtist:@"Pink Floyd" onAlbum:@"Wish You Were Here" withDuration:534 atTimestamp:(int)[[NSDate date] timeIntervalSince1970] successHandler:^(NSDictionary *result) {
        NSLog(@"result: %@", result);
    } failureHandler:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];*/
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.userAvatarView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.f];
    
    __weak typeof(self) weakSelf = self;
    
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

#pragma mark - Data operations

- (void)saveSongDataToPersistentStoreWithAlbum:(NSString *)album songTitle:(NSString *)title andPlayCount:(NSNumber *)playCount {
    
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext* context = [appDelegate managedObjectContext];
   
    NSManagedObject* currentSongObject = [NSEntityDescription
                                          insertNewObjectForEntityForName:@"SongsData"
                                                   inManagedObjectContext:context];
    
    [currentSongObject setValue:album     forKey:@"albumTitle"];
    [currentSongObject setValue:title     forKey:@"songTitle"];
    [currentSongObject setValue:playCount forKey:@"songPlayCount"];
    
    NSError* error;
    [context save:&error];
}

#pragma mark - Actions

- (IBAction)logOutButton:(UIButton *)sender {
    
    [[LastFm sharedInstance] logout];
    [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:isFirstLaunchKey];
    [self performSegueWithIdentifier:@"logoutToLoginVCSegue" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

#pragma mark - Helpers


@end
