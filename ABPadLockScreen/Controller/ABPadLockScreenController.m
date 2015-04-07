//
//  ABPadLockScreenController.m
//
//  Version 2.0
//
//  Created by Aron Bury on 09/09/2011.
//  Copyright 2011 Aron Bury. All rights reserved.
//
//  Get the latest version of ABLockScreen from this location:
//  https://github.com/abury/ABPadLockScreen
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//
#import "ABPadLockScreenController.h"
#import "ABPadLockScreenView_iPad.h"
#import "ABPadLockScreenView_iPhone.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "SFHFKeychainUtils.h"

#define ipadView ((ABPadLockScreenView_iPad *)[self view])

#define kNoAttemptLimit -1

typedef enum {
    ABLockPadModeLock = 0,
    ABLockPadModeSetup = 1
    
}ABLockPadMode;

@interface ABPadLockScreenController() <UITextFieldDelegate>

/**
 The current pin value
 */
@property (nonatomic, strong) NSString *currentPin;

/**
 How many unlock attempts the user has performed
 */
@property (nonatomic, assign) NSInteger attempts;

@property (nonatomic, strong) NSString *firstPinEntry;
@property (nonatomic, strong) NSString *secondPinEntry;
@property (nonatomic, assign) ABLockPadMode mode;
@property (nonatomic, strong)UIImageView *navBarHairlineImageView;


/**
 Called when the user selects the cancel button
 */
- (void)cancelButtonSelected:(id)sender;
/**
 Called when the user has entered 4 digits the controller checks to see if the pin matches
 */
- (void)checkPin;

/**
 Locks the pad from further use after the user has expired their allowed attempts
 */
- (void)lockPad;

/**
 Performs the relevant actions when a user fails a PIN entry attempt that is not their last
 @param remainingAttempts The reamining attempts to display to the user
 */
- (void)failedAttemptWithRemaningAttempts:(NSInteger)remainingAttempts;

/**
 Performs the relevant actions when a user fails their final PIN entry attempt
 */
- (void)failedFinalAttempt;

@end

@implementation ABPadLockScreenController

#pragma mark -
#pragma mark - init Methods
- (id)initWithABLockScreenDelegate:(id<ABLockScreenDelegate>)delegate
{
	NSString *nibName = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		nibName = @"ABPadLockScreenController-iPad";
	} else {
		nibName = @"ABPadLockScreenController";
	}
    self = [self initWithNibName:nibName bundle:nil];
    if (self)
    {
        _delegate = delegate;
        _currentPin = @"";
        _attemptLimit = 0;
		_mode = ABLockPadModeLock;
    }
    
    return self;
}

- (id)initWithABLockScreenSetupDelegate:(id<ABLockScreenSetupDelegate>)delegate
{
	NSString *nibName = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		nibName = @"ABPadLockScreenController-iPad";
	} else {
		nibName = @"ABPadLockScreenController";
	}
    self = [self initWithNibName:nibName bundle:nil];
    if (self)
    {
        _setupDelegate = delegate;
        _currentPin = @"";
		_mode = ABLockPadModeSetup;
    }
    
    return self;
}


