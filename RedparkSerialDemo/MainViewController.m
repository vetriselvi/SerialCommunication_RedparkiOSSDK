//
//  ViewController.m
//  Redpark Serial Demo App
//
//  Created by Adam F Froio on 5/12/15.
//  Copyright © 2015 Redpark  All Rights Reserved
//



#import "MainViewController.h"
#import "SerialConfigViewController.h"
#import <QuartzCore/QuartzCore.h>

#define MODEM_STAT_ON_COLOR [UIColor colorWithRed:0.0/255.0 green:255.0/255.0 blue:0.0/255.0 alpha:1.0]
#define MODEM_STAT_OFF_COLOR [UIColor colorWithRed:128.0/255.0 green:128.0/255.0 blue:128.0/255.0 alpha:1.0]
#define MODEM_STAT_RECT CGRectMake(0.0f,0.0f,42.0f,21.0f)


@interface MainViewController ()
@end


@implementation MainViewController


// perform startup tasks whe the app is launched
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    toSendTextField.delegate = self;

    // for the cable status label
    myGreen = [UIColor colorWithRed:0/255.0f green:128/255.0f blue:0/255.0f alpha:1.0f];
    myRed = [UIColor colorWithRed:200/255.0f green:0/255.0f blue:0/255.0f alpha:1.0f];

    // init UI values
    txLabel.text = @"0";
    rxLabel.text = @"0";
    errorsLabel.text = @"0";
    terminalTextView.text = @"";
    startButton.enabled = NO;
    stopButton.enabled = NO;
    cableConnected = NO;
    testRunning = NO;
    
    // retrieve the stored settings before the view loads
    defaults  = [NSUserDefaults standardUserDefaults];
    baudRate  = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"baudRate"];
    dataBits  = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"dataBits"];
    parity    = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"parity"];
    stopBits  = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"stopBits"];
    rts       = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"rts"];
    cts       = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"cts"];
    logging   = (BOOL)[[NSUserDefaults standardUserDefaults] boolForKey:@"logging"];
    showTxRx  = (BOOL)[[NSUserDefaults standardUserDefaults] boolForKey:@"showTxRx"];
    
    
    // validate baud rate value (the default of zero is fine for the others, if uninitialized)
    if(baudRate == 0) {
        baudRate = 115200;  // if uninitialized, assign a default value
    }
    
    [[rtsButton layer] setBorderWidth:1.0f];
    [[rtsButton layer] setBorderColor:[UIColor grayColor].CGColor];
    rtsButton.layer.cornerRadius = 6;
 
    [[dtrButton layer] setBorderWidth:1.0f];
    [[dtrButton layer] setBorderColor:[UIColor grayColor].CGColor];
    dtrButton.layer.cornerRadius = 6;
    
    [self loadSerialSettings];  // update the UI elements
    
   
    // load test buffer
    int i;
    for (i = 0; i < TEST_DATA_LEN; i++) {
        testData[i] = i;
    }
    
    // Create and start the comm thread.  We'll use this thread to manage the rscMgr so
    // we don't tie up the UI thread.
    if (commThread == nil) {
        commThread = [[NSThread alloc] initWithTarget:self
                                             selector:@selector(startCommThread:)
                                               object:nil];
        [commThread start];  // Actually create the thread
    }
}


// start the communication thread
- (void) startCommThread:(id)object {
    
    // initialize RscMgr on this thread
    // so it schedules delegate callbacks for this thread
    rscMgr = [[RscMgr alloc] init];
    
    [rscMgr setDelegate:self];
    
    [rscMgr enableExternalLogging:logging];
    [rscMgr enableTxRxExternalLogging:showTxRx];
    
    
    // run the run loop
    [[NSRunLoop currentRunLoop] run];
}


