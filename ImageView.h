/*
 ---------------------------------------------------------------------------
 BlobApp -- ImageView.h
 Author: Henry Weiss
 Last Modified: 1/16/08
 ---------------------------------------------------------------------------
 This is the header file that initializes all the variables, functions, and
 stuff for the ImageView class.  See "ImageView.m" for
 info on the ImageView class.
 
 */

#import <AppKit/AppKit.h>
#import "AppController.h"


@interface ImageView : NSImageView
{
}

- (void)setImage:(NSImage *)image;
- (NSImage *)image;

@end