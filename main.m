/*
 ---------------------------------------------------------------------------
 BlobApp -- main.m
 Author: Henry Weiss
 Last Modified: 1/16/08
 ---------------------------------------------------------------------------
 This calls sharedApplication: from AppController before sharedApplication:
 gets called from NSApplication.  Because sharedApplication will not create
 NSApp if it is already exists, we make NSApp an instance of AppController,
 our custom NSApplication subclass.  So when NSApplicationMain() calls
 sharedApplication: from NSApplication, NSApp will remain an instance of
 AppController.
 
 Why this low-level hack?  We want to intercept system-defined hot keys,
 which we register during program initialization.  So we have to subclass
 NSApplication.  Part two of this hack involves changing the NSPrincipalClass
 entry in Info.plist from NSApplication to AppController.
 
 */

#import <Cocoa/Cocoa.h>
#import "AppController.h"

int main(int argc, const char *argv[])
{
    // Make NSApp an instance of AppController, not NSApplication
    [AppController sharedApplication];
    
    return NSApplicationMain(argc, argv);  // Okay, continue...
}