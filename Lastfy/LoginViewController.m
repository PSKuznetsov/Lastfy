//
//  LoginViewController.m
//  Lastfy
//
//  Created by Paul Kuznetsov on 07/05/15.
//  Copyright (c) 2015 Paul Kuznetsov. All rights reserved.
//

#import "LoginViewController.h"
#import <CSAnimationView.h>
#import <LastFm/LastFm.h>

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet CSAnimationView* loginView;

- (IBAction)loginButton:(UIButton *)sender;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //Setting up loginView animation parameters
    [self.loginView setType:CSAnimationTypeShake];
    [self.loginView setDuration:0.3f];
    [self.loginView setDelay:0.f];
    
    
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
    
    [self.loginView startCanvasAnimation];
}
@end
