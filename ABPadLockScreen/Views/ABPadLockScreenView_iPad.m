//
//  ABPadLockScreenView_iPad.m
//  ABPadLockScreen
//
//  Created by Aron Bury on 10/11/12.
//  Copyright (c) 2012 Aron's IT Consultancy. All rights reserved.
//

#import "ABPadLockScreenView_iPad.h"

@interface ABPadLockScreenView_iPad()

- (UIButton *)getStyledButtonForNumber:(NSInteger)number;

@end

@implementation ABPadLockScreenView_iPad



#pragma mark -
#pragma mark - Private Methods
- (UIButton *)getStyledButtonForNumber:(NSInteger)number
{
    UIButton * returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *imageName = [NSString stringWithFormat:@"%ld", (long)number];
    NSString *altImageName = [NSString stringWithFormat:@"%@-selected", imageName];
    [returnButton setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [returnButton setBackgroundImage:[UIImage imageNamed:altImageName] forState:UIControlStateHighlighted];
    returnButton.tag = number;
    
    return returnButton;
}

@end
