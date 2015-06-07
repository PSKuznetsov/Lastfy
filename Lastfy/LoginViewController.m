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

@property (weak, nonatomic) IBOutlet UITextField     *loginField;
@property (weak, nonatomic) IBOutlet UITextField     *passwordField;
@property (weak, nonatomic) IBOutlet UILabel         *loginStatusLabel;
@property (weak, nonatomic) IBOutlet CSAnimationView *loginView;

@property (strong, nonatomic) IBOutlet UIImageView   *backgroudView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceConstraint;

@property (assign, nonatomic) CGFloat constraintConstant;

- (IBAction)loginButton:(UIButton *)sender;

@end



@implementation LoginViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //UITextFieldDelegate
    
    self.loginField.delegate    = self;
    self.passwordField.delegate = self;
    
    
    
    [self.loginView setType:CSAnimationTypeBounceUp];
    [self.loginView setDuration:0.3f];
    [self.loginView setDelay:0.f];
    [self.loginView startCanvasAnimation];
    
    self.verticalSpaceConstraint.constant = 0.f;
    self.constraintConstant = self.verticalSpaceConstraint.constant;
    
    //NSLog(@"Constant is: %f", self.constraintConstant);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    
    //Disabling Navigation Bar
    
    self.navigationController.navigationBar.hidden = YES;
    
    //Subscribing keyboard notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - keyboard movements

- (void)keyboardWillShow:(NSNotification *)notification {
    
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    CGFloat newConstant = 0;
    newConstant += keyboardSize.height/2;
    
    [self.loginView setNeedsUpdateConstraints];
    //NSLog(@"%f",self.verticalSpaceConstraint.constant);
    self.verticalSpaceConstraint.constant = newConstant;
     //NSLog(@"%f",self.verticalSpaceConstraint.constant);
    [UIView animateWithDuration:0.3 animations:^{
        
        [self.loginView layoutIfNeeded];
        
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    //[self.loginView setNeedsUpdateConstraints];
    
    self.verticalSpaceConstraint.constant = self.constraintConstant;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        [self.loginView layoutIfNeeded];
    }];
}


#pragma mark - Navigation

- (void)performSegueToMainView {
    
    [self performSegueWithIdentifier:@"segueToMainVC" sender:self];
}

#pragma mark - Actions

- (IBAction)loginButton:(UIButton *)sender {
    //TODO: replace HUD's with UILabels
    self.loginStatusLabel.textColor = [UIColor grayColor];
    self.loginStatusLabel.text = NSLocalizedString(@"Login in...", nil);
    
    //Resign first responder from textfields
    [self.loginField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //Initial first launch of the App
    [defaults setObject:@0 forKey:isFirstLaunchKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Saving user Session and Login in defaults
    __weak typeof(self) weakSelf = self;
        
        [[LastFm sharedInstance] getSessionForUser:self.loginField.text
                                          password:self.passwordField.text
                                    successHandler:^(NSDictionary *result) {
                                        
                                        [[NSUserDefaults standardUserDefaults]setObject:[result objectForKey:@"key"] forKey:LastFMUserSessionKey];
                                        [[NSUserDefaults standardUserDefaults]setObject:[result objectForKey:@"name"] forKey:LastFMUserLoginKey];
                                        
                                        __strong typeof(self) strongSelf = weakSelf;
                                        strongSelf.loginStatusLabel.textColor = [UIColor greenColor];
                                        strongSelf.loginStatusLabel.text = NSLocalizedString(@"Login successesful", nil);
                                        //Setting up Canvas animation
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
                                        strongSelf.loginStatusLabel.textColor = [UIColor redColor];
                                        strongSelf.loginStatusLabel.text = NSLocalizedString(@"Wrong login or password. Try again.", nil);
                                        
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"._@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"] invertedSet];
    
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    return [string isEqualToString:filtered];
}

@end
