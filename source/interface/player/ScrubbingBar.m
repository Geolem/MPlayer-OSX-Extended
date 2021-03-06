/*
 *  ScrubbingBar.h
 *  MPlayer OS X
 *
 *  Created by Jan Volf on Mon Apr 14 2003.
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#import "ScrubbingBar.h"
#import "Debug.h"

@implementation ScrubbingBar
- (void)awakeFromNib
{
	myStyle = MPEScrubbingBarEmptyStyle;
	// load images that forms th scrubbing bar
	[self loadImages];
	
	// Register for notification to check when we need to redraw the animation image
	[self setPostsFrameChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(redrawAnim) name:NSViewFrameDidChangeNotification object:nil];
	[self redrawAnim];
	    
	[self setNeedsDisplay:YES];
}

- (void)redrawAnim
{
	int frameWidth = [scrubBarAnimFrame size].width;
	
	// Only redraw if current image is too small
	if ([scrubBarAnim size].width > [self frame].size.width + frameWidth)
		return;
	
	NSSize animSize = NSMakeSize([self frame].size.width+(frameWidth*3),[self frame].size.height);
	[scrubBarAnim release];
	scrubBarAnim = [[NSImage alloc] initWithSize:animSize];
	
	[scrubBarAnim lockFocus];
	int numFrames = round([scrubBarAnim size].width/frameWidth);
	int i = 0;
	for (i = 0; i < numFrames; i++)
	{
        [scrubBarAnimFrame drawAtPoint:NSMakePoint(i * frameWidth, 0)
                              fromRect:NSZeroRect
                             operation:NSCompositeCopy
                              fraction:1.0];
    }
	[scrubBarAnim unlockFocus];
}

- (void) loadImages
{
	scrubBarEnds = [[NSImage imageNamed:@"bar_ends"] retain];
	scrubBarRun = [[NSImage imageNamed:@"bar_run"] retain];
	scrubBarBadge = [[NSImage imageNamed:@"bar_pointer"] retain];
	scrubBarAnimFrame = [[NSImage imageNamed:@"bar_inter"] retain];;
	
	yBadgeOffset = 0;
	xBadgeOffset = 7;
	leftClip = 2;
	rightClip = 2;
}

- (void) dealloc
{
	[scrubBarEnds release];
	[scrubBarRun release];
	[scrubBarBadge release];
	[scrubBarAnimFrame release];
	[scrubBarAnim release];
	
	if (animationTimer) {
		[animationTimer invalidate];
		[animationTimer release];
	}
	
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if ([self scrubStyle] == MPEScrubbingBarPositionStyle)
		postNotification(self, theEvent, [scrubBarBadge size]);
}
- (void)mouseDragged:(NSEvent *)theEvent
{
	if ([self scrubStyle] == MPEScrubbingBarPositionStyle)
		postNotification(self, theEvent, [scrubBarBadge size]);
}
- (BOOL)mouseDownCanMoveWindow
{
	if ([self scrubStyle] == MPEScrubbingBarPositionStyle)
		return NO;
	return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	if ([self scrubStyle] == MPEScrubbingBarPositionStyle)
		return YES;
	return NO;
}

- (BOOL)isFlipped
{	
	return NO;
}

- (void)drawRect:(NSRect)aRect
{
	NSSize viewSize = [self bounds].size;
	float runLength = viewSize.width - [scrubBarEnds size].width;
	float endWidth = [scrubBarEnds size].width / 2;		// each half of the picture is one end
	double theValue = [self doubleValue] / ([self maxValue] - [self minValue]);	
	
	//draw bar end left and right
	[scrubBarEnds drawAtPoint:NSMakePoint(0, 0)
                     fromRect:NSMakeRect(0,0,endWidth,[scrubBarEnds size].height)
                    operation:NSCompositeSourceOver
                     fraction:1.0];
    [scrubBarEnds drawAtPoint:NSMakePoint(viewSize.width - endWidth,0)
                     fromRect:NSMakeRect(endWidth,0,endWidth,[scrubBarEnds size].height)
                    operation:NSCompositeSourceOver
                     fraction:1.0];
	
	// resize the bar run frame if needed
	if ([scrubBarRun size].width != runLength)
	{
		[scrubBarRun setSize:NSMakeSize(runLength, [scrubBarRun size].height)];
		[scrubBarRun recache];
	}
    [scrubBarRun drawAtPoint:NSMakePoint(endWidth,0)
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1.0];
	
	if ([self scrubStyle] == MPEScrubbingBarPositionStyle) {
		// calculate actual x-position of badge with badge offset and shadow
		CGFloat badgePosX = (viewSize.width - rightClip - leftClip) * theValue + leftClip - xBadgeOffset;
		
		NSSize badgeSize = [scrubBarBadge size];
		NSRect badgeRect = NSMakeRect(0, 0, badgeSize.width, badgeSize.height);
		
		// Clip the badge when on the far left/right side to make it disappear behind the chrome
		if (badgePosX < leftClip) {
			CGFloat amount = leftClip - badgePosX;
			badgeRect.size.width -= amount;
			badgeRect.origin.x += amount;
			badgePosX = leftClip;
		} else if (badgePosX + badgeSize.width > viewSize.width - rightClip) {
			CGFloat amount = (badgePosX + badgeSize.width) - (viewSize.width - rightClip);
			badgeRect.size.width = fmax(badgeRect.size.width - amount, 0);
		}
		
        [scrubBarBadge drawAtPoint:NSMakePoint(badgePosX, yBadgeOffset)
                          fromRect:badgeRect
                         operation:NSCompositeSourceOver
                          fraction:1.0];
		
	} else if ([self scrubStyle] == MPEScrubbingBarProgressStyle) {
		[scrubBarAnim 
			drawInRect:NSMakeRect(0, 0, viewSize.width - rightClip, viewSize.height)
			fromRect:NSMakeRect((1.0 - animFrame) * [scrubBarAnimFrame size].width, 0, viewSize.width - rightClip, [scrubBarAnim size].height)
			operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (void)animate:(NSTimer *)aTimer
{
	if ([[self window] isVisible]) {
		animFrame += 0.1;
		if(animFrame>1) animFrame=0;
		[self setNeedsDisplay:YES];
	}
}

- (NSScrubbingBarStyle)scrubStyle
{
	return myStyle;
}

- (void)setScrubStyle:(NSScrubbingBarStyle)style
{
	myStyle = style;
	if (style == MPEScrubbingBarProgressStyle)
		[self startAnimation:self];
	else
		[self stopAnimation:self];
	[self setNeedsDisplay:YES];
}

- (void)startAnimation:(id)sender
{
    if (animationTimer == NULL) {
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 
                                                           target:self selector:@selector(animate:) 
                                                         userInfo:nil repeats:YES] retain];
		
	}
}

- (void)stopAnimation:(id)sender
{
    if (animationTimer) {
		[animationTimer invalidate];
		[animationTimer release];
		animationTimer = NULL;		
	}
}

- (void)incrementBy:(double)delta
{
	[super incrementBy:delta];
	[self setNeedsDisplay:YES];
}

- (void)setDoubleValue:(double)doubleValue
{
	[super setDoubleValue:doubleValue];
	[self setNeedsDisplay:YES];
}

- (void)setIndeterminate:(BOOL)flag
{
	[super setIndeterminate:flag];
	[self setNeedsDisplay:YES];
}

- (void)setMaxValue:(double)newMaximum
{
	[super setMaxValue:newMaximum];
	[self setNeedsDisplay:YES];
}

- (void)setMinValue:(double)newMinimum
{
	[super setMinValue:newMinimum];
	[self setNeedsDisplay:YES];
}

@end

int postNotification (id self, NSEvent *theEvent, NSSize badgeSize)
{
	NSPoint thePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	double theValue;
	float minX = NSMinX([self bounds]),
		maxX = NSMaxX([self bounds]);
	
	// set the value
	if (thePoint.x < minX)
		theValue = [self minValue];
	else if (thePoint.x >= maxX)
		theValue = [self maxValue];
	else
		theValue = [self minValue] + (([self maxValue] - [self minValue]) *
				(thePoint.x - minX) / (maxX - minX));
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName:@"SBBarClickedNotification"
			object:self
			userInfo:[NSDictionary 
					dictionaryWithObject:[NSNumber numberWithDouble:theValue]
					forKey:@"SBClickedValue"]];
	
	return 1;
}
