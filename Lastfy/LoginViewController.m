//
//  LoginViewController.m
//  Lastfy
//
//  Created by Paul Kuznetsov on 07/05/15.
//  Copyright (c) 2015 Paul Kuznetsov. All rights reserved.
//

#import "LoginViewController.h"
#import "MainViewController.h"
#import <CSAnimationView.h>
#import <LastFm/LastFm.h>

NSString* const LastFMUserSessionKey    = @"userSessionKey";
NSString* const LastFMUserLoginKey      = @"userLoginKey";

NSString* const isFirstLaunchKey        = @"isFirstLaunchKey";

@interface LoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet CSAnimationView* loginView;

- (IBAction)loginButton:(UIButton *)sender;

@end

@implementation LoginViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //UITextFieldDelegate
    
    self.loginField.delegate    = self;
    self.passwordField.delegate = self;
    
    //Check if this first lunch
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:isFirstLaunchKey] isEqualToNumber:@1]) {
        
        [LastFm sharedInstance].username = [defaults objectForKey:LastFMUserLoginKey];
        [LastFm sharedInstance].session  = [defaults objectForKey:LastFMUserSessionKey];
        
        [self performSegueWithIdentifier:@"segueToMainVC" sender:self];
        
    }
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //Disabling Navigation Bar
    
    self.navigationController.navigationBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

#pragma mark - Actions

- (IBAction)loginButton:(UIButton *)sender {
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    
        //Initial first launch of the App
        [defaults setObject:@1 forKey:isFirstLaunchKey];
        //Saving user Session and Login in defaults
        
        __weak typeof(self) weakSelf = self;
        
        [[LastFm sharedInstance] getSessionForUser:self.loginField.text
                                          password:self.passwordField.text
                                    successHandler:^(NSDictionary *result) {
                                        
                                        [[NSUserDefaults standardUserDefaults]setObject:[result objectForKey:@"key"] forKey:LastFMUserSessionKey];
                                        [[NSUserDefaults standardUserDefaults]setObject:[result objectForKey:@"name"] forKey:LastFMUserLoginKey];
                                        
                                        __strong typeof(self) strongSelf = weakSelf;
                                        
                                        [strongSelf.loginView setType:CSAnimationTypeZoomIn];
                                        [strongSelf.loginView setDuration:0.3f];
                                        [strongSelf.loginView setDelay:0.f];
                                        [strongSelf.loginView startCanvasAnimation];
                                        
                                        [strongSelf performSegueWithIdentifier:@"segueToMainVC" sender:strongSelf];
                                    }
                                    failureHandler:^(NSError *error) {
                                        
                                        __strong typeof(self) strongSelf = weakSelf;
                                        
                                        [strongSelf.loginView setType:CSAnimationTypeShake];
                                        [strongSelf.loginView setDuration:0.3f];
                                        [strongSelf.loginView setDelay:0.f];
                                        [strongSelf.loginView startCanvasAnimation];
                                        
                                        
                                        
                                    }];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:self.loginField]) {
        [self.passwordField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
        [self loginButton:0];
    }
    
    return YES;
}

@end
