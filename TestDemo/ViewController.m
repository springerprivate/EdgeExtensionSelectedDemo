//
//  ViewController.m
//  TestDemo
//
//  Created by springer on 2021/7/22.
//

#import "ViewController.h"
#import "Masonry.h"
#import "CustomView.h"

@interface ViewController ()<UIScrollViewDelegate>

@property (nonatomic,strong)UIScrollView *scrView;
@property (nonatomic,strong)CustomView *contentView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self drawUI];
    [self layoutUI];
}

- (void)drawUI{
    [self.view addSubview:self.scrView];
    [self.scrView addSubview:self.contentView];
}
- (void)layoutUI{
    [self.scrView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.equalTo(self.view);
        make.height.mas_equalTo(200);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrView);
        make.height.equalTo(self.scrView);
    }];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"%f",scrollView.contentOffset.x);
}

#pragma mark ----滑块拖动
- (UIScrollView *)scrView{
    if (nil == _scrView) {
        _scrView = [UIScrollView new];
        _scrView.backgroundColor = [UIColor grayColor];
        _scrView.delegate = self;
    }
    return _scrView;
}
- (CustomView *)contentView{
    if (nil == _contentView) {
        _contentView = [CustomView new];
        _contentView.scro = self.scrView;
        _contentView.backgroundColor = [UIColor lightGrayColor];
        __weak typeof(self)weakSelf = self;
        _contentView.contentWidthBlock = ^(CGFloat contentWidth) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(contentWidth);
            }];
        };
        _contentView.contentOffsetBlock = ^(CGFloat contentOffset) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.scrView.contentOffset = CGPointMake(contentOffset, strongSelf.scrView.contentOffset.y);
        };
        [_contentView normalSetting];
    }
    return _contentView;
}

- (void)resetContentViewWithContentWidth:(CGFloat)contentWidth contentOffset:(CGFloat)contentOffset{
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(contentWidth);
    }];
    self.scrView.contentOffset = CGPointMake(contentOffset, self.scrView.contentOffset.y);
}

@end
