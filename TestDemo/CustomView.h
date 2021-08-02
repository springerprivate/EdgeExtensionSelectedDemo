//
//  CustomView.h
//  TestDemo
//
//  Created by springer on 2021/7/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomView : UIView

@property (nonatomic,copy)void(^contentWidthBlock)(CGFloat contentWidth);
@property (nonatomic,copy)void(^contentOffsetBlock)(CGFloat contentOffset);

@property (nonatomic,weak)UIScrollView *scro;

- (void)normalSetting;

@end

NS_ASSUME_NONNULL_END
