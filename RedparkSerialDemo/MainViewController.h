//
//  ViewController.h
//  Redpark Serial Demo App
//
//  Created by Adam F Froio on 5/12/15.
//  Copyright © 2015 Redpark  All Rights Reserved
//

#import <UIKit/UIKit.h>
#import "redparkSerial.h"
#import "RscMgr.h"

#define TEST_DATA_LEN 256


@interface MainViewController : UIViewController <RscMgrDelegate, UITextFieldDelegate>
{
   
    NSThread *commThread;   // thread for communications tasks
    RscMgr *rscMgr;         // Redpark serial communications
    
    UIColor *myGreen;
    UIColor *myRed;
    
    IBOutlet UIBarButtonItem *startButton;
    IBOutlet UIBarButtonItem *stopButton;
    IBOutlet UIBarButtonItem *configButton;
    IBOutlet UILabel *cableStatusLabel;
    IBOutlet UILabel *serialSettingsLabel;
    IBOutlet UILabel *txLabel;
    IBOutlet UILabel *rxLabel;
    IBOutlet UILabel *errorsLabel;
    IBOutlet UITextField *toSendTextField;
    IBOutlet UITextView *terminalTextView;
    IBOutlet UILabel *riLabel;
    IBOutlet UILabel *cdLabel;
    IBOutlet UILabel *dsrLabel;
    IBOutlet UILabel *ctsLabel;
    IBOutlet UIButton *rtsButton;
    IBOutlet UIButton *dtrButton;


    NSUserDefaults *defaults;   // to read and write communications settings
    
    BOOL cableConnected;
    
    
    int baudRate;
    int dataBits;
    int parity;
    int stopBits;
    int rts;        // rx flow control
    int cts;        // tx flow control
    BOOL logging;   // log data over http
    BOOL showTxRx;  // log tx & rx data
    
    DataSizeType dataSizeType;
    ParityType parityType;
    StopBitsType stopBitsType;

    int rxCount;
    int txCount;
    int errCount;
    
    UInt8 seqNum;
    UInt8 testData[TEST_DATA_LEN];
    UInt8 rxBuffer[TEST_DATA_LEN];
    BOOL testRunning;    
}

- (void) webLog:(NSString *)text color:(NSString *)color;
- (void) startCommThread:(id)object;
- (void) updateStatus:(id)object;
- (void) resetCounters;
- (void) startTest;
- (void) stopTest;
- (IBAction) sendUserData:(id)sender;


@end