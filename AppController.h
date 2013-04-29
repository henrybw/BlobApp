/*
 ---------------------------------------------------------------------------
 BlobApp -- AppController.h
 Author: Henry Weiss
 Last Modified: 1/16/08
 ---------------------------------------------------------------------------
 This is the header file that initializes all the variables, functions, and
 stuff for the AppController class.  See "AppController.m" for
 info on the AppController class.
 
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
@class ImageView;
#import "ImageView.h"

@interface AppController : NSApplication
{
    EventHotKeyRef hotKeyRef;  // The reference key for our global hot key
    EventHotKeyRef activateHotKeyRef;  // The reference key for our activate hot key
    
    IBOutlet NSPanel *mainPanel;  // The main panel
    IBOutlet NSPanel *helpPanel;  // The help panel
    IBOutlet ImageView *aboutImage;  // The big BlobApp icon
    
    IBOutlet NSTextField *helpText;  // The text in the help panel
    IBOutlet NSButton *blobStatus;  // Blob visibility status
    IBOutlet NSPopUpButton *toggleBlobHotKey;  // Toggle Blob hot key
    IBOutlet NSPopUpButton *showBlobAppHotKey;  // Show BlobApp hot key
    IBOutlet NSButton *showPanelCheckbox;  // Show main panel on startup?
    IBOutlet NSButton *showHelpCheckbox;  // Show help panel on startup?
    
    BOOL launching;  // Are we in the process of launching?
    BOOL firstRun;  // Is this the first run?
}

- (void)initPreferences;
- (void)updateUI;
- (void)imageClick:(NSEvent *)event;
- (void)toggleImage;
- (IBAction)toggleBlob:(id)sender;
- (IBAction)changeToggleBlobHotKey:(id)sender;
- (IBAction)changeShowBlobAppHotKey:(id)sender;
- (IBAction)changeShowInstructions:(id)sender;
- (IBAction)changeShowMainPanel:(id)sender;
- (IBAction)resetBlobLocation:(id)sender;
- (IBAction)revertToOriginal:(id)sender;
- (void)resetPreferences;

@end