//
//  ViewController.m
//  iOSReachability
//
//  Created by Karl Stenerud on 5/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <KSReachability/KSReachability.h>

@interface ViewController ()

@property(strong,nonatomic) KSReachability* internetReachability;

@property(strong,nonatomic) KSReachability* reachability;
@property(strong,nonatomic) KSReachableOperation* reachableOperation;
@property(strong,nonatomic) UIActivityIndicatorView* activityIndicator;

- (void) updateLabels;

- (void) showAlertWithTitle:(NSString*) title
                    message:(NSString*) message;

- (void) onReachabilityChanged:(NSNotification*) notification;

@end

@implementation ViewController

@synthesize hostField = _hostField;
@synthesize reachableLabel = _reachableLabel;
@synthesize wwanLabel = _wwanLabel;
@synthesize flagsLabel = _flagsLabel;
@synthesize reachability = _reachability;
@synthesize reachableOperation = _reachableOperation;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReachabilityChanged:)
                                                 name:kDefaultNetworkReachabilityChangedNotification
                                               object:nil];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    [self updateLabels];
    
    __unsafe_unretained ViewController* blockSelf = self;
    
    // Create a new reachability object.
    self.internetReachability = [KSReachability reachabilityToInternet];
    self.internetReachability.onInitializationComplete = ^(KSReachability *reachability)
    {
        NSLog(@"Internet reachability initialization complete. Reachability = %d. Flags = %x", reachability.reachable, reachability.flags);
    };
    // Set a callback.
    self.internetReachability.onReachabilityChanged = ^(KSReachability* reachability)
    {
        NSLog(@"Internet reachability changed to %d. Flags = %x (blocks)", reachability.reachable, reachability.flags);
        [blockSelf updateLabels];
    };
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reachability removeObserver:self forKeyPath:@"reachable"];
    
    self.internetReachability = nil;
    
    self.reachability = nil;
    self.reachableOperation = nil;
}

- (void)startBusySpinner
{
    self.activityIndicator.center = self.view.center;
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)stopBusySpinner
{
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
}

- (IBAction)onStartNewReachability:(id)sender
{
    [self startBusySpinner];
    #pragma unused(sender)
    __unsafe_unretained ViewController* blockSelf = self;
    NSString* hostname = self.hostField.text;
    
    if(self.reachability != nil)
    {
        [self.reachability removeObserver:self forKeyPath:@"reachable"];
    }
    
    // Create a new reachability object.
    self.reachability = [KSReachability reachabilityToHost:hostname];

    // Find out when initialization has completed.
    self.reachability.onInitializationComplete = ^(KSReachability* reachability)
    {
        NSLog(@"Initialization complete. Reachability = %d. Flags = %x", reachability.reachable, reachability.flags);
    };

    // Set a callback.
    self.reachability.onReachabilityChanged = ^(KSReachability* reachability)
    {
        NSLog(@"Reachability changed to %d. Flags = %x (blocks)", reachability.reachable, reachability.flags);
        [blockSelf updateLabels];
    };
    
    // Enable notifications via NSNotificationCenter.
    self.reachability.notificationName = kDefaultNetworkReachabilityChangedNotification;
    
    // Enable notifications via KVO.
    [self.reachability addObserver:self
                        forKeyPath:@"reachable"
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
    
    
    // Create a one-shot operation that gets fired once the host is reachable.
    self.reachableOperation = [KSReachableOperation operationWithHost:hostname
                                                            allowWWAN:NO
                                               onReachabilityAchieved:^
                               {
                                   [self stopBusySpinner];
                                   [self showAlertWithTitle:@"One-time message"
                                                    message:@"Host is reachable!"];
                               }];
    
    
    [self updateLabels];
}

- (void) updateLabels
{
    SCNetworkReachabilityFlags flags = self.reachability.flags;
    self.flagsLabel.text = [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
                            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
                            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
                            
                            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
                            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
                            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
                            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
                            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
                            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
                            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
    
    self.internetLabel.text = self.internetReachability.reachable ? @"YES" : @"NO";
    self.reachableLabel.text = self.reachability.reachable ? @"YES" : @"NO";
    self.wwanLabel.text = self.reachability.WWANOnly ? @"YES" : @"NO";
}

- (void) onInternetReachabilityChanged:(NSNotification *) notification
{
    KSReachability* reachability = (KSReachability*)notification.object;
    NSLog(@"Internet reachability changed to %d. Flags = %x (NSNotification)", reachability.reachable, reachability.flags);
}

- (void) onReachabilityChanged:(NSNotification*) notification
{
    KSReachability* reachability = (KSReachability*)notification.object;
    NSLog(@"Reachability changed to %d. Flags = %x (NSNotification)", reachability.reachable, reachability.flags);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    #pragma unused(keyPath)
    #pragma unused(change)
    #pragma unused(context)
    KSReachability* reachability = (KSReachability*)object;
    NSLog(@"Reachability changed to %d. Flags = %x (KVO)", reachability.reachable, reachability.flags);
}


- (void) showAlertWithTitle:(NSString*) title
                    message:(NSString*) message
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