// Redpark Serial Cable has been connected and/or application moved to foreground.
// protocol is the string which matched from the protocol list passed to initWithProtocol:
- (void) cableConnected:(NSString *)protocol {
    
    cableConnected = YES;
    cableStatusLabel.textColor = myGreen;
    cableStatusLabel.text = @"Cable Connected";

    // set baud rate, data bits, parity, and stop bits
    [rscMgr setBaud:baudRate];
    [rscMgr setDataSize:dataSizeType];
    [rscMgr setParity:parityType];
    [rscMgr setStopBits:stopBitsType];
    
    serialPortConfig portCfg;
    [rscMgr getPortConfig:&portCfg];
    portCfg.txAckSetting = 1;
    portCfg.rxFlowControl = rts;     // set flow control options
    portCfg.txFlowControl = cts;
    [rscMgr setPortConfig:&portCfg requestStatus: NO];
    
    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:nil waitUntilDone:NO];
    startButton.enabled = YES;
    stopButton.enabled = NO;
    rtsButton.enabled = YES;
    dtrButton.enabled = YES;
}


// Redpark Serial Cable was disconnected and/or application moved to background
- (void) cableDisconnected {
    
    cableConnected = NO;
    cableStatusLabel.textColor = myRed;
    cableStatusLabel.text = @"Cable Disconnected";
    [self stopTest];
    [self performSelectorOnMainThread:@selector(resetCounters) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:nil waitUntilDone:NO];
    startButton.enabled = NO;
    stopButton.enabled = NO;
    rtsButton.enabled = NO;
    dtrButton.enabled = NO;
}


// reset button is tapped
- (IBAction)resetCounters:(id)sender {
    
    [self resetCounters];
}


// reset the ui elements
- (void) resetCounters {
    
    testRunning = NO;
    txCount = rxCount = errCount = 0;
    seqNum = 0;
    if (cableConnected) {
        startButton.enabled = YES;
    }
    stopButton.enabled = NO;
    [self updateStatus:nil];
    terminalTextView.text = @"";
}


- (void) updateStatus:(id)object {
    
    rxLabel.text = [NSString stringWithFormat:@"%d", rxCount];
    txLabel.text = [NSString stringWithFormat:@"%d", txCount];
    errorsLabel.text = [NSString stringWithFormat:@"%d", errCount];
}


// Start loopback test button tapped
- (IBAction)clickedStart:(id)sender {
    
    if (testRunning == NO) {
        [self performSelector:@selector(startTest) onThread:commThread withObject:nil waitUntilDone:YES];
        startButton.enabled = NO;
        stopButton.enabled = YES;
    }
}


// Stop loopback test button tapped
- (IBAction)clickedStop:(id)sender {
    
    if (testRunning != NO) {

        [self performSelector:@selector(stopTest) onThread:commThread withObject:nil waitUntilDone:YES];

        stopButton.enabled = NO;
        startButton.enabled = YES;
    }
}


// initialize and start the loopback test
- (void) startTest {
    
    testRunning = YES;
    seqNum = 0;
    
    [rscMgr write:testData length:TEST_DATA_LEN];
    
    txCount += TEST_DATA_LEN;
    
    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:nil waitUntilDone:NO];
}


// stop the loopback test
- (void) stopTest {
    
    testRunning = NO;
}


// if a loopback test is not running, send the text the user typed in to the terminal
// and to over the serial connection.  display a message if a test is in progress
- (IBAction)sendUserData:(id)sender {
    
    if (!testRunning) {
        [self outputToTerminal:toSendTextField.text];
        [self webLog:toSendTextField.text color:@"red"];
        // output to serial connection
        [rscMgr writeString:toSendTextField.text];
        toSendTextField.text = @"";
    } else {
        [self outputToTerminal:@"Loopback test in progress; stop test to send commands manually."];
    }
}


