//
//  SpectrumView.h
//  Spectrum
//
//  Created by OS on 2019/5/5.
//  Copyright © 2019 Whde. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpectrumView : UIView

@property (nonatomic, copy) void (^itemLevelCallback)(void);
@property (nonatomic) UIColor * itemColor;
@property (nonatomic) CGFloat level;
@property (nonatomic) NSArray <NSNumber*>*levels;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
