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
    SliderTypeVideoLeftSlider,
    SliderTypeVideoRightSlider,
    SliderTypeAudioLeftSlider,
    SliderTypeAudioRightSlider,
};

@interface CustomView (){
    CGFloat _scrollOffset;
    CGFloat _recordVideoOffset;
    CGFloat _recordAudioOffset;
}

@property (nonatomic,assign)SliderType sliderType;
@property (nonatomic,assign)BOOL isEdit;
//固定参数
@property (nonatomic,assign,readonly)CGFloat selectMinLength;//选中最小间隔
@property (nonatomic,assign,readonly)CGFloat windowLength;//窗口长度
@property (nonatomic,assign,readonly)CGFloat edgeSpace;
@property (nonatomic,assign,readonly)CGFloat leftSpace;//左间隔（为常态时，左滑块距离左边界的距离，也是选择开始距离内容背景左侧的间隔）
@property (nonatomic,assign,readonly)CGFloat rightSpace;//右间隔（为常态时，右滑块距离右边界的距离，也是选择结束距离内容背景右侧的间隔）
//公共参数
@property (nonatomic,assign)CGFloat scrollOffset;//偏移
@property (nonatomic,assign)CGFloat matterBGLength;//内容背景长度
//视频
//视图
@property (nonatomic,strong)UIView *videoView;//视频视图
@property (nonatomic,strong)UIView *videoLeftMaskView;//左蒙版
@property (nonatomic,strong)UIView *videoSliderLeftView;//左滑块
@property (nonatomic,strong)UIView *videoRightMaskView;//右蒙版
@property (nonatomic,strong)UIView *videoSliderRightView;//右滑块
//
@property (nonatomic,assign)CGFloat videoSelectIn;//选中起点
@property (nonatomic,assign)CGFloat videoSelectOut;//选中终点
@property (nonatomic,assign)CGFloat videoOffset;//内容约束偏移

//音频
//视图
@property (nonatomic,strong)UIView *audioView;//音频视图
@property (nonatomic,strong)UIView *audioLeftMaskView;//左蒙版
@property (nonatomic,strong)UIView *audioSliderLeftView;//左滑块
@property (nonatomic,strong)UIView *audioRightMaskView;//右蒙版
@property (nonatomic,strong)UIView *audioSliderRightView;//右滑块
//
@property (nonatomic,assign)CGFloat audioSelectIn;//选中起点
@property (nonatomic,assign)CGFloat audioSelectOut;//选中终点
@property (nonatomic,assign)CGFloat audioOffset;//内容约束偏移

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
- (void)setWithVideoSelectIn:(CGFloat)videoSelectIn videoSelectOut:(CGFloat)videoSelectOut audioSelectIn:(CGFloat)audioSelectIn audioSelectOunt:(CGFloat)audioSelectOut{
    _videoSelectIn = videoSelectIn;
    _videoSelectOut = videoSelectOut;
    _audioSelectIn = audioSelectIn;
    _audioSelectOut = audioSelectOut;
    
    self.videoSelectIn = self.videoSelectIn;
    self.videoSelectOut = self.videoSelectOut;
    self.audioSelectIn = self.audioSelectIn;
    self.audioSelectOut = self.audioSelectOut;
    [self handleParameter];
}
#pragma mark ---静态参数计算
- (void)handleParameter{
    self.matterBGLength = MAX(self.videoSelectOut - self.videoSelectIn, self.audioSelectOut - self.audioSelectIn)  + self.leftSpace + self.rightSpace;
    self.videoOffset = self.leftSpace - self.videoSelectIn;
    self.audioOffset = self.leftSpace - self.audioSelectIn;
    if (SliderTypeVideoLeftSlider == self.sliderType || SliderTypeAudioLeftSlider == self.sliderType) {//左边编辑完成后
        self.scrollOffset = 0;
    }else if(SliderTypeVideoRightSlider == self.sliderType){//video右边编辑完成后
        self.scrollOffset = self.videoSelectOut - self.videoSelectIn;
    }else if(SliderTypeAudioRightSlider == self.sliderType){//audio右边编辑完成后
        self.scrollOffset = self.audioSelectOut - self.audioSelectIn;
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
        self.sliderType = SliderTypeVideoLeftSlider;
        return;
    }else if(CGRectContainsPoint([self lh_extendRectWithRect:self.videoSliderRightView.frame minWidth:50 minHeight:50], touchPoint)){
        self.isEdit = YES;
        self.sliderType = SliderTypeVideoRightSlider;
        return;
    }else if (CGRectContainsPoint([self lh_extendRectWithRect:self.audioSliderLeftView.frame minWidth:50 minHeight:50], touchPoint)){
        self.isEdit = YES;
        self.sliderType = SliderTypeAudioLeftSlider;
        return;
    }else if (CGRectContainsPoint([self lh_extendRectWithRect:self.audioSliderRightView.frame minWidth:50 minHeight:50], touchPoint)){
        self.isEdit = YES;
        self.sliderType = SliderTypeAudioRightSlider;
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
            case SliderTypeVideoLeftSlider:{//左滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.videoSelectIn -= 20.;
                    [self videoLeftSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.videoSelectIn += 20.;
                    [self videoLeftSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.videoSelectIn = touchPoint.x - self.videoOffset;
                }
                break;
            }
            case SliderTypeVideoRightSlider:{//右滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.videoSelectOut -= 20.;
                    [self videoRightSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.videoSelectOut += 20.;
                    [self videoRightSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.videoSelectOut = touchPoint.x - self.videoOffset;
                }
                break;
            }
            case SliderTypeAudioLeftSlider:{//左滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.audioSelectIn -= 20.;
                    [self audioLeftSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.audioSelectIn += 20.;
                    [self audioLeftSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.audioSelectIn = touchPoint.x - self.audioOffset;
                }
                break;
            }
            case SliderTypeAudioRightSlider:{//右滑块
                if (touchPoint.x - self.scrollOffset < self.edgeSpace) {//左边缘
                    self.audioSelectOut -= 20.;
                    [self audioRightSliderLeftEdgeLayoutHandle];
                }else if (self.windowLength - (touchPoint.x - self.scrollOffset) < self.edgeSpace){//右边缘
                    self.audioSelectOut += 20.;
                    [self audioRightSliderRightEdgeLayoutHandle];
                }else{//非边缘
                    self.audioSelectOut = touchPoint.x - self.audioOffset;
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
#pragma mark ---处理
//左滑块 左边缘处理
- (void)videoLeftSliderLeftEdgeLayoutHandle{
    if (_videoSelectIn - self.edgeSpace + _videoOffset >= 0) {//只需调整scroll的偏移
        self.scrollOffset = _videoSelectIn - self.edgeSpace + _videoOffset;
    }else{
        self.scrollOffset = 0;
        self.videoOffset = self.edgeSpace - _videoSelectIn;
        self.audioOffset = _recordAudioOffset + (_videoOffset - _recordVideoOffset);
    }
}
- (void)videoLeftSliderRightEdgeLayoutHandle{
    self.scrollOffset = self.videoSelectIn + self.videoOffset - (self.windowLength - self.edgeSpace);
}
//右滑块 处理
- (void)videoRightSliderLeftEdgeLayoutHandle{
    self.scrollOffset = self.videoSelectOut - self.edgeSpace + _videoOffset;
}
- (void)videoRightSliderRightEdgeLayoutHandle{
    if (self.videoSelectOut <= self.matterBGLength - self.videoOffset) {//可以只更改 偏移
        self.videoOffset = (self.windowLength - self.edgeSpace) + self.scrollOffset - self.videoSelectOut;
        self.audioOffset = _recordAudioOffset + (_videoOffset - _recordVideoOffset);
    }else{
        self.scrollOffset = self.matterBGLength - self.windowLength;
        self.videoOffset = self.matterBGLength - self.videoSelectOut;
        self.audioOffset = _recordAudioOffset + (_videoOffset - _recordVideoOffset);
    }
}
//左滑块 左边缘处理
- (void)audioLeftSliderLeftEdgeLayoutHandle{
    if (_audioSelectIn - self.edgeSpace + _audioOffset >= 0) {//只需调整scroll的偏移
        self.scrollOffset = _audioSelectIn - self.edgeSpace + _audioOffset;
    }else{
        self.scrollOffset = 0;
        self.audioOffset = self.edgeSpace - _audioSelectIn;
        self.videoOffset = _recordVideoOffset + (_audioOffset - _recordAudioOffset);
    }
}
- (void)audioLeftSliderRightEdgeLayoutHandle{
    self.scrollOffset = self.audioSelectIn + self.audioOffset - (self.windowLength - self.edgeSpace);
}
//右滑块 处理
- (void)audioRightSliderLeftEdgeLayoutHandle{
    self.scrollOffset = self.audioSelectOut - self.edgeSpace + _audioOffset;
}
- (void)audioRightSliderRightEdgeLayoutHandle{
    if (self.audioSelectOut <= self.matterBGLength - self.audioOffset) {//可以只更改 偏移
        self.audioOffset = (self.windowLength - self.edgeSpace) + self.scrollOffset - self.audioSelectOut;
        self.videoOffset = _recordVideoOffset + (_audioOffset - _recordAudioOffset);
    }else{
        self.scrollOffset = self.matterBGLength - self.windowLength;
        self.audioOffset = self.matterBGLength - self.audioSelectOut;
        self.videoOffset = _recordVideoOffset + (_audioOffset - _recordAudioOffset);
    }
}
#pragma mark ----set
- (void)setIsEdit:(BOOL)isEdit{
    _isEdit = isEdit;
    self.scro.scrollEnabled = !isEdit;
    if (!isEdit) {//结束编辑
        [self handleParameter];
    }else{
        _recordVideoOffset = _videoOffset;
        _recordAudioOffset = _audioOffset;
    }
}
- (void)setScrollOffset:(CGFloat)scrollOffset{
    _scrollOffset = scrollOffset;
    if (self.contentOffsetBlock) {
        self.contentOffsetBlock(scrollOffset);
    }
}
- (void)setMatterBGLength:(CGFloat)videoBGLength{
    _matterBGLength = videoBGLength;
    if (self.contentWidthBlock) {
        self.contentWidthBlock(videoBGLength);
    }
}
//video
- (void)setVideoSelectIn:(CGFloat)selectIn{
    if (selectIn < 0) {
        _videoSelectIn = 0;
    }else if(selectIn > (_videoSelectOut - self.selectMinLength)){
        _videoSelectIn = _videoSelectOut - self.selectMinLength;
    }else{
        _videoSelectIn = selectIn;
    }
    [self relayoutVideoLeftSlider];
}
- (void)setVideoSelectOut:(CGFloat)selectOut{
    if (selectOut < _videoSelectIn + self.selectMinLength) {
        _videoSelectOut = _videoSelectIn + self.selectMinLength;
    }else if(selectOut > self.videoLength){
        _videoSelectOut = self.videoLength;
    }else{
        _videoSelectOut = selectOut;
    }
    [self relayoutVideoRightSlider];
}
- (void)setVideoOffset:(CGFloat)videoOffset{
    _videoOffset = videoOffset;
    [self relayoutVideoView];
}
- (void)setVideoLength:(CGFloat)videoLength{
    _videoLength = videoLength;
    [self.videoView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(videoLength);
    }];
}
//audio
- (void)setAudioSelectIn:(CGFloat)audioSelectIn{
    if (audioSelectIn < 0) {
        _audioSelectIn = 0;
    }else if(audioSelectIn > (_audioSelectOut - self.selectMinLength)){
        _audioSelectIn = _audioSelectOut - self.selectMinLength;
    }else{
        _audioSelectIn = audioSelectIn;
    }
    [self relayoutAudioLeftSlider];
}
- (void)setAudioSelectOut:(CGFloat)audioSelectOut{
    if (audioSelectOut < _audioSelectIn + self.selectMinLength) {
        _audioSelectOut = _audioSelectIn + self.selectMinLength;
    }else if(audioSelectOut > self.audioLength){
        _audioSelectOut = self.audioLength;
    }else{
        _audioSelectOut = audioSelectOut;
    }
    [self relayoutAudioRightSlider];
}
- (void)setAudioOffset:(CGFloat)audioOffset{
    _audioOffset = audioOffset;
    [self relayoutAudioView];
}
- (void)setAudioLength:(CGFloat)audioLength{
    _audioLength = audioLength;
    [self.audioView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(audioLength);
    }];
}
#pragma mark ---界面约束
//左滑块
- (void)relayoutVideoLeftSlider{
    [self.videoSliderLeftView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.videoView.mas_left).offset(_videoSelectIn);
    }];
}
//右滑块
- (void)relayoutVideoRightSlider{
    [self.videoSliderRightView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.videoView.mas_left).offset(_videoSelectOut);
    }];
}
- (void)relayoutVideoView{
    [self.videoView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(_videoOffset);
    }];
}
//左滑块
- (void)relayoutAudioLeftSlider{
    [self.audioSliderLeftView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.audioView.mas_left).offset(_audioSelectIn);
    }];
}
//右滑块
- (void)relayoutAudioRightSlider{
    [self.audioSliderRightView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioView.mas_left).offset(_audioSelectOut);
    }];
}
- (void)relayoutAudioView{
    [self.audioView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(_audioOffset);
    }];
}
#pragma mark ---界面
- (void)drawUI{
    [self addSubview:self.videoView];
    [self addSubview:self.videoLeftMaskView];
    [self addSubview:self.videoRightMaskView];
    [self addSubview:self.videoSliderLeftView];
    [self addSubview:self.videoSliderRightView];
    
    [self addSubview:self.audioView];
    [self addSubview:self.audioLeftMaskView];
    [self addSubview:self.audioRightMaskView];
    [self addSubview:self.audioSliderLeftView];
    [self addSubview:self.audioSliderRightView];
}
- (void)layoutUI{
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.top.equalTo(self).offset(10);
        make.width.mas_equalTo(self.videoLength);
        make.left.equalTo(self).offset(0);
    }];
    [self.videoLeftMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.top.equalTo(self.videoView);
        make.right.equalTo(self.videoSliderLeftView);
    }];
    [self.videoSliderLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self.videoView);
        make.right.equalTo(self.videoView.mas_left).offset(self.videoSelectIn);
    }];
    [self.videoRightMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.top.equalTo(self.videoView);
        make.left.equalTo(self.videoSliderRightView);
    }];
    [self.videoSliderRightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self.videoView);
        make.left.equalTo(self.videoView.mas_left).offset(self.videoSelectOut);
    }];
    
    [self.audioView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.bottom.equalTo(self).offset(-10);
        make.width.mas_equalTo(self.audioLength);
        make.left.equalTo(self).offset(0);
    }];
    [self.audioLeftMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.top.equalTo(self.audioView);
        make.right.equalTo(self.audioSliderLeftView);
    }];
    [self.audioSliderLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self.audioView);
        make.right.equalTo(self.audioView.mas_left).offset(self.audioSelectIn);
    }];
    [self.audioRightMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.top.equalTo(self.audioView);
        make.left.equalTo(self.audioSliderRightView);
    }];
    [self.audioSliderRightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 50));
        make.centerY.equalTo(self.audioView);
        make.left.equalTo(self.audioView.mas_left).offset(self.audioSelectOut);
    }];
}
#pragma mark ---懒加载
- (CGFloat)selectMinLength{
    return 40.;
}
- (CGFloat)windowLength{
    return [UIScreen mainScreen].bounds.size.width;
}
- (CGFloat)edgeSpace{
    return 50.;
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
- (UIView *)audioView{
    if (nil == _audioView) {
        _audioView = [UIView new];
        _audioView.backgroundColor = [UIColor redColor];
    }
    return _audioView;
}
- (UIView *)audioLeftMaskView{
    if (nil == _audioLeftMaskView) {
        _audioLeftMaskView = [UIView new];
        _audioLeftMaskView.backgroundColor = [UIColor yellowColor];
    }
    return _audioLeftMaskView;
}
- (UIView *)audioSliderLeftView{
    if (nil == _audioSliderLeftView) {
        _audioSliderLeftView = [UIView new];
        _audioSliderLeftView.backgroundColor = [UIColor blueColor];
    }
    return _audioSliderLeftView;
}
- (UIView *)audioRightMaskView{
    if (nil == _audioRightMaskView) {
        _audioRightMaskView = [UIView new];
        _audioRightMaskView.backgroundColor = [UIColor yellowColor];
    }
    return _audioRightMaskView;
}
- (UIView *)audioSliderRightView{
    if (nil == _audioSliderRightView) {
        _audioSliderRightView = [UIView new];
        _audioSliderRightView.backgroundColor = [UIColor blueColor];
    }
    return _audioSliderRightView;
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
