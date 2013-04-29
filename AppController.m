/*
 ---------------------------------------------------------------------------
 BlobApp -- AppController.m
 Author: Henry Weiss
 Last Modified: 1/16/08
 ---------------------------------------------------------------------------
 This is our custom subclass of NSApplication that intercepts events.  During
 initialization, the hot key is registered (using Carbon).  Then, we intercept
 sendEvent: and check if it was our hot key that was pressed.  If it was, then
 we toggle the wvous floater (the Blob).
 
 The hot key and intercepting event routines were derived from an Unsanity blog
 entry <http://www.unsanity.org/2002/10/20/doing-carbon-things-in-cocoa/>
 
 Major events:
 
 - 11/17/04: Now unregisters the hot keys (we forgot to in version 1.0).
 
 */

#import "AppController.h"

/*************/
/* Constants */
/*************/

// NSEvent subtypes for hot key events
enum { kEventHotKeyPressedSubtype = 6, kEventHotKeyReleasedSubtype = 9 };


@implementation AppController

/***** Register our hot keys *****/

- (id)init
{
    if (self = [super init])
    {
        EventHotKeyID hotKeyID;
        OSStatus err;  // Result returned by RegisterEventHotKey
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [self initPreferences];
        
        // Register the hot key (default is 97, or F6)
        
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobHotKey"] != 0)
        {
            err = RegisterEventHotKey([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobHotKey"], NULL, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
            
            if (err != noErr)
            {
                NSLog(@"Error while trying to register global hot key (%d)", err);  // See if an error occurred
            }
        }
        
        // Register the activation hot key (default is 98, or F7)
        
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobAppHotKey"] != 0)
        {
            err = RegisterEventHotKey([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobAppHotKey"], NULL, hotKeyID, GetApplicationEventTarget(), 0, &activateHotKeyRef);
            
            if (err != noErr)
            {
                NSLog(@"Error while trying to register activation hot key (%d)", err);  // See if an error occurred
            }
        }
        
        //
        // Register us for NSApplication activated and window closed notification
        //
        
        [notificationCenter addObserver:self selector:@selector(becomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(closeInstructionsPanel:) name:NSWindowWillCloseNotification object:helpPanel];
        
        firstRun = YES;
    }
    
    return self;
}

/***** Register the "Factory Defaults" *****/

- (void)initPreferences
{
    // Create a new dictionary to hold the preferences
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    NSDictionary *dockPrefs = [[NSDictionary alloc] initWithContentsOfFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath]];
    BOOL blobOn = [[dockPrefs objectForKey:@"wvous-floater"] boolValue];
    
    // Put defaults into the dictionary
    [defaultValues setObject:[NSNumber numberWithBool:blobOn] forKey:@"BlobVisible"];
    [defaultValues setObject:[NSNumber numberWithInt:97] forKey:@"BlobHotKey"];
    [defaultValues setObject:[NSNumber numberWithInt:98] forKey:@"BlobAppHotKey"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ShowMainPanel"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"ShowInstructions"];
    
    // Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    
    [dockPrefs release];
}

/***** Initialize the interface *****/

- (void)awakeFromNib
{
    [self updateUI];
    
    launching = YES;
    
    [self activateIgnoringOtherApps:YES];
}

/***** Validate menu items when asked for *****/

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];  // Load the preferences
    int toggleBlobKeyCode = [prefs integerForKey:@"BlobHotKey"];
    int blobAppKeyCode = [prefs integerForKey:@"BlobAppHotKey"];
    NSString *toggleBlobKeyCodeText = [NSString stringWithFormat:@"%d", toggleBlobKeyCode];
    NSString *blobAppKeyCodeText = [NSString stringWithFormat:@"%d", blobAppKeyCode];
    NSMenu *toggleBlobKeyMenu = [toggleBlobHotKey menu];
    NSMenu *showBlobAppKeyMenu = [showBlobAppHotKey menu];
    
    // Validate the Toggle Blob popup menu
    
    if ([[menuItem menu] isEqual:toggleBlobKeyMenu])
    {
        // The current key should be enabled
        
        if ([menuItem isEqual:[toggleBlobKeyMenu itemWithTitle:NSLocalizedString(toggleBlobKeyCodeText, nil)]])
        {
            return YES;
        }
        
        // Disable the other menu's selected item so there are no conflicts
        
        else if ([menuItem isEqual:[toggleBlobKeyMenu itemWithTitle:NSLocalizedString(blobAppKeyCodeText, nil)]])
        {
            // However, if the other menu's selected hot key is None, don't disable None!
            
            return ([prefs integerForKey:@"BlobAppHotKey"] == 0);
        }
        
        // All other menu items should be enabled
        
        else
        {
            return YES;
        }
    }
    
    else if ([[menuItem menu] isEqual:showBlobAppKeyMenu])
    {
        // The current key should be enabled
        
        if ([menuItem isEqual:[showBlobAppKeyMenu itemWithTitle:NSLocalizedString(blobAppKeyCodeText, nil)]])
        {
            return YES;
        }
        
        // Disable the other menu's selected item so there are no conflicts
        
        else if ([menuItem isEqual:[showBlobAppKeyMenu itemWithTitle:NSLocalizedString(toggleBlobKeyCodeText, nil)]])
        {
            // However, if the other menu's selected hot key is None, don't disable None!
            
            return ([prefs integerForKey:@"BlobHotKey"] == 0);
        }
        
        // All other menu items should be enabled
        
        else
        {
            return YES;
        }
    }
    
    return YES;  // All other menu items should be enabled
}

/***** Update the user interface *****/

- (void)updateUI
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];  // Load the preferences
    int toggleBlobKeyCode = [prefs integerForKey:@"BlobHotKey"];
    int blobAppKeyCode = [prefs integerForKey:@"BlobAppHotKey"];
    NSString *toggleBlobKeyCodeText = [NSString stringWithFormat:@"%d", toggleBlobKeyCode];
    NSString *blobAppKeyCodeText = [NSString stringWithFormat:@"%d", blobAppKeyCode];
    NSMenu *toggleBlobKeyMenu = [toggleBlobHotKey menu];
    NSMenu *showBlobAppKeyMenu = [showBlobAppHotKey menu];
    NSMenuItem *toggleBlobItem = [toggleBlobKeyMenu itemWithTitle:NSLocalizedString(toggleBlobKeyCodeText, nil)];
    NSMenuItem *showBlobAppItem = [showBlobAppKeyMenu itemWithTitle:NSLocalizedString(blobAppKeyCodeText, nil)];
    
    // If no hot keys are selected, then don't mention pressing hot keys!
    NSString *toggleBlobText = (toggleBlobKeyCode == 0) ? @"" : [NSString stringWithFormat:NSLocalizedString(@"BlobHotKeyText", nil), NSLocalizedString(toggleBlobKeyCodeText, nil)];
    NSString *activateBlobAppText = (blobAppKeyCode == 0) ? @"" : [NSString stringWithFormat:NSLocalizedString(@"ActivateBlobAppHotKeyText", nil), NSLocalizedString(blobAppKeyCodeText, nil)];
    
    // Replace the tokens with the actual keys -- just a little consideration for the user
    [helpText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"HelpText", nil), NSLocalizedString(toggleBlobText, nil), NSLocalizedString(activateBlobAppText, nil)]];
    
    // The checkboxes
    [blobStatus setState:[prefs boolForKey:@"BlobVisible"]];
    [showPanelCheckbox setState:[prefs boolForKey:@"ShowMainPanel"]];
    [showHelpCheckbox setState:[prefs boolForKey:@"ShowInstructions"]];
    
    // The popup menus (validateMenuItem: will take care of enabling/disabling the items)
    [toggleBlobHotKey selectItem:toggleBlobItem];
    [showBlobAppHotKey selectItem:showBlobAppItem];
}

