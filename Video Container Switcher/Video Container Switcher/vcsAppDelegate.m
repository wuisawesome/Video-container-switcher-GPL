//
//  vcsAppDelegate.m
//  Video Container Switcher
//
//  Created by Florian Fahrenberger on 31.08.12.
//  Copyright (c) 2012 Florian Fahrenberger. All rights reserved.
//

#import "vcsAppDelegate.h"

@implementation vcsAppDelegate

/* inputfilenames can be manipulated by all classes! */
@synthesize inputfilenames;


/* things to do in the very beginning */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* allocate inputfilenames variable */
    inputfilenames = [[NSArray alloc] init];
    /* set colors for Text in Heads Up Display */
    [HUDDisplayText setBackgroundColor:[NSColor clearColor]];
    [HUDDisplayText setTextColor:[NSColor lightGrayColor]];
}


/* class is called if the "Browse" button for input files is clicked */
- (IBAction)clickFileButton:(id)sender;
{
    /* File dialog properties: Multiple files, no directories */
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:YES];
    [openDlg setCanChooseDirectories:NO];
    
    /* If "OK" is chosen, save the file names into global variable */
    if ( [openDlg runModal] == NSOKButton )
    {
        inputfilenames = [openDlg URLs];

        if ([inputfilenames count] == 1) {
            infileTextField.stringValue = [[inputfilenames objectAtIndex:0] path];
            [outputPathTextField setEditable:TRUE];
            [outputPathTextField setEnabled:TRUE];
        } else {
            infileTextField.stringValue = MULTIPLE_TEXT;
            [outputPathTextField setEditable:TRUE];
            [outputPathTextField setEnabled:TRUE];
        }
    }

}


/* class is called if the "Browse" button for output path is clicked */
- (IBAction)clickPathButton:(id)sender;
{
    /* File dialog properties: Only directories */
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    
    /* If "OK" is chosen, save new path in Textfield */
    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray *outputPath = [openDlg URLs];
        outputPathTextField.stringValue = [[outputPath objectAtIndex:0] path];
    }    
}


/* class is called when Checkbox "same as input path" is changed */
- (IBAction)clickOutputPathCheckbox:(id)sender;
{
    /* enable/disable Textfield and "Browse" button accordingly */
    if ([outputPathCheckbox state] == NSOnState) {
        [outputPathTextField setEditable:FALSE];
        [outputPathTextField setEnabled:FALSE];
        [pickOutputPath setEnabled:FALSE];
    } else {
        [outputPathTextField setEditable:TRUE];
        [outputPathTextField setEnabled:TRUE];
        [pickOutputPath setEnabled:TRUE];
    }
        
}


- (IBAction)hideShowHUD:(id)sender;
{
    if ([_HUD isVisible])
        [_HUD orderOut:self];
    else
        [_HUD orderFront:self];
}

