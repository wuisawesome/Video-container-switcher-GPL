//
//  vcsAppDelegate.h
//  Video Container Switcher
//
//  Created by Florian Fahrenberger on 31.08.12.
//  Copyright (c) 2012 Florian Fahrenberger. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MULTIPLE_TEXT (@"(multiple files)")

@interface vcsAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSTextField *infileTextField;
    IBOutlet NSTextField *outputPathTextField;
    IBOutlet NSPopUpButton *formatPopUpButton;
    IBOutlet NSButton *outputPathCheckbox;
    IBOutlet NSButton *pickOutputPath;
    IBOutlet NSButton *keepFile;
    IBOutlet NSTextField *Converting;
    IBOutlet NSProgressIndicator *spinningWheel;
    IBOutlet NSTextField *DoneLabel;
    IBOutlet NSTextView *HUDDisplayText;
    
    NSArray *inputfilenames;
}

- (IBAction)clickOutputPathCheckbox:(id)sender;

- (IBAction)clickFileButton:(id)sender;

- (IBAction)clickPathButton:(id)sender;

- (IBAction)clickConvertButton:(id)sender;

- (IBAction)hideShowHUD:(id)sender;

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;


@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *HUD;
@property (strong) NSArray *inputfilenames;

@end
