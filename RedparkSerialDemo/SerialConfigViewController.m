//
//  SerialConfigViewController.m
//  Redpark Serial Demo App
//
//  Created by Adam F Froio on 5/12/15.
//  Copyright © 2015 Redpark  All Rights Reserved
//


#import "SerialConfigViewController.h"


@implementation SerialConfigViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _baudRateTextField.delegate = self;
    
    // read the saved settings and update the configuraion controls
    defaults = [NSUserDefaults standardUserDefaults];
    _baudRateTextField.text = [NSString stringWithFormat:@"%ld", (long)[defaults integerForKey:@"baudRate"]];
    _dataBitsSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"dataBits"];
    _paritySegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"parity"];
    _stopBitsSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"stopBits"];
    _rtsSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"rts"];
    _ctsSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"cts"];
    _debugSwitch.on = [defaults boolForKey:@"logging"];
    _txRxSwitch.on = [defaults boolForKey:@"showTxRx"];
}


// dismiss the keyboard if the user taps the enter key in the baud rate field
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return NO;
}


// don't allow commas in the baud rate (replace any commas typed with an empty string)
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString {
    
    NSString *originalNumber = _baudRateTextField.text;
    if([replacementString isEqualToString:@""]) {
        originalNumber = [originalNumber stringByReplacingCharactersInRange:range withString:@""];
    } else {
        originalNumber = [originalNumber stringByAppendingString:replacementString];
    }
    originalNumber = [originalNumber stringByReplacingOccurrencesOfString:@"," withString:@""];
    _baudRateTextField.text = originalNumber;
    
    return NO;
}


@end