- (void)imageClick:(NSEvent *)event
{
    if ([event type] == NSLeftMouseDown)
    {
        if (firstRun || ([event modifierFlags] & NSCommandKeyMask))
        {
            SEL selector = @selector(alertSheetDidEnd:returnCode:contextInfo:);  // The sheet handler
            
            NSBeginAlertSheet(NSLocalizedString(@"Title", nil), NSLocalizedString(@"OK", nil), @"", nil, mainPanel, self, nil, selector, nil, NSLocalizedString(@"Description", nil), nil); 
        }
        
        [self toggleImage];
    }
}

- (void)alertSheetDidEnd:(NSWindow *)sheet returnCode:(int)result contextInfo:(void *)contextInfo
{
    firstRun = NO;    
    [mainPanel makeKeyAndOrderFront:nil];  // Make sure the window is still visible
}

- (void)toggleImage
{
    if ([[[aboutImage image] name] isEqualToString:@"BlobApp"])
    {
        [aboutImage setImage:[NSImage imageNamed:@"BlobApp2"]];
    }
    
    else
    {
        [aboutImage setImage:[NSImage imageNamed:@"BlobApp"]];
    }
}

/***** Intercept events sent to us *****/

- (void)sendEvent:(NSEvent *)event
{
    // Check if the hot key was pressed...
    
    if ([event type] == NSSystemDefined && [event subtype] == kEventHotKeyPressedSubtype)
    {
        // Was it the one WE registered?
        
        if ([event data1] == (int)hotKeyRef)
        {
            [self toggleBlob:nil];
        }
        
        else if ([event data1] == (int)activateHotKeyRef)
        {
            [self activateIgnoringOtherApps:YES];
        }
    }
    
    [super sendEvent:event];  // Send the innocent event on its way
}