// bytes are available to be read (user calls read:)
- (void) readBytesAvailable:(UInt32)length {
    
    //NSLog(@"readBytesAvailable");
    
    int len;
    
    if (testRunning) {      // if a loopback test is running
    
        while (length) {

            len = [rscMgr read:rxBuffer length:TEST_DATA_LEN];
            
            int i;
            for (i = 0; i < len; i++)
            {
                if (rxBuffer[i] != seqNum)
                {
                    errCount++;
                    seqNum = rxBuffer[i];
                }
                seqNum++;
            }
            
            rxCount += len;
            
            length -= len;
        }
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:nil waitUntilDone:NO];
     }
     else {     // if a loopback test is *not* running, process any text entered by the user
         NSString *str = [rscMgr getStringFromBytesAvailable];
     
         if ([str length] != 0) {       // avoid outputting empty strings; remains of a previously stopped loopback test may be displayed, however
             [self performSelectorOnMainThread:@selector(outputToTerminal:) withObject:str waitUntilDone:NO];
         }
     }
}


// serial port status has changed
// user can call getModemStatus or getPortStatus to get current state
- (void) portStatusChanged {
    
    int modemStatus = [rscMgr getModemStatus];
    static serialPortStatus portStat;
    
    NSLog(@"PortStatus: msr:%02x", modemStatus);
	
    [ctsLabel  setTextColor:(modemStatus & MODEM_STAT_CTS) ? MODEM_STAT_ON_COLOR : MODEM_STAT_OFF_COLOR];
    [riLabel setTextColor:(modemStatus & MODEM_STAT_RI) ? MODEM_STAT_ON_COLOR : MODEM_STAT_OFF_COLOR];
    [dsrLabel setTextColor:(modemStatus & MODEM_STAT_DSR) ? MODEM_STAT_ON_COLOR : MODEM_STAT_OFF_COLOR];
    [cdLabel setTextColor:(modemStatus & MODEM_STAT_DCD) ? MODEM_STAT_ON_COLOR : MODEM_STAT_OFF_COLOR];

    
    [rscMgr getPortStatus:&portStat];
    
    if(testRunning == YES && portStat.txAck)
    {
        // tx fifo has been drained in cable so write some more
        [rscMgr write:testData length:TEST_DATA_LEN];
        
        txCount += TEST_DATA_LEN;
        
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:nil waitUntilDone:NO];
    }
}


- (IBAction) toggleRTS:(id)sender
{
    BOOL rtsState = [rscMgr getRts];
    
    rtsState = !rtsState;
    
    if (rtsState) {
        [rtsButton setTitle:@"RTS on" forState:UIControlStateNormal];
    }
    else {
        [rtsButton setTitle:@"RTS off" forState:UIControlStateNormal];
    }
    
    [rscMgr setRts:rtsState];
}

- (IBAction) toggleDTR:(id)sender
{
    BOOL dtrState = [rscMgr getDtr];
    
    dtrState = !dtrState;
    
    if (dtrState) {
        [dtrButton setTitle:@"DTR on" forState:UIControlStateNormal];
    }
    else {
        [dtrButton setTitle:@"DTR off" forState:UIControlStateNormal];
    }
    
    [rscMgr setDtr:dtrState];
}


// upon returning from the config screen, save the configuration settings, assign their
// values to variables, and apply any changes made
- (IBAction)unwindToMainView:(UIStoryboardSegue *)segue {

    SerialConfigViewController *scvc = segue.sourceViewController;
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // don't write the baudrate value if the text field is blank
    if (![scvc.baudRateTextField.text isEqual: @""]) {
        [defaults setInteger:[scvc.baudRateTextField.text intValue] forKey:@"baudRate"];
    }
    [defaults setInteger:scvc.dataBitsSegmentedControl.selectedSegmentIndex forKey:@"dataBits"];
    [defaults setInteger:scvc.paritySegmentedControl.selectedSegmentIndex forKey:@"parity"];
    [defaults setInteger:scvc.stopBitsSegmentedControl.selectedSegmentIndex forKey:@"stopBits"];
    [defaults setInteger:scvc.rtsSegmentedControl.selectedSegmentIndex forKey:@"rts"];
    [defaults setInteger:scvc.ctsSegmentedControl.selectedSegmentIndex forKey:@"cts"];
    [defaults setInteger:scvc.debugSwitch.on forKey:@"logging"];
    [defaults setInteger:scvc.txRxSwitch.on forKey:@"showTxRx"];
    [defaults synchronize];
    
    baudRate  = (int)[defaults integerForKey:@"baudRate"];
    dataBits  = (int)[defaults integerForKey:@"dataBits"];
    parity    = (int)[defaults integerForKey:@"parity"];
    stopBits  = (int)[defaults integerForKey:@"stopBits"];
    rts       = (int)[defaults integerForKey:@"rts"];
    cts       = (int)[defaults integerForKey:@"cts"];
    logging   = (BOOL)[defaults boolForKey:@"logging"];
    showTxRx  = (BOOL)[defaults boolForKey:@"showTxRx"];
    
    [rscMgr enableExternalLogging:logging];
    [rscMgr enableTxRxExternalLogging:showTxRx];
    
    [self loadSerialSettings];

    // set baud rate, data bits, parity, and stop bits
    [rscMgr setBaud:baudRate];
    [rscMgr setDataSize:dataSizeType];
    [rscMgr setParity:parityType];
    [rscMgr setStopBits:stopBitsType];
    
    serialPortConfig portCfg;
    [rscMgr getPortConfig:&portCfg];
    portCfg.txAckSetting = 1;
    portCfg.rxFlowControl = rts;    // set flow control
    portCfg.txFlowControl = cts;
    [rscMgr setPortConfig:&portCfg requestStatus: NO];
}


// parse the configuration settings to display and apply
- (void) loadSerialSettings {
    
    NSString *dataBitsString;
    switch (dataBits) {
        case 0:
            dataBitsString = @"8";
            dataSizeType = SERIAL_DATABITS_8;
            break;
        case 1:
            dataBitsString = @"7";
            dataSizeType = SERIAL_DATABITS_7;
            break;
        default:
            break;
    }
    
    NSString *parityString;
    switch (parity) {
        case 0:
            parityString = @"N";
            parityType = 	SERIAL_PARITY_NONE;
            break;
        case 1:
            parityString = @"O";
            parityType = SERIAL_PARITY_ODD;
            break;
        case 2:
            parityString = @"E";
            parityType = SERIAL_PARITY_EVEN;
            break;
        default:
            break;
    }
    
    NSString *stopBitsString;
    switch (dataBits) {
        case 0:
            stopBitsString = @"1";
            stopBitsType = STOPBITS_1;
            break;
        case 1:
            stopBitsString = @"2";
            stopBitsType = STOPBITS_2;
            break;
        default:
            break;
    }
    
    NSString *rtsString;
    switch (rts) {
        case 0:
            rts = RXFLOW_NONE;
            rtsString = @"Off";
            break;
        case 1:
            rts = TXFLOW_CTS;
            rtsString = @"On";
            break;
        default:
            break;
    }

    NSString *ctsString;
    switch (cts) {
        case 0:
            cts = RXFLOW_NONE;
            ctsString = @"Off";
            break;
        case 1:
            cts = RXFLOW_RTS;
            ctsString = @"On";
            break;
        default:
            break;
    }

    serialSettingsLabel.text = [NSString stringWithFormat:@"%d baud, %@%@%@, RTS %@/CTS %@", baudRate, dataBitsString, parityString, stopBitsString, [rtsString lowercaseString], [ctsString lowercaseString]];
}


// display text in the terminal window
- (void)outputToTerminal:(NSString *)stringToAppend {
    
    terminalTextView.text = [NSString stringWithFormat:@"%@%@\r\n", terminalTextView.text, stringToAppend];
}


// send debug message over http
- (void) webLog:(NSString *)text color:color{
    
    if (logging) {
        [rscMgr logEvent:text color:color];
    }
}


// stop the test if the configuration view is opened
- (void)viewDidDisappear:(BOOL)animated
{
    [self clickedStop:nil];
}


// dismiss the keyboard when the user taps any area outside the textbox
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UIView * txt in self.view.subviews){
        if ([txt isKindOfClass:[UITextField class]] && [txt isFirstResponder]) {
            [txt resignFirstResponder];
        }
    }
}


// if the enter key is tapped in the text field, hide the keyboard and try to send any text
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    [self sendUserData:nil];
    return NO;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end