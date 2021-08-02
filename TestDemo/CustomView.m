//
//  CustomView.m
//  TestDemo
//
//  Created by springer on 2021/7/28.
//

#import "CustomView.h"
#import "Masonry.h"

typedef NS_ENUM(NSInteger,SliderType) {
    SliderTypeUnknown,
    SliderTypeLeftSlider,
    SliderTypeRightSlider,
};

@interface CustomView (){
    CGFloat _scrollOffset;
}

@property (nonatomic,strong)UIView *videoView;//视频视图
@property (nonatomic,strong)UIView *videoLeftMaskView;//左蒙版
@property (nonatomic,strong)UIView *videoSliderLeftView;//左滑块
@property (nonatomic,strong)UIView *videoRightMaskView;//右蒙版
@property (nonatomic,strong)UIView *videoSliderRightView;//右滑块

@property (nonatomic,assign)SliderType sliderType;
@property (nonatomic,assign)BOOL isEdit;
//固定参数
@property (nonatomic,assign,readonly)CGFloat videoLength;//视频长度
@property (nonatomic,assign,readonly)CGFloat selectMinLength;//选中最小间隔
@property (nonatomic,assign,readonly)CGFloat windowLength;//窗口长度
@property (nonatomic,assign,readonly)CGFloat leftSpace;//左间隔（为常态时，左滑块距离左边界的距离，也是选择开始距离内容背景左侧的间隔）
@property (nonatomic,assign,readonly)CGFloat rightSpace;//右间隔（为常态时，右滑块距离右边界的距离，也是选择结束距离内容背景右侧的间隔）
@property (nonatomic,assign,readonly)CGFloat edgeSpace;

//
@property (nonatomic,assign)CGFloat selectIn;//选中起点
@property (nonatomic,assign)CGFloat selectOut;//选中终点
@property (nonatomic,assign)CGFloat scrollOffset;//偏移
@property (nonatomic,assign)CGFloat videoOffset;//内容约束偏移
@property (nonatomic,assign)CGFloat videoBGLength;//内容背景长度


@end

@implementation CustomView

- (instancetype)init{
    self = [super init];
    if (self) {
        [self drawUI];
        [self layoutUI];
    }
    return self;
}
//开始设置
- (void)normalSetting{
    _sliderType = SliderTypeLeftSlider;
    _selectIn = 300.;
    _selectOut = self.videoLength;
    self.selectIn = _selectIn;
    self.selectOut = _selectOut;
    [self handleParameter];
}
- (void)setIsEdit:(BOOL)isEdit{
    _isEdit = isEdit;
    NSLog(@"isEdit ==== %d",(int)isEdit);
    self.scro.scrollEnabled = !isEdit;
    if (!isEdit) {//结束编辑
        [self handleParameter];
    }
}
#pragma mark ---静态参数计算
- (void)handleParameter{
    self.videoBGLength = self.selectOut - self.selectIn + self.leftSpace + self.rightSpace;
    self.videoOffset = self.leftSpace - self.selectIn;
    if (SliderTypeLeftSlider == self.sliderType) {//左边编辑完成后
        self.scrollOffset = 0;
    }else{//右边编辑完成后
        self.scrollOffset = self.videoBGLength - self.windowLength;
    }
}
#pragma mark ----滑块拖动
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    //获取手指位置判断在哪个滑块上
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    //按住了光标
    if (CGRectContainsPoint([self lh_extendRectWithRect:self.videoSliderLeftView.frame minWidth:50 minHeight:50], touchPoint)) {
        self.isEdit = YES;
        self.sliderType = SliderTypeLeftSlider;
        return;
    }else if(CGRectContainsPoint([self lh_extendRectWithRect:self.videoSliderRightView.frame minWidth:50 minHeight:50], touchPoint)){
        self.isEdit = YES;
        self.sliderType = SliderTypeRightSlider;
        return;
    }
    self.sliderType = SliderTypeUnknown;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    if (self.isEdit) {//
        switch (self.sliderType) {
            case SliderTypeLeftSlider:{//左滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.selectIn -= 20.;
                    [self leftSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.selectIn += 20.;
                    [self leftSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.selectIn = touchPoint.x - self.videoOffset;
                }
                break;
            }
            case SliderTypeRightSlider:{//右滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.selectOut -= 20.;
                    [self rightSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.selectOut += 20.;
                    [self rightSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.selectOut = touchPoint.x - self.videoOffset;
                }
                break;
            }
                
            default:
                break;
        }
    }
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    NSLog(@"touchesEnded:");
    if (self.sliderType == SliderTypeUnknown) {
        return;
    }
    self.isEdit = NO;
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    NSLog(@"touchesCancelled:");
    if (self.sliderType == SliderTypeUnknown) {
        return;
    }
    self.isEdit = NO;
}

#pragma mark ----set
- (void)setSelectIn:(CGFloat)selectIn{
    if (selectIn < 0) {
        _selectIn = 0;
    }else if(selectIn > (_selectOut - self.selectMinLength)){
        _selectIn = _selectOut - self.selectMinLength;
    }else{
        _selectIn = selectIn;
    }
    [self relayoutLeftSlider];
}
//左滑块 左边缘处理
- (void)leftSliderLeftEdgeLayoutHandle{
    if (_selectIn - self.edgeSpace + _videoOffset >= 0) {//只需调整scroll的偏移
        self.scrollOffset = _selectIn - self.edgeSpace + _videoOffset;
    }else{
        self.scrollOffset = 0;
        self.videoOffset = self.edgeSpace - _selectIn;
    }
}
- (void)leftSliderRightEdgeLayoutHandle{
    self.scrollOffset = self.selectIn + self.videoOffset - (self.windowLength - self.edgeSpace);
}
//右滑块 处理
- (void)rightSliderLeftEdgeLayoutHandle{
    self.scrollOffset = self.selectOut - self.edgeSpace + _videoOffset;
}
- (void)rightSliderRightEdgeLayoutHandle{
    self.videoOffset = (self.windowLength - self.edgeSpace) + self.scrollOffset - self.selectOut;
}

- (void)setSelectOut:(CGFloat)selectOut{
    if (selectOut < _selectIn + self.selectMinLength) {
        _selectOut = _selectIn + self.selectMinLength;
    }else if(selectOut > self.videoLength){
        _selectOut = self.videoLength;
    }else{
        _selectOut = selectOut;
    }
    [self relayoutRightSlider];
    if (self.isEdit) {//编辑过程中
        
    }
}
- (void)setScrollOffset:(CGFloat)scrollOffset{
    _scrollOffset = scrollOffset;
    if (self.contentOffsetBlock) {
        self.contentOffsetBlock(scrollOffset);
    }
}
- (void)setVideoBGLength:(CGFloat)videoBGLength{
    _videoBGLength = videoBGLength;
    if (self.contentWidthBlock) {
        self.contentWidthBlock(videoBGLength);
    }
}
- (void)setVideoOffset:(CGFloat)videoOffset{
    _videoOffset = videoOffset;
    [self relayoutVideoView];
}
#pragma mark ---界面约束
//左滑块
- (void)relayoutLeftSlider{
    [self.videoSliderLeftView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.videoView.mas_left).offset(_selectIn);
    }];
}
//右滑块
- (void)relayoutRightSlider{
    [self.videoSliderRightView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.videoView.mas_left).offset(_selectOut);
    }];
}
- (void)relayoutVideoView{
    [self.videoView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(_videoOffset);
    }];
}
#pragma mark ---界面
- (void)drawUI{
    [self addSubview:self.videoView];
    [self addSubview:self.videoLeftMaskView];
    [self addSubview:self.videoRightMaskView];
    [self addSubview:self.videoSliderLeftView];
    [self addSubview:self.videoSliderRightView];
}
- (void)layoutUI{
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.centerY.equalTo(self);
        make.width.mas_equalTo(self.videoLength);
        make.left.equalTo(self).offset(self.leftSpace - self.selectIn);
    }];
    [self.videoLeftMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.top.equalTo(self.videoView);
        make.right.equalTo(self.videoSliderLeftView);
    }];
    [self.videoSliderLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self);
        make.right.equalTo(self.videoView.mas_left).offset(self.selectIn);
    }];
    [self.videoRightMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.top.equalTo(self.videoView);
        make.left.equalTo(self.videoSliderRightView);
    }];
    [self.videoSliderRightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self);
        make.left.equalTo(self.videoView.mas_left).offset(self.selectOut);
    }];
}
#pragma mark ---懒加载
- (UIView *)videoView{
    if (nil == _videoView) {
        _videoView = [UIView new];
        _videoView.backgroundColor = [UIColor redColor];
    }
    return _videoView;
}
- (UIView *)videoLeftMaskView{
    if (nil == _videoLeftMaskView) {
        _videoLeftMaskView = [UIView new];
        _videoLeftMaskView.backgroundColor = [UIColor yellowColor];
    }
    return _videoLeftMaskView;
}
- (UIView *)videoSliderLeftView{
    if (nil == _videoSliderLeftView) {
        _videoSliderLeftView = [UIView new];
        _videoSliderLeftView.backgroundColor = [UIColor blueColor];
    }
    return _videoSliderLeftView;
}
- (UIView *)videoRightMaskView{
    if (nil == _videoRightMaskView) {
        _videoRightMaskView = [UIView new];
        _videoRightMaskView.backgroundColor = [UIColor yellowColor];
    }
    return _videoRightMaskView;
}
- (UIView *)videoSliderRightView{
    if (nil == _videoSliderRightView) {
        _videoSliderRightView = [UIView new];
        _videoSliderRightView.backgroundColor = [UIColor blueColor];
    }
    return _videoSliderRightView;
}

- (CGFloat)videoLength{
    return 900.;
}
- (CGFloat)selectMinLength{
    return 40.;
}
- (CGFloat)windowLength{
    return [UIScreen mainScreen].bounds.size.width;
}
- (CGFloat)leftSpace{
    return self.windowLength / 2.0;
}
- (CGFloat)rightSpace{
    return self.windowLength / 2.0;
}
- (CGFloat)scrollOffset{
    return self.scro.contentOffset.x;
}
- (CGFloat)edgeSpace{
    return 50.;
}
//扩大区域
- (CGRect)lh_extendRectWithRect:(CGRect)rect minWidth:(CGFloat)minWidth minHeight:(CGFloat)minHeight{
    CGRect rect1 = rect;
    CGFloat width = MAX(minWidth - rect1.size.width, 0);
    CGFloat height = MAX(minHeight - rect1.size.height, 0);
    rect1.origin.x = rect1.origin.x - width / 2.0;
    rect1.origin.y = rect1.origin.y - height / 2.0;
    rect1.size.width += width;
    rect1.size.height += height;
    return rect1;
}

@end
