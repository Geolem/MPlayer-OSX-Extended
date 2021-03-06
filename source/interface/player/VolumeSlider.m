#import "VolumeSlider.h"

#import "PlayerWindow.h"
#import "PlayerController.h"
#import "CocoaAdditions.h"

#import "Debug.h"

@implementation VolumeSliderCell
- (id)init
{
	self = [super init];
	if (self) {
		[self loadImages];
		isKnobSelected = NO;
	}
	return self;
}

- (void) dealloc
{
	[knobOff release];
	[knobOn release];
	
	[super dealloc];
}

- (void)loadImages
{
	knobOff = [[NSImage imageNamed:@"volume_knob_off"] retain];
	knobOn = [[NSImage imageNamed:@"volume_knob_on"] retain];
	knobOffsetX = 1;
	knobOffsetY = -2;
}

- (void)drawKnob:(NSRect)knobRect
{
	NSImage *knob;
	
	if(isKnobSelected)
		knob = knobOn;
	else
		knob = knobOff;

    [knob drawAtPoint:NSMakePoint(knobRect.origin.x + knobOffsetX, knobRect.origin.y - knobOffsetY)
            fromRect:NSZeroRect
           operation:NSCompositeSourceOver
            fraction:1.0
      respectFlipped:YES];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	isKnobSelected = YES;
	return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	isKnobSelected = NO;
	[super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}
@end

@implementation VolumeSlider
- (void)awakeFromNib
{
	NSSliderCell* oldCell = [self cell];
	VolumeSliderCell *cell = [[[VolumeSliderCell alloc] init] retain];

	[cell setTag:[oldCell tag]];
	[cell setTarget:[oldCell target]];
	[cell setAction:[oldCell action]];
	[cell setControlSize:[oldCell controlSize]];
	[cell setMinValue:[oldCell minValue]];
	[cell setMaxValue:[oldCell maxValue]];
	[cell setDoubleValue:[oldCell doubleValue]];
	//[cell setNumberOfTickMarks:[oldCell numberOfTickMarks]];
	//[cell setTickMarkPosition:[oldCell tickMarkPosition]];

	[self setCell:cell];
	[self setNeedsDisplay:YES];
	
	[cell release];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (![[(PlayerWindow *)[self window] playerController] handleKeyEvent:theEvent])
		[super keyDown:theEvent];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (BOOL)refusesFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return NO;
}

@end