#pragma mark -
#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_button_clear.png"] forBarMetrics:UIBarMetricsDefault];
	self.navigationController.navigationBar.hidden = YES;
	self.navBarHairlineImageView=[self findHairlineImageViewUnder:self.navigationController.navigationBar];
	if (self.mode == ABLockPadModeSetup) {
		[self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
		NSString *ver = [[UIDevice currentDevice] systemVersion];
		int ver_int = [ver intValue];
		if(ver_int<7)
		{
			[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"modelview_toolbar.png"] forBarMetrics:UIBarMetricsDefault];
		}
		else{
			[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar_button_clear.png"] forBarMetrics:UIBarMetricsDefault];
		}
		self.navigationController.navigationBar.hidden = NO;
		UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelButtonSelected:)];
		[cancelBarButtonitem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:17], NSFontAttributeName,nil] forState:UIControlStateNormal];
		[[self navigationItem] setRightBarButtonItem:cancelBarButtonitem animated:NO];
		self.subtitle  = @"Setup Passcode";

	}
    
       
	self.subtitleLabel = ipadView.subtitleLabel;
    
	self.subtitleLabel.text = self.subtitle;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if(self.mode == ABLockPadModeLock)
	{
		
		LAContext *defaultContext = [[LAContext alloc] init];
		NSError *error;
		
		if([defaultContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
		{
			NSUserDefaults *defaults      = [NSUserDefaults sharedUserDefaults];
			NSString       *lastGroupName = [defaults stringForKey:kUserDefaultsKeyGroupName];
			NSString       *lastUserId    = [defaults stringForKey:kUserDefaultsKeyUserName];
			NSString *passcode = [SFHFKeychainUtils getPasswordForUsername:[NSString stringWithFormat:@"%@||%@||%@", lastGroupName, lastUserId, kIngeniousAppDomainIdentifier] andServiceName:kIngeniousAppDomainIdentifier error:&error sharedKeychain:YES];
			
			defaultContext.localizedFallbackTitle = @"Enter PIN";
			if(passcode.length > 0)
			{
				[defaultContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
							   localizedReason:@"Login to Ingenious Med"
										 reply:^(BOOL success, NSError *error) {
											 if (success)
											 {
												 dispatch_sync(dispatch_get_main_queue(), ^(void){
												 
													 self.currentPin = passcode;
													 [self checkPin];
												 });
											 }
											 else
											 {
												 switch (error.code)
												 {
													 case LAErrorAuthenticationFailed:
														 return;
														 break;
													 case LAErrorUserCancel:
														 return;
														 
														 break;
													 case LAErrorUserFallback:
														 return;
														 
														 break;
													 case LAErrorSystemCancel:
														 return;
														 
														 break;
													 case LAErrorPasscodeNotSet:
														 return;
														 
														 break;
													 case LAErrorTouchIDNotAvailable:
														 return;
														 
														 break;
													 case LAErrorTouchIDNotEnrolled:
														 return;
														 
														 break;
														 
													 default:
														 return;
														 break;
												 }
											 }
										 }];

			}
		}
		

	}
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navBarHairlineImageView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navBarHairlineImageView.hidden = NO;
}
- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
		return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

#pragma mark -
#pragma mark - Public Methods
- (void)resetErrorLabels
{
    self.attempts = 0;
	ipadView.remainingAttemptsLabel.text = @"";
	ipadView.errorbackView.alpha = 0.0f;
	self.subtitleLabel.text = self.subtitle;
}

- (void)resetSetupPins
{
	self.firstPinEntry = nil;
	self.secondPinEntry = nil;
}

- (void)resetLockScreen
{
    self.currentPin = @"";
    
    UIView *relevantVeiw = ipadView;
    NSInteger startingPoint = 11;
    NSInteger endingPoint = 15;
    
    for (NSInteger i = startingPoint; i < endingPoint; i++)
    {
        if ([[relevantVeiw viewWithTag:i] isKindOfClass:[UIImageView class]])
        {
            UIImageView *relevantPinImage = (UIImageView *)[relevantVeiw viewWithTag:i];
            relevantPinImage.image = [UIImage imageNamed:@"small_circle.png"];
        }
    }
}

- (void)animateLockBoxes
{
	//Animate the boxes here
	[UIView animateWithDuration:0.4 animations:^(void) {
		
	} completion:^(BOOL finished) {
		
	}];
}

- (void)setAttemptLimit:(NSInteger)attemptLimit
{
    if (attemptLimit == 0)
    {
        _attemptLimit = -1;
        return;
    }
    
    _attemptLimit = attemptLimit;
}

#pragma mark -
#pragma mark - Private Methods

- (void)cancelButtonSelected:(id)sender
{
    if (self.mode == ABLockPadModeLock && self.delegate && [self.delegate respondsToSelector:@selector(unlockWasCancelled)]) {
        [self.delegate unlockWasCancelled];
        [self resetLockScreen];
        [self resetErrorLabels];
    }
	if (self.mode == ABLockPadModeSetup && self.setupDelegate && [self.setupDelegate respondsToSelector:@selector(setupWasCancelled)]) {
		[self.setupDelegate setupWasCancelled];
		[self resetLockScreen];
		[self resetSetupPins];
	}
}

- (IBAction)digitButtonselected:(id)sender
{
	[self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
	
    UIButton *digitButton = (UIButton *)sender;
    
    NSString *digitAsString = [NSString stringWithFormat:@"%ld", (long)digitButton.tag];
	
    if ([[ipadView viewWithTag:self.currentPin.length + 11] isKindOfClass:[UIImageView class]])
    {
        UIImageView *relevantPinImage = (UIImageView *)[ipadView viewWithTag:self.currentPin.length + 11];
        relevantPinImage.image = [UIImage imageNamed:@"small_circle_filled.png"];
    }
    
    self.currentPin = [NSString stringWithFormat:@"%@%@", self.currentPin, digitAsString];
	
    if (self.currentPin.length == 4)
        [self performSelector:@selector(checkPin) withObject:Nil afterDelay:0.1];
}

- (IBAction)backButtonSelected:(id)sender
{
    if ([[ipadView viewWithTag:self.currentPin.length + 10] isKindOfClass:[UIImageView class]])
    {
        UIImageView *relevantPinImage = (UIImageView *)[ipadView viewWithTag:self.currentPin.length + 10];
        relevantPinImage.image = [UIImage imageNamed:@"small_circle.png"];
    }
    
    if (self.currentPin.length > 0)
	{
        self.currentPin = [self.currentPin substringWithRange:NSMakeRange(0, self.currentPin.length - 1)];
	}
	else if(self.mode != ABLockPadModeSetup)
	{
		[self cancelButtonSelected:self];
	}
	if (self.currentPin.length==0 && self.mode != ABLockPadModeSetup)
		[self.deleteButton setTitle:@"Cancel" forState:UIControlStateNormal];
}

- (void)checkPin
{
	if (self.mode == ABLockPadModeLock) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(unlockWithCode:)]) {
			BOOL success = [self.delegate unlockWithCode:self.currentPin];
			if (success)
			{
				NSUserDefaults *defaults      = [NSUserDefaults sharedUserDefaults];
				NSString       *lastGroupName = [defaults stringForKey:kUserDefaultsKeyGroupName];
				NSString       *lastUserId    = [defaults stringForKey:kUserDefaultsKeyUserName];
				[SFHFKeychainUtils storeUsername:[NSString stringWithFormat:@"%@||%@||%@", lastGroupName, lastUserId, kIngeniousAppDomainIdentifier] andPassword:self.secondPinEntry forServiceName:kIngeniousAppDomainIdentifier updateExisting:YES error:nil sharedKeychain:YES];

				[self resetErrorLabels];
				[self resetLockScreen];
			}
		}
	}
	
	if (self.mode == ABLockPadModeSetup) {
		[self clearError];
		if (!self.firstPinEntry) {
			self.firstPinEntry = self.currentPin;
			self.currentPin = @"";
			self.secondPinEntry = nil;
			[self animateLockBoxes];
			[self resetLockScreen];
			self.subtitleLabel.text = @"Confirm Passcode";
		} else if (!self.secondPinEntry) {
			self.secondPinEntry = self.currentPin;
			self.currentPin = @"";
			if ([self.firstPinEntry isEqualToString:self.secondPinEntry]) {
				
				NSUserDefaults *defaults      = [NSUserDefaults sharedUserDefaults];
				NSString       *lastGroupName = [defaults stringForKey:kUserDefaultsKeyGroupName];
				NSString       *lastUserId    = [defaults stringForKey:kUserDefaultsKeyUserName];
				[SFHFKeychainUtils storeUsername:[NSString stringWithFormat:@"%@||%@||%@", lastGroupName, lastUserId, kIngeniousAppDomainIdentifier] andPassword:self.secondPinEntry forServiceName:kIngeniousAppDomainIdentifier updateExisting:YES error:nil sharedKeychain:YES];

				if (self.setupDelegate && [self.setupDelegate respondsToSelector:@selector(setupWasSuccessfulWithCode:)]) {
					[self.setupDelegate setupWasSuccessfulWithCode:self.secondPinEntry];
				}
			} else {
				self.subtitleLabel.text = self.subtitle;
				[self codeSetupMismatch];
			}
			[self resetSetupPins];
			[self resetLockScreen];
		}
	}
}

