//
//  KLSwitch.m
//  KLSwitch
//
//  Created by Kieran Lafferty on 2013-06-15.
//  Copyright (c) 2013 Kieran Lafferty. All rights reserved.
//

#import "KLSwitch.h"

#define kSwitchTrackOnColor     [UIColor colorWithRed:83/255.0 green: 214/255.0 blue: 105/255.0 alpha: 1]
#define kSwitchTrackOffColor    [UIColor colorWithWhite: 0.9 alpha:1.0]
#define kSwitchTrackContrastColor [UIColor whiteColor]

#define kDefaultSwitchBorderWidth 2.0
//Size of knob with respect to the control - Must be a multiple of 2
#define kKnobOffset 2.0
#define kKnobTrackingGrowthRatio 1.2

#define kDefaultAnimationScaleLength 0.10
#define kDefaultAnimationSlideLength 0.20
#define kDefaultAnimationThumbGrowLength 0.20

#define kSwitchTrackContrastViewShrinkFactor 0.00
@interface KLSwitch () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) KLSwitchTrack* track;
@property (nonatomic, strong) KLSwitchKnob* trackingKnob;

//Gesture Recognizers
@property (nonatomic, strong) UIPanGestureRecognizer* panGesture;
@property (nonatomic, strong) UITapGestureRecognizer* tapGesture;

-(void) configureSwitch;
-(void) initializeDefaults;
-(void) toggleState;
@end

@implementation KLSwitch
- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder: aDecoder]) {
        [self configureSwitch];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureSwitch];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
   didChangeHandler:(changeHandler) didChangeHandler {
    if (self = [self initWithFrame: frame]) {
        _didChangeHandler = didChangeHandler;
    }
    return self;
}
-(void) initializeDefaults {
    self.onColor = kSwitchTrackOnColor;
    self.onTintColor = kSwitchTrackOnColor;
    self.tintColor = kSwitchTrackOffColor;
}
-(void) configureSwitch {
    [self initializeDefaults];
    
    //Configure visual properties of self
    [self setBackgroundColor: [UIColor clearColor]];
    
    
    // tap gesture for toggling the switch
	self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(didTap:)];
	[self.tapGesture setDelegate:self];
	[self addGestureRecognizer:self.tapGesture];
    
    
	// pan gesture for moving the switch knob manually
	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(didDrag:)];
	[self.panGesture setDelegate:self];
	[self addGestureRecognizer:self.panGesture];
    
    //Initialize the switch to off
    [self setOn:NO
       animated:NO];
}
-(void) layoutSubviews {
    [super layoutSubviews];
    /*
        View should be layered as follows : 
     
        TOP 
            trackingKnob
            onTrack
            offTrack
        BOTTOM
     */
    // Initialization code
    if (!self.track) {
        _track = [[KLSwitchTrack alloc] initWithFrame: self.bounds
                                              onColor: self.onTintColor
                                             offColor: self.tintColor
                                        contrastColor: kSwitchTrackContrastColor];
        [_track setOn: self.isOn
             animated: NO];
        [self addSubview: self.track];
    }
    if (!_trackingKnob) {
        _trackingKnob = [[KLSwitchKnob alloc] initWithParentSwitch: self];
        [_trackingKnob setParentSwitch: self];
        [_trackingKnob setBackgroundColor: self.thumbTintColor];
        [self addSubview: self.trackingKnob];
    }
}
-(void) setOnTintColor:(UIColor *)onTintColor {
    _onTintColor = onTintColor;
    [self.track setOnTintColor: onTintColor];
}
-(void) setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.track setTintColor: tintColor];
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    //[self.trackingKnob setTintColor: self.thumbTintColor];
    [self.trackingKnob setBackgroundColor: [UIColor whiteColor]];
    
    //Make the knob a circle and add a shadow
    CGFloat roundedCornerRadius = self.trackingKnob.frame.size.height/2.0;
    [self.trackingKnob.layer setBorderWidth: 0.5];
    [self.trackingKnob.layer setBorderColor: [kSwitchTrackOffColor CGColor]];
    [self.trackingKnob.layer setCornerRadius: roundedCornerRadius];
    [self.trackingKnob.layer setShadowColor: [[UIColor grayColor] CGColor]];
    [self.trackingKnob.layer setShadowOffset: CGSizeMake(0, 4)];
    [self.trackingKnob.layer setShadowOpacity: 0.60];
    [self.trackingKnob.layer setShadowRadius: 1.0];
}

-(void) toggleState {
    [self setOn: self.isOn ? NO : YES
       animated: YES];
}

