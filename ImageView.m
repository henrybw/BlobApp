/*
 ---------------------------------------------------------------------------
 BlobApp -- ImageView.m
 Author: Henry Weiss
 Last Modified: 1/16/08
 ---------------------------------------------------------------------------
 This is our custom subclass of NSImageView to add functionality to the
 BlobApp icon.
 
 */

#import "ImageView.h"


@implementation ImageView


- (void)mouseDown:(NSEvent *)event
{
    [NSApp imageClick:event];
}

- (void)setImage:(NSImage *)image
{
    [super setImage:image];
}

- (NSImage *)image
{
    return [super image];
}

@end