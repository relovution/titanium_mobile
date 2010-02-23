/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiUIButtonBar.h"
#import "TiUIWidgetProxy.h"
#import "TiUtils.h"
#import "Webcolor.h"

@implementation TiUIButtonBar

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		selectedIndex = -1;
		isNullStyle = YES;
	}
	return self;
}

-(BOOL)hasTouchableListener
{
	// since this guy only works with touch events, we always want them
	// just always return YES no matter what listeners we have registered
	return YES;
}

-(UISegmentedControl *)segmentedControl
{
	if (segmentedControl==nil)
	{
		CGRect ourBoundsRect = [self bounds];
		segmentedControl=[[UISegmentedControl alloc] initWithFrame:ourBoundsRect];
		[segmentedControl setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
		[segmentedControl addTarget:self action:@selector(onSegmentChange:) forControlEvents:UIControlEventValueChanged];
		[self addSubview:segmentedControl];
	}
	return segmentedControl;
}


-(void)relayout:(CGRect)bounds
{
//TODO: Move this further up, because auto can be very very useful.
	[super relayout:bounds];
	BOOL inBar = [(TiUIWidgetProxy *)[self proxy] isUsingBarButtonItem];
	BOOL autoWidth = inBar || TiDimensionIsAuto([self layout]->width);
	BOOL autoHeight = inBar || TiDimensionIsAuto([self layout]->height);
	
	if (!autoWidth && !autoHeight)
	{
		return;
	}

	CGRect ourFrame = [TiUtils viewPositionRect:self];
	CGSize wantedSize = [segmentedControl sizeThatFits:ourFrame.size];
	
	if (autoWidth)
	{
		ourFrame.origin.x += (ourFrame.size.width - wantedSize.width)/2;
		ourFrame.size.width = wantedSize.width;
	}

	if (autoHeight)
	{
		ourFrame.origin.y += (ourFrame.size.height - wantedSize.height)/2;
		ourFrame.size.height = wantedSize.height;
	}

	if (inBar)
	{
		ourFrame.origin = CGPointZero;
	}
	[TiUtils setView:self positionRect:ourFrame];

}


- (void)setTabbedBar: (BOOL)newIsTabbed;
{
	[[self segmentedControl] setMomentary:!newIsTabbed];
}

-(void)useStyle:(UISegmentedControlStyle)newStyle;
{
	int segmentCount = [[self segmentedControl] numberOfSegments];
	CGFloat * segmentWidth;
	if (segmentCount > 0)
	{
		segmentWidth = malloc(sizeof(CGFloat) * segmentCount);
	}
	else
	{
		segmentWidth = NULL;
	}

	for (int thisSegmentIndex = 0; thisSegmentIndex < segmentCount; thisSegmentIndex++)
	{
		segmentWidth[thisSegmentIndex]=[segmentedControl widthForSegmentAtIndex:thisSegmentIndex];
	}
	
	[[self segmentedControl] setSegmentedControlStyle:newStyle];

	for (int thisSegmentIndex = 0; thisSegmentIndex < segmentCount; thisSegmentIndex++)
	{
		[segmentedControl setWidth:segmentWidth[thisSegmentIndex] forSegmentAtIndex:thisSegmentIndex];
	}
	
	if (segmentWidth != NULL)
	{
		free(segmentWidth);
	}
}

- (void)updateNullStyle;
{
	if (!isNullStyle)
	{
		return;
	}

	if ([(TiUIWidgetProxy *)[self proxy] isUsingBarButtonItem])
	{
		[self useStyle:UISegmentedControlStyleBar];
	}
	else
	{
		[self useStyle:UISegmentedControlStylePlain];
	}
}

-(void)setBackgroundColor_:(id)value
{
	TiColor *color = [TiUtils colorValue:value];
	[[self segmentedControl] setTintColor:[color _color]];
}

-(void)setIndex_:(id)value
{
	selectedIndex = [TiUtils intValue:value def:-1];
	[[self segmentedControl] setSelectedSegmentIndex:selectedIndex];
}

-(void)setStyle_:(id)value
{
	int newStyle = [TiUtils intValue:value def:-1];
	isNullStyle = (newStyle < 0);
	if (isNullStyle)
	{
		[self updateNullStyle];
	}
	else
	{
		[self useStyle:newStyle];
	}
}

-(void)setLabels_:(id)value
{
	[[self segmentedControl] removeAllSegments];
	if (IS_NULL_OR_NIL(value)) {
		return;
	}
	ENSURE_ARRAY(value);

	int thisSegmentIndex = 0;
	for (id thisSegmentEntry in value)
	{
		NSString * thisSegmentTitle = [TiUtils stringValue:thisSegmentEntry];
		UIImage * thisSegmentImage = nil;
		CGFloat thisSegmentWidth = 0;
		BOOL thisSegmentEnabled = YES;
		
		if ([thisSegmentEntry isKindOfClass:[NSDictionary class]])
		{
			thisSegmentTitle = [TiUtils stringValue:@"title" properties:thisSegmentEntry];
			thisSegmentImage = [TiUtils image:[thisSegmentEntry objectForKey:@"image"] proxy:[self proxy]];
			thisSegmentWidth = [TiUtils floatValue:@"width" properties:thisSegmentEntry];
			thisSegmentEnabled = [TiUtils boolValue:@"enabled" properties:thisSegmentEntry def:YES];
		}

		if (thisSegmentImage != nil)
		{
			[segmentedControl insertSegmentWithImage:thisSegmentImage atIndex:thisSegmentIndex animated:NO];
		}
		else
		{
			if (thisSegmentTitle == nil)
			{
				thisSegmentTitle = @"";
			}
			[segmentedControl insertSegmentWithTitle:thisSegmentTitle atIndex:thisSegmentIndex animated:NO];
		}

		[segmentedControl setWidth:thisSegmentWidth forSegmentAtIndex:thisSegmentIndex];
		[segmentedControl setEnabled:thisSegmentEnabled forSegmentAtIndex:thisSegmentIndex];
		thisSegmentIndex ++;
	}

	if (![segmentedControl isMomentary])
	{
		[segmentedControl setSelectedSegmentIndex:selectedIndex];
	}

	[self updateNullStyle];

}

-(IBAction)onSegmentChange:(id)sender
{
	int newIndex = [(UISegmentedControl *)sender selectedSegmentIndex];
	
	[self.proxy replaceValue:NUMINT(newIndex) forKey:@"index" notification:NO];
	
	if (newIndex == selectedIndex)
	{
		return;
	}

	selectedIndex = newIndex;

	if ([self.proxy _hasListeners:@"click"])
	{
		NSDictionary *event = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:selectedIndex] forKey:@"index"];
		[self.proxy fireEvent:@"click" withObject:event];
	}
	
	if ([(UISegmentedControl *)sender isMomentary])
	{
		selectedIndex = -1;
		[self.proxy replaceValue:NUMINT(-1) forKey:@"index" notification:NO];
	}
}

-(CGFloat)autoWidthForWidth:(CGFloat)suggestedWidth
{
	return [[self segmentedControl] sizeThatFits:CGSizeZero].width;
}

-(CGFloat)autoHeightForWidth:(CGFloat)width
{
	return [[self segmentedControl] sizeThatFits:CGSizeZero].height;
}

@end
