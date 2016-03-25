//
//  SerialConfigViewController.h
//  Redpark Serial Demo App
//
//  Created by Adam F Froio on 5/12/15.
//  Copyright © 2015 Redpark  All Rights Reserved
//

#import <UIKit/UIKit.h>


@interface SerialConfigViewController : UIViewController <UITextFieldDelegate>
{
    NSUserDefaults *defaults;
}

@property (strong, nonatomic) IBOutlet UITextField *baudRateTextField;
@property (strong, nonatomic) IBOutlet UISwitch *debugSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *txRxSwitch;
@property (strong, nonatomic) IBOutlet UISegmentedControl *dataBitsSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *paritySegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *stopBitsSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *rtsSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *ctsSegmentedControl;


@end