-(void) didTap:(UITapGestureRecognizer*) gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self toggleState];
    }

}
-(void) didDrag:(UIPanGestureRecognizer*) gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        //Grow the thumb horizontally towards center by defined ratio
        [self.trackingKnob setIsTracking: YES
                                animated: YES];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        //If touch crosses a threshold then toggle the state
        CGPoint currentTouchLocation = [gesture locationInView: self];
        
        //Once location gets less than 0 or greater than width then toggle and cancel gesture
        if ((self.isOn && currentTouchLocation.x <= 0)
            || (!self.isOn && currentTouchLocation.x >= self.frame.size.width)) {
            [self toggleState];
        }
        
        // send off the appropriate actions (not fully tested yet)
        CGPoint locationOfTouch = [gesture locationInView:self];
        if (CGRectContainsPoint(self.bounds, locationOfTouch))
            [self sendActionsForControlEvents:UIControlEventTouchDragInside];
        else
            [self sendActionsForControlEvents:UIControlEventTouchDragOutside];
    }
    else  if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.trackingKnob setIsTracking: NO
                                animated: YES];
    }
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    [self setOn: on];
    [self.trackingKnob setIsTracking:NO
                            animated: animated];
    if (animated) {
        [self.track setOn: on
                 animated: YES];

        [UIView animateWithDuration:kDefaultAnimationSlideLength
        delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (self.isOn) {
                [self.trackingKnob  setFrame: [self.trackingKnob frameForCurrentStateForSwitch:self]];
            }
            else {
                [self.trackingKnob  setFrame: [self.trackingKnob frameForCurrentStateForSwitch: self]];
            }
        } completion: nil];
    }
}
- (void) setOn:(BOOL)on {
    _on = on;
    if (self.didChangeHandler) {
        self.didChangeHandler(_on);
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
    [self.trackingKnob setIsTracking:YES animated: YES];

    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
    [self.trackingKnob setIsTracking:NO animated:YES];
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	[self sendActionsForControlEvents:UIControlEventTouchUpOutside];
}
@end
@implementation KLSwitchKnob
-(id) initWithParentSwitch:(KLSwitch*) parentSwitch {
    if (self = [super initWithFrame: [self frameForCurrentStateForSwitch: parentSwitch]]) {
        _parentSwitch = parentSwitch;
    }
    return self;
}
-(void) setIsTracking:(BOOL)isTracking {
    if (self.isTracking != isTracking) {
        if (isTracking) {
            //Grow
            [self setFrame: [self trackingFrameForSwitch: self.parentSwitch]];
        }
        else {
            //Shrink
            [self setFrame: [self frameForCurrentStateForSwitch: self.parentSwitch]];
        }
    }
    _isTracking = isTracking;
}
-(void) setIsTracking:(BOOL)isTracking
             animated:(BOOL) animated {
    
    [UIView animateWithDuration: kDefaultAnimationThumbGrowLength
                     animations:^{
                         [self setIsTracking: isTracking];
                     }];
}
-(CGRect) trackingFrameForSwitch:(KLSwitch*) parentSwitch {
    //Round the scaled knob height to a multiple of 2
    CGFloat knobRadius = parentSwitch.bounds.size.height - roundf(kKnobOffset/2.0) * 2.0;
    CGFloat knobOffset = (parentSwitch.bounds.size.height - knobRadius)/2.0;
    
    CGFloat knobWidth = knobRadius * kKnobTrackingGrowthRatio;
    CGFloat knobHeight = knobRadius;
    
    if (parentSwitch.isOn) {
        return CGRectMake(parentSwitch.frame.size.width - (knobWidth + knobOffset), knobOffset, knobWidth, knobHeight);
    }
    else {
        return CGRectMake(knobOffset, knobOffset, knobWidth, knobHeight);
    }
}
-(CGRect) frameForCurrentStateForSwitch:(KLSwitch*) parentSwitch {
    //Round the scaled knob height to a multiple of 2
    CGFloat knobRadius = parentSwitch.bounds.size.height - roundf(kKnobOffset/2.0) * 2.0;
    CGFloat knobOffset = (parentSwitch.bounds.size.height - knobRadius)/2.0;
    
    if (parentSwitch.isOn) {
        return CGRectMake(parentSwitch.frame.size.width - knobRadius - knobOffset, knobOffset, knobRadius, knobRadius);
    }
    else {
        return CGRectMake(knobOffset, knobOffset, knobRadius, knobRadius);
    }
}
@end

@interface KLSwitchTrack ()
@property (nonatomic, strong) UIView* contrastView;
@end
@implementation KLSwitchTrack

-(id) initWithFrame:(CGRect)frame
            onColor:(UIColor*) onColor
           offColor:(UIColor*) offColor
      contrastColor:(UIColor*) contrastColor {
    if (self = [super initWithFrame: frame]) {
        _onTintColor = onColor;
        _tintColor = offColor;
        _contrastView = [[UIView alloc] initWithFrame:frame];
        [_contrastView setBackgroundColor: contrastColor];
        [_contrastView setCenter: self.center];
        
        CGFloat cornerRadius = frame.size.height/2.0;
        [self.layer setCornerRadius: cornerRadius];
        [_contrastView.layer setCornerRadius: cornerRadius];
        [self.layer setBorderWidth: 1.5];
        [self.layer setBorderColor: [kSwitchTrackOffColor CGColor]];
        [self addSubview: _contrastView];
    }
    return self;
}
-(void) setOn:(BOOL)on {
    if (on) {
        [self.layer setBorderColor: [self.onTintColor CGColor]];
        [self setBackgroundColor: self.onTintColor];
        [self shrinkContrastView];
    }
    else {
        [self.layer setBorderColor: [self.tintColor CGColor]];
        [self setBackgroundColor: self.tintColor];
        [self growContrastView];
    }
}
-(void) setOn:(BOOL)on animated:(BOOL)animated {
    if (animated) {
        //First animate the color switch
        [UIView animateWithDuration: 0.25
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self setOn: on
                                animated: NO];
                         }
                         completion:nil];
    }
    else {
        [self setOn: on];
    }
}

-(void) growContrastView {
    //Start out with contrast view small and centered
    [self.contrastView setTransform: CGAffineTransformMakeScale(kSwitchTrackContrastViewShrinkFactor, kSwitchTrackContrastViewShrinkFactor)];
    [self.contrastView setTransform: CGAffineTransformMakeScale(1, 1)];
}
-(void) shrinkContrastView {
    //Start out with contrast view the size of the track
    [self.contrastView setTransform: CGAffineTransformMakeScale(1, 1)];
    [self.contrastView setTransform: CGAffineTransformMakeScale(kSwitchTrackContrastViewShrinkFactor, kSwitchTrackContrastViewShrinkFactor)];
}

@end