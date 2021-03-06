//
//  HMMessageCellTableViewCell.m
//  GKHelpOutApp
//
//  Created by kky on 2019/3/4.
//  Copyright © 2019年 kky. All rights reserved.
//

#import "HMMessageCellTableViewCell.h"
#import "NSString+JsonString.h"
#import "NSString+Utils.h"

@implementation HMMessageCellTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self renderContents];
    }
    return self;
}

- (void)renderContents {
    CGFloat spacex = 15;
    
    [self addSubview:self.iconImg];
    self.iconImg.frame = CGRectMake(spacex,55/2,35,35);
    
//    [self addSubview:self.arrowImg];
    self.arrowImg.frame = CGRectMake(KScreenWidth-26,36,10,18);
    self.arrowImg.hidden = YES;
    
    [self addSubview:self.titleLab];
    self.titleLab.frame = CGRectMake(self.iconImg.right+10,_iconImg.y-10,150,30);
    
    [self addSubview:self.detailLab];
    self.detailLab.frame = CGRectMake(self.iconImg.right+10,_titleLab.bottom,KScreenWidth-100,35);
    
    [self addSubview:self.dataLab];
    self.dataLab.frame = CGRectMake(KScreenWidth-190,_iconImg.y-10,150,30);
}


-(void)setModel:(HMMessageModel *)model {
    _model = model;
    //{"content":"您于2019-03-06 07:17发布的财产纠纷咨询已有律师接单，请前往咨询。","ext":"07e6d788-dc23-4579-af50-01ed842a80d6","type":"NOTIFICATION_LEGAL_ADVICE"}
    if (ValidStr(model.content)) {
        NSDictionary *dic = [NSString dictionaryWithJsonString:model.content];
        if (ValidDict(dic)) {
            NSString *content = [dic valueForKey:@"content"];
            if (ValidStr(content)) {
                self.detailLab.text = content;
                 self.dataLab.text = [NSString changeFormatWithDateString: model.lastUpdatedTime];
            } else {
                self.detailLab.text = @"有新的可接订单,快去接单吧";
                self.dataLab.text = [NSString changeFormatWithDateString:model.createdTime];
                NSLog(@"%@",[NSString changeFormatWithDateString:model.createdTime]);
            }
        }
    }
//    self.dataLab.text = model.lastUpdatedTime;
   
    
}

#pragma mark - Setting&Getting
-(UIImageView *)iconImg{
    if (!_iconImg) {
        _iconImg = [UIImageView new];
        _iconImg.image = IMAGE_NAMED(@"HMCellMessageIcon");
    }
    return _iconImg;
}

-(UIImageView *)arrowImg{
    if (!_arrowImg) {
        _arrowImg = [UIImageView new];
        _arrowImg.image = IMAGE_NAMED(@"myarrow_icon");
    }
    return _arrowImg;
}

-(UILabel *)titleLab{
    if (!_titleLab) {
        _titleLab = [UILabel new];
        _titleLab.text = @"心理咨询";
        _titleLab.textColor = CFontColor1;
        _titleLab.font = FFont2;
        _titleLab.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLab;
}

-(UILabel *)detailLab{
    if (!_detailLab) {
        _detailLab = [UILabel new];
        _detailLab.text = @"您发布的财产纠纷咨询律师超时未处理，已关闭此,您发布的财产纠纷咨询律师超时未处理，已关闭此";
        _detailLab.numberOfLines = 0;
        _detailLab.textColor = CFontColor4;
        _detailLab.font = FFont1;
        _detailLab.textAlignment = NSTextAlignmentLeft;
    }
    return _detailLab;
}

-(UILabel *)dataLab{
    if (!_dataLab) {
        _dataLab = [UILabel new];
        _dataLab.text = @"2018-11-13 19:33";
        _dataLab.textColor = CFontColor2;
        _dataLab.font = FFont1;
        _dataLab.textAlignment = NSTextAlignmentRight;
    }
    return _dataLab;
}

@end