/* class is called when "Convert" button is pressed */
- (IBAction)clickConvertButton:(id)sender;
{
    /* Is there only a single file? If so the user may have changed it manually instead of using browse */
    if (![infileTextField.stringValue isEqualToString:MULTIPLE_TEXT]){
        inputfilenames = [[NSArray alloc] initWithObjects:[NSURL URLWithString:infileTextField.stringValue], nil];
    }
    
    /* How many files are we dealing with? */
    NSInteger numberOfFiles;
    numberOfFiles = [inputfilenames count];
    
    /* Is the HUD visible? */
    bool HUDvisible = [_HUD isVisible];
    
    /* show spinning wheel etc. */
    [DoneLabel setHidden:TRUE];
    [Converting setHidden:FALSE];
    [spinningWheel setHidden:FALSE];
    [spinningWheel startAnimation:sender];
    
     for( int i = 0; i < numberOfFiles; i++ )
     {
         /* convert URL to path. ffmpeg doesn't like URLs. */
         NSString *inFile = [[inputfilenames objectAtIndex:i] path];
         Converting.stringValue = [NSString stringWithFormat:@"Converting %d of %ld ...", (i+1), numberOfFiles];
         
         /* determine file names */
         NSString *inFilePath = [inFile stringByDeletingLastPathComponent];
         NSString *inFileBase = [[inFile lastPathComponent] stringByDeletingPathExtension];
         NSString *outFilePath = inFilePath;
         if ([outputPathCheckbox state] == NSOffState) outFilePath = [outputPathTextField stringValue];
         NSString *outFileEnd = formatPopUpButton.titleOfSelectedItem;
         NSString *outFile =
            [[outFilePath stringByAppendingPathComponent:inFileBase] stringByAppendingPathExtension:outFileEnd];
         
         /* if target file already exists */
         if ([[NSFileManager defaultManager] fileExistsAtPath:outFile]) {
             /* Alert box prompted */
             NSAlert *overwriteAlert = [[NSAlert alloc] init];
             NSString *messageText =
                [NSString stringWithFormat:@"The file %@.%@ already exists.", inFileBase, outFileEnd];
            [overwriteAlert setMessageText:messageText];
            [overwriteAlert addButtonWithTitle:@"Overwrite"];
            [overwriteAlert addButtonWithTitle:@"Append number"];
             
            NSInteger choice = [overwriteAlert runModal];
             
             /* If used chose "Append number", append .(j) to filename
              with the lowest number j for which the file doesn't exist yet */
             if (choice == NSAlertSecondButtonReturn) {
                 int j=1;
                 while ([[NSFileManager defaultManager] fileExistsAtPath:outFile]) {
                     NSString *appendix = [NSString stringWithFormat:@"(%d)", j];
                     outFile =
                     [[[outFilePath stringByAppendingPathComponent:inFileBase]
                       stringByAppendingPathExtension:appendix]
                       stringByAppendingPathExtension:outFileEnd];
                     j+=1;
                 }
             }
             
             
         }
         
         /* concatenate execution command and arguments */
         NSArray *argumentsArray =
            [NSArray arrayWithObjects:@"-i", inFile, @"-acodec", @"copy", @"-vcodec", @"copy", @"-y", outFile, nil];
         NSString *execPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ffmpeg"];
         
         /* call conversion command and wait until it's finished */
         /* pipe output to Heads Up Display */
         NSPipe *pipe = [NSPipe pipe];
         NSFileHandle *handle = NULL;
         NSTask *conversiontask = [[NSTask alloc] init];
         [conversiontask setLaunchPath:execPath];
         [conversiontask setArguments:argumentsArray];
         [conversiontask setStandardOutput:pipe];
         [conversiontask setStandardError:pipe];
         [conversiontask launch];

         [conversiontask waitUntilExit];
         handle = [pipe fileHandleForReading];
         NSString *outputLines = [[NSString alloc]
                                  initWithData:[handle readDataToEndOfFile]
                                  encoding:NSASCIIStringEncoding];
         [HUDDisplayText insertText:outputLines];
         
         /* if ffmpeg does not exit with code 0 */
         if ([conversiontask terminationStatus] != 0) {
             /* something went very wrong */
             /* Make output visible */
             if (!HUDvisible) [_HUD orderFront:self];
             /* alert user with filename info */
             NSAlert *errorAlert = [[NSAlert alloc] init];
             NSString *messageText =
             [NSString stringWithFormat:@"Couldn't convert file %@. Sorry.", [inFile lastPathComponent]];
             [errorAlert setMessageText:messageText];
             [errorAlert addButtonWithTitle:@"OK"];
             [errorAlert runModal];
             /* delete unusable target file */
             [NSTask launchedTaskWithLaunchPath:@"/bin/rm" arguments:[NSArray arrayWithObject:outFile]];
             /* Make output not visible anymore (if it wasn't before...) */
             if (!HUDvisible) [_HUD orderOut:self];
         } /* only if everything went fine, possibly delete file! */
         else if ([keepFile state] == NSOffState) {
            /* delete original if wanted */
             [NSTask launchedTaskWithLaunchPath:@"/bin/rm" arguments:[NSArray arrayWithObject:inFile]];
         }
     }

    /* Done, stop spinning wheel etc. */
    [spinningWheel stopAnimation:sender];
    [Converting setHidden:TRUE];
    [spinningWheel setHidden:TRUE];
    [DoneLabel setHidden:FALSE];
    
}


@end
