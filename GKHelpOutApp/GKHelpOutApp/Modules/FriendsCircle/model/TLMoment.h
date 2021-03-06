//
//  TLMoment.h
//  TLChat
//
//  Created by 李伯坤 on 16/4/7.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLMomentDetail.h"
#import "TLMomentExtension.h"
#import "TLCustomer.h"
#import "TLMomentComment.h"
#import "TLCommentDetail.h"

@class TLMomentLinkModel;
@class TLMomentFrame;
@class TLCommentDetail;

@interface TLMoment : NSObject

@property (nonatomic, strong) NSString *momentID;

@property (nonatomic, strong) UserInfo *user;

/// 发布时间
@property (nonatomic, strong) NSString *date;

@property (nonatomic, strong, readonly) NSString *showDate;

/// 来源
@property (nonatomic, strong) NSString *source;

/// 跳转链接（位置、app url等）
@property (nonatomic, strong) TLMomentLinkModel *link;

/// 详细内容
@property (nonatomic, strong) TLMomentDetail *detail;

/// 是否有赞和评论
@property (nonatomic, assign, readonly) BOOL hasExtension;
/// 附加（评论，赞）
@property (nonatomic, strong) TLMomentExtension *extension;

@property (nonatomic, strong) TLMomentFrame *momentFrame;

#pragma mark -------- add
@property (nonatomic, copy)   NSString *id;
@property (nonatomic, assign) NSInteger praiseNum; //赞数
@property (nonatomic, assign) NSInteger  commentNum; //评论数
@property (nonatomic, strong) TLCustomer *customer; //朋友圈发送人
@property (nonatomic, strong) NSArray *circleoffriendsPicture; //图片
@property (nonatomic, strong) NSString *content;    //文字内容;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *createdTime; //发布时间
@property (nonatomic, assign) BOOL praisesCircleoffriends; //是否点赞 circleoffriendsComments
//点赞
@property (nonatomic, strong) NSArray *circleoffriendsComments; //circleoffriendsComments
//点赞
@property (nonatomic, strong) NSArray<TLCommentDetail *> *showcircleoffriendsComments; //circleoffriendsComments

//第几个单元格
@property (nonatomic,assign)NSInteger index;



@end


@interface TLMomentLinkModel : NSObject

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSString *jumpUrl;

@end


@interface TLMomentFrame : NSObject

@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGFloat heightDetail;

@property (nonatomic, assign) CGFloat heightExtension;

@end