- (void)lockPad
{
    
	ipadView.remainingAttemptsLabel.text = @"Attempts expired";
	ipadView.subtitleLabel.text = @"PIN Entry Locked";
}

- (void)failedAttemptWithRemaningAttempts:(NSInteger)remainingAttempts
{
    
    
	ipadView.remainingAttemptsLabel.text = [NSString stringWithFormat:@"%ld Attempts Remaining", (long)remainingAttempts];
	if (ipadView.errorbackView.alpha == 0.0f)
	{
		[UIView animateWithDuration:0.4f animations:^{
			ipadView.errorbackView.alpha = 1.0f;
		}];
	}
    
}

- (void)failedFinalAttempt
{
    
	ipadView.remainingAttemptsLabel.text = [NSString stringWithFormat:@"%ld Failed Passcode Attempts", (long)self.attempts];
	if (ipadView.errorbackView.alpha == 0.0f)
	{
		[UIView animateWithDuration:0.4f animations:^{
			ipadView.errorbackView.alpha = 1.0f;
		}];
	}
}

- (void)codeSetupMismatch
{
    
	ipadView.remainingAttemptsLabel.text = @"Passcodes did not match. Try again.";
	if (ipadView.errorbackView.alpha == 0.0f)
	{
		[UIView animateWithDuration:0.4f animations:^{
			ipadView.errorbackView.alpha = 1.0f;
		}];
	}
}

- (void)clearError
{
	ipadView.remainingAttemptsLabel.text = @"";
	if (ipadView.errorbackView.alpha == 1.0f)
	{
		[UIView animateWithDuration:0.4f animations:^{
			ipadView.errorbackView.alpha = 0.0f;
		}];
	}
}

- (void)viewDidUnload {
	[self setAnimationView:nil];
	[super viewDidUnload];
}


//This fix will allow the screen to work with iPad applications that have the interface orientation set to Horizontal.
//So we don't display the pin screen in a different orientation related to the iPad.
#pragma mark - Interface orientation for iOS 5

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)  {
        return YES;
    }else {
        return NO;
    }
}

@end
