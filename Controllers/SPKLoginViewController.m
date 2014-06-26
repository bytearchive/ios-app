//
//  SPKLoginViewController.m
//  Spark IOS
//
//  Copyright (c) 2013 Spark Devices. All rights reserved.
//

#import "SPKLoginViewController.h"
#import "SPKSpark.h"
#import <QuartzCore/QuartzCore.h>

@implementation SPKLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.userIdTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 20)];
    self.userIdTextField.leftViewMode = UITextFieldViewModeAlways;

    self.passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 20)];
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionError:) name:kSPKWebClientConnectionError object:nil];

    [self.loginButton setTitle:@"LOG IN" forState:UIControlStateNormal];
    self.loginButton.enabled = NO;
    self.userIdTextField.enabled = YES;
    self.passwordTextField.enabled = YES;

    self.spinnerImageView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPKWebClientConnectionError object:nil];
}

- (void)viewDidLayoutSubviews
{
    if (!isiPhone5) {
        CGRect f = self.formView.frame;
        f.origin.y -= 50.0;
        self.formView.frame = f;

        f = self.logoImageView.frame;
        f.origin.x += (f.size.width - (f.size.width * 0.75)) / 2.0;
        f.size.height *= 0.75;
        f.size.width *= 0.75;
        self.logoImageView.frame = f;
    }
}

- (void)dismissKeyboard
{
    if (self.userIdTextField.isFirstResponder) {
        [self.userIdTextField resignFirstResponder];
    } else if (self.passwordTextField.isFirstResponder) {
        [self.passwordTextField resignFirstResponder];
    }
}

#pragma mark - Notifications

- (void)connectionError:(NSNotification *)notifications
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.userIdTextField.enabled = YES;
        self.passwordTextField.enabled = YES;
        [self.loginButton setTitle:@"LOG IN" forState:UIControlStateNormal];
    });
}

#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL r1 = NO;
    BOOL r2 = NO;

    NSString *s = self.userIdTextField.text;
    if (textField == self.userIdTextField) {
        s = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    r1 = [self isValidEmail:s];

    s = self.passwordTextField.text;
    if (textField == self.passwordTextField) {
        s = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    r2 = s.length > 0;

    self.loginButton.enabled = r1 && r2;

#if 0
    self.loginButton.enabled = YES;
#endif

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if (textField == self.userIdTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self.passwordTextField resignFirstResponder];
        [self login:textField];
    }
    return NO;
}

#pragma mark - Actions

- (IBAction)forgot:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.spark.io/forgot-password"]];
}

- (IBAction)login:(id)sender
{
    self.userIdTextField.enabled = NO;
    self.passwordTextField.enabled = NO;

    [self.loginButton setTitle:@"LOGGING IN..." forState:UIControlStateNormal];

    SPKUser *user = [SPKSpark sharedInstance].user;
    user.userId = self.userIdTextField.text;
    user.password = self.passwordTextField.text;
    [SPKSpark sharedInstance].attemptedLogin = YES;

    [self spinSpinner:YES];

    [[SPKSpark sharedInstance].webClient login:^(NSString *authToken) {
        user.token = authToken;
        [user store];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self spinSpinner:NO];
            self.errorLabel.text = @"";
            [self performSegueWithIdentifier:@"loading" sender:sender];
        });
    } failure:^(NSString *failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self spinSpinner:NO];

            self.userIdTextField.enabled = YES;
            self.passwordTextField.enabled = YES;

            self.errorLabel.text = @"Username and/or password incorrect";

            [self.loginButton setTitle:@"LOG IN" forState:UIControlStateNormal];
        });
    }];
}

#pragma mark - Private Methods

- (void)spinSpinner:(BOOL)go
{
    if (go) {
        self.spinnerImageView.hidden = NO;

        CABasicAnimation *rotation;
        rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        rotation.fromValue = [NSNumber numberWithFloat:0];
        rotation.toValue = [NSNumber numberWithFloat:(2*M_PI)];
        rotation.duration = 1.1; // Speed
        rotation.repeatCount = HUGE_VALF; // Repeat forever. Can be a finite number.
        [self.spinnerImageView.layer addAnimation:rotation forKey:@"Spin"];
    } else {
        self.spinnerImageView.hidden = YES;
        [self.spinnerImageView.layer removeAllAnimations];
    }
}

@end
