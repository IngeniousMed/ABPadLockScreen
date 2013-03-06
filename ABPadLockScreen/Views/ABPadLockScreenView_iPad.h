//
//  ABPadLockScreenView_iPad.h
//  ABPadLockScreen
//
//  Created by Aron Bury on 10/11/12.
//  Copyright (c) 2012 Aron's IT Consultancy. All rights reserved.
//

#import <UIKit/UIKit.h>

#define clearTag 1221

@interface ABPadLockScreenView_iPad : UIView

/**
 The entry boxes for the view
 */
@property (nonatomic, strong) IBOutlet UIImageView *box1;
@property (nonatomic, strong) IBOutlet UIImageView *box2;
@property (nonatomic, strong) IBOutlet UIImageView *box3;
@property (nonatomic, strong) IBOutlet UIImageView *box4;

/**
 Displays the subittle text to the user
 */
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

/**
 Displays the remaining alerts to the user
 */
@property (nonatomic, strong) IBOutlet UILabel *remainingAttemptsLabel;

/**
 Displays the red alert background for the remainingAttemptsLabel
 */
@property (nonatomic, strong) IBOutlet UIImageView *errorbackView;

/** Emulated Keyboard Buttons */
@property (nonatomic, strong) IBOutlet UIButton *one;
@property (nonatomic, strong) IBOutlet UIButton *two;
@property (nonatomic, strong) IBOutlet UIButton *three;
@property (nonatomic, strong) IBOutlet UIButton *four;
@property (nonatomic, strong) IBOutlet UIButton *five;
@property (nonatomic, strong) IBOutlet UIButton *six;
@property (nonatomic, strong) IBOutlet UIButton *seven;
@property (nonatomic, strong) IBOutlet UIButton *eight;
@property (nonatomic, strong) IBOutlet UIButton *nine;
@property (nonatomic, strong) IBOutlet UIButton *zero;
@property (nonatomic, strong) IBOutlet UIButton *back;
@property (nonatomic, strong) IBOutlet UIButton *blank;


@end
