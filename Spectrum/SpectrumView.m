//
//  SpectrumView.m
//  Spectrum
//
//  Created by OS on 2019/5/5.
//  Copyright © 2019 Whde. All rights reserved.
//

#import "SpectrumView.h"
#include "math.h"
@interface SpectrumView ()
@property (nonatomic, strong) NSMutableArray * itemLineLayers;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) CGFloat itemWidth;
@property (nonatomic) CGFloat lineWidth;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation SpectrumView


- (id)init {
    if(self = [super init]) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.itemColor = [UIColor colorWithRed:253/255.f green:111/255.f blue:82/255.f alpha:1.0];
    self.itemLineLayers = [[NSMutableArray alloc] init];
    self.lineWidth = 3;
}

#pragma mark - layout
- (void)layoutSubviews {
    [super layoutSubviews];
    self.itemHeight = CGRectGetHeight(self.bounds);
    self.itemWidth = CGRectGetWidth(self.bounds);
    [self updateItems];
}

#pragma mark - setter

- (void)setItemColor:(UIColor *)itemColor {
    _itemColor = itemColor;
    for (CAShapeLayer *itemLine in self.itemLineLayers) {
        itemLine.strokeColor = [self.itemColor CGColor];
    }
}

- (CAShapeLayer *)deqLayer {
    CAShapeLayer *itemLine = self.itemLineLayers.firstObject;
    if (itemLine) {
        [self.itemLineLayers removeObject:itemLine];
        return itemLine;
    }
    itemLine = [CAShapeLayer layer];
    itemLine.lineCap       = kCALineCapRound;
    itemLine.lineJoin      = kCALineJoinRound;
    itemLine.strokeColor   = [[UIColor clearColor] CGColor];
    itemLine.fillColor     = [[UIColor clearColor] CGColor];
    itemLine.strokeColor   = [self.itemColor CGColor];
    itemLine.lineWidth     = self.lineWidth;
    [self.layer addSublayer:itemLine];
    return itemLine;
}

- (void)setItemLevelCallback:(void (^)(void))itemLevelCallback {
    _itemLevelCallback = itemLevelCallback;
}


- (void)setLevel:(CGFloat)level { // -160 ~ 0
    NSArray *layers = self.layer.sublayers;
    int m = arc4random_uniform((int)layers.count);
    CAShapeLayer *layer = [layers objectAtIndex:m];
    float   minDecibels = -80.0f;
    float   decibels    = level;
    if (decibels < minDecibels) {
        level = 0.0f;
    } else if (decibels >= 0.0f) {
        level = 1.0f;
    } else {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        level = powf(adjAmp, 1.0f / root);
    }
    level = level*0.9;
    layer.strokeStart = 0.45-level/2;
    layer.strokeEnd = 0.55+level/2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        layer.strokeStart = 0.45;
        layer.strokeEnd = 0.55;
    });
}

- (void)setLevels:(NSArray<NSNumber *> *)levels {
    _levels = levels;
}
#pragma mark - update

- (void)updateItems {
    UIGraphicsBeginImageContext(self.frame.size);
    for (CAShapeLayer *layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAShapeLayer class]]) {
            [self.itemLineLayers addObject:layer];
        }
    }
    int lineOffset = self.lineWidth * 2.f;
    int leftX = 0;
    while (leftX<self.itemWidth) {
        CGFloat lineTop = 0;
        CGFloat lineBottom = self.itemHeight;
        leftX += lineOffset;
        UIBezierPath *linePathLeft = [UIBezierPath bezierPath];
        [linePathLeft moveToPoint:CGPointMake(leftX, lineBottom)];
        [linePathLeft addLineToPoint:CGPointMake(leftX, lineTop)];
        CAShapeLayer *itemLine = [self deqLayer];
        itemLine.path = [linePathLeft CGPath];
        itemLine.strokeStart = 0.48;
        itemLine.strokeEnd = 0.52;
    }
    UIGraphicsEndImageContext();
}

- (void)start {
    if (self.displayLink == nil) {
        /*
        self.displayLink = [CADisplayLink displayLinkWithTarget:_itemLevelCallback selector:@selector(invoke)];
        */
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLayers)];
        self.displayLink.frameInterval = 2;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)updateLayers {
    NSArray *layers = self.layer.sublayers;
    NSInteger num = MIN(_levels.count, layers.count);
    for (int i=0; i<num; i++) {
        CAShapeLayer *layer = [layers objectAtIndex:i];
        // CGFloat rate = sin(i/M_PI*10/_levels.count);
        CGFloat preRate = 0.2+i*1.0/self.levels.count*0.6;
        CGFloat rate = 2/(0.4*sqrtf(2*M_PI))*exp(-powf(((preRate/0.3)-1.6), 2)/(2*powf(0.4, 2)));
        CGFloat level = [_levels[i] floatValue]*rate;
        layer.strokeStart = 0.48-level;
        layer.strokeEnd = 0.52+level;
        /*
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            layer.strokeStart = 0;
            layer.strokeEnd = 0.1;
        });
        */
    }
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
    for (CAShapeLayer *layer in self.layer.sublayers) {
        layer.strokeStart = 0;
        layer.strokeEnd = 0.1;
    }
}


@end