/**************************/
/* Toggle the preferences */
/**************************/

- (IBAction)toggleBlob:(id)sender
{
    /*
     * Load an AppleScript that will relaunch the Dock.  AppleScript is used
     * because you can relaunch the Dock WITHOUT having to find the Dock's
     * process ID (which takes a lengthy hack).  Plus, you can delay the
     * launch a little bit, which makes the Dock launch faster.  Why?  Because
     * otherwise, it takes a LONG time for the Dock to launch.
     */
    
    NSURL *script = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"relaunchDock.scpt"]];
    NSAppleScript *relaunchDockCommand = [[NSAppleScript alloc] initWithContentsOfURL:script error:nil];
    
    // Get the Dock's preferences and then see if the blob is on or not
    
    NSMutableDictionary *dockPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath]];
    BOOL blobOn = ![[dockPrefs objectForKey:@"wvous-floater"] boolValue];
    
    // Change the Dock's preferences
    
    [dockPrefs setObject:[NSNumber numberWithBool:blobOn] forKey:@"wvous-floater"];
    [dockPrefs writeToFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath] atomically:NO];  // Save the preferences
    
    // Run the relaunching script and relaunch the Dock, so the changes can apply
    
    [relaunchDockCommand executeAndReturnError:nil];
    
    // Update the Blob status checkbox
    
    [blobStatus setState:(blobOn) ? NSOnState : NSOffState];
    
    // Release all the stuff we've allocated memory for
    
    [relaunchDockCommand release];
    [dockPrefs release];
}

- (IBAction)changeToggleBlobHotKey:(id)sender
{
    EventHotKeyID hotKeyID;
    OSStatus err;
    
    // Unregister the old hot key (don't if there was no previous hot key)
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobHotKey"] != 0)
    {
        err = UnregisterEventHotKey(hotKeyRef);
        
        if (err != noErr)
        {
            NSLog(@"Error while trying to unregister global hot key (%d)", err);  // See if an error occurred
        }
    }
    
    // Update the preferences
    
    [[NSUserDefaults standardUserDefaults] setInteger:[toggleBlobHotKey selectedTag] forKey:@"BlobHotKey"];
    
    // Update all the settings
    
    [self updateUI];
    
    // Check if they don't want a hot key
    
    if ([toggleBlobHotKey selectedTag] == 0)
    {
        return;
    }
    
    // Register the new hot key
    
    err = RegisterEventHotKey([toggleBlobHotKey selectedTag], NULL, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
    
    if (err != noErr)
    {
         NSLog(@"Error while trying to register global hot key (%d)", err);  // See if an error occurred
    }
}

- (IBAction)changeShowBlobAppHotKey:(id)sender
{
    EventHotKeyID hotKeyID;
    OSStatus err;
    
    // Unregister the old hot key (don't if there was no previous hot key)
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"BlobAppHotKey"] != 0)
    {
        err = UnregisterEventHotKey(activateHotKeyRef);
        
        if (err != noErr)
        {
            NSLog(@"Error while trying to unregister activation hot key (%d)", err);  // See if an error occurred
        }
    }
    
    // Update the preferences
    
    [[NSUserDefaults standardUserDefaults] setInteger:[showBlobAppHotKey selectedTag] forKey:@"BlobAppHotKey"];
    
    // Update all the settings
    
    [self updateUI];
    
    // Check if they don't want a hot key
    
    if ([showBlobAppHotKey selectedTag] == 0)
    {
        return;
    }
    
    // Register the new hot key
    
    err = RegisterEventHotKey([showBlobAppHotKey selectedTag], NULL, hotKeyID, GetApplicationEventTarget(), 0, &activateHotKeyRef);
    
    if (err != noErr)
    {
        NSLog(@"Error while trying to register activation hot key (%d)", err);  // See if an error occurred
    }
}

- (IBAction)changeShowInstructions:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"ShowInstructions"];
    [self updateUI];  // Update all the settings
}

- (IBAction)changeShowMainPanel:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"ShowMainPanel"];
    [self updateUI];  // Update all the settings
}

/***** Reset the Blob to its default location *****/

- (IBAction)resetBlobLocation:(id)sender
{
    NSMutableDictionary *dockPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath]];
    NSURL *script = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"relaunchDock.scpt"]];
    NSAppleScript *relaunchDockCommand = [[NSAppleScript alloc] initWithContentsOfURL:script error:nil];
    
    // Change the Dock's preferences
    
    [dockPrefs removeObjectForKey:@"wvous-floater-pos"];
    [dockPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"wvous-floater"];
    [dockPrefs writeToFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath] atomically:NO];  // Save the preferences
    
    // Run the relaunching script and relaunch the Dock, so the changes can apply
    
    [relaunchDockCommand executeAndReturnError:nil];
    
    // Update the Blob status checkbox
    
    [blobStatus setState:NSOnState];
    
    // Release all the stuff we've allocated memory for
    
    [dockPrefs release];
    [relaunchDockCommand release];
}

/***** Revert to the default settings *****/

- (IBAction)revertToOriginal:(id)sender
{
    SEL selector = @selector(sheetDidEnd:returnCode:contextInfo:);  // The sheet handler
    
    // Run an alert sheet to see if they really want to revert to defaults
    
    NSBeginAlertSheet(NSLocalizedString(@"ResetTitle", nil), NSLocalizedString(@"Reset", nil), NSLocalizedString(@"Cancel", nil), nil, mainPanel, self, nil, selector, nil, NSLocalizedString(@"ResetDescription", nil), nil);
}

/***** Handle post-sheet stuff *****/

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)result contextInfo:(void *)contextInfo
{
    if (result == NSAlertDefaultReturn)
    {
        [self resetPreferences];  // They clicked OK, so go ahead and reset the preferences
    }
    
    [mainPanel makeKeyAndOrderFront:nil];  // Make sure the window is still visible
}

/***** Reset the preferences *****/

- (void)resetPreferences
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dockPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath]];
    NSURL *script = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"relaunchDock.scpt"]];
    NSAppleScript *relaunchDockCommand = [[NSAppleScript alloc] initWithContentsOfURL:script error:nil];
    
    // Delete the preferences
    
    [prefs removeObjectForKey:@"BlobVisible"];
    [prefs removeObjectForKey:@"BlobHotKey"];
    [prefs removeObjectForKey:@"BlobAppHotKey"];
    [prefs removeObjectForKey:@"ShowMainPanel"];
    [prefs removeObjectForKey:@"ShowInstructions"];
    
    // Change the Dock's preferences
    
    [dockPrefs removeObjectForKey:@"wvous-floater-pos"];
    [dockPrefs removeObjectForKey:@"wvous-floater"];
    [dockPrefs writeToFile:[@"~/Library/Preferences/com.apple.dock.plist" stringByExpandingTildeInPath] atomically:NO];  // Save the preferences
    
    // Run the relaunching script and relaunch the Dock, so the changes can apply
    
    [relaunchDockCommand executeAndReturnError:nil];
    
    // Update the Blob status checkbox
    
    [blobStatus setState:NSOnState];
    
    // Release all the stuff we've allocated memory for
    
    [dockPrefs release];
    [relaunchDockCommand release];
    
    [self updateUI];  // Update all the settings
}

/***** Make sure that if this is shown when launched, BlobApp is hidden *****/

- (void)closeInstructionsPanel:(NSNotification *)notification
{
    if (launching)
    {
        [self hide:nil];
    }
    
    launching = NO;  // We're not launching anymore
}

/***** Show panels when BlobApp becomes active *****/

- (void)becomeActive:(NSNotification *)notification
{
    BOOL instructionsIsOpen = NO;
    
    if (launching)
    {
        // Show the instructions/main panel, if mandated by preferences
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMainPanel"])
        {
            [mainPanel makeKeyAndOrderFront:nil];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInstructions"])
        {
            [helpPanel makeKeyAndOrderFront:nil];
            instructionsIsOpen = YES;  // Make sure we don't hide when the panel is open
        }
        
        // Don't hide BlobApp if the main panel is showing!
        
        else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMainPanel"])
        {
            [self hide:nil];
        }
        
        // Update launching status
        
        if (!instructionsIsOpen)
        {
            launching = NO;
        }
    }
    
    // BlobApp was activated -- show the main panel
    
    else
    {
        [mainPanel makeKeyAndOrderFront:nil];
    }
}

/***** When closing the main panel, BlobApp will hide *****/

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp hide:nil];
}

/***** Clean up after ourselves *****/

- (void)terminate:(id)sender
{
    // Unregister our hot keys
    
    OSStatus err = UnregisterEventHotKey(hotKeyRef);
    
    if (err != noErr)
    {
        NSLog(@"Error while trying to unregister global hot key (%d)", err);  // See if an error occurred
    }
    
    err = UnregisterEventHotKey(activateHotKeyRef);
    
    if (err != noErr)
    {
        NSLog(@"Error while trying to unregister activation hot key (%d)", err);  // See if an error occurred
    }
    
    // Unregister ourselves from the notification center
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super terminate:sender];  // ...and then quit
}

@end