//
//  UserManager.m
//  MiAiApp
//
//  Created by 徐阳 on 2017/5/22.
//  Copyright © 2017年 徐阳. All rights reserved.
//

#import "UserManager.h"
#import <UMSocialCore/UMSocialCore.h>
#import <AFNetworking.h>
#import "Mine_AuthLogic.h"
#import "lawyerInfo.h"
#import "LawUserInfo.h"
@implementation UserManager

SINGLETON_FOR_CLASS(UserManager);

-(instancetype)init{
    self = [super init];
    if (self) {
        //被踢下线
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKick)
                                                     name:KNotificationOnKick
                                                   object:nil];
    }
    return self;
}

#pragma mark ————— 三方登录 —————
-(void)login:(UserLoginType )loginType completion:(loginBlock)completion{
    [self login:loginType params:nil completion:completion];
}

#pragma mark ————— 带参数登录 —————
-(void)login:(UserLoginType )loginType params:(NSDictionary *)params completion:(loginBlock)completion{
    //友盟登录类型
    UMSocialPlatformType platFormType;
    
    if (loginType == kUserLoginTypeQQ) {
        platFormType = UMSocialPlatformType_QQ;
    }else if (loginType == kUserLoginTypeWeChat){
        platFormType = UMSocialPlatformType_WechatSession;
    }else{
        platFormType = UMSocialPlatformType_UnKnown;
    }
    //第三方登录
    if (loginType != kUserLoginTypePwd) {
        [MBProgressHUD showActivityMessageInView:@"授权中..."];
        [[UMSocialManager defaultManager] getUserInfoWithPlatform:platFormType currentViewController:nil completion:^(id result, NSError *error) {
            if (error) {
                [MBProgressHUD hideHUD];
                if (completion) {
                    completion(NO,error.localizedDescription);
                }
            } else {
                
                UMSocialUserInfoResponse *resp = result;

                
                //登录参数
                NSDictionary *params = @{@"openid":resp.openid, @"nickname":resp.name, @"photo":resp.iconurl, @"sex":[resp.unionGender isEqualToString:@"男"]?@1:@2, @"cityname":resp.originalResponse[@"city"], @"fr":@(loginType)};
                
                self.loginType = loginType;
                //登录到服务器
                [self loginToServer:params refresh:NO  completion:completion];
            }
        }];
    }else{
        //账号登录 暂未提供
        
    }
}
#pragma mark ————— 注册账号或者判断账号是否存在 —————


-(void)requestEcomRegister:(NSDictionary *)parmeters {
    
    NSString *url = NSStringFormat(@"%@%@",EmallHostUrl,URL_post_registe);
    AFHTTPSessionManager* manager=[AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = 10.f;
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
//    NSDictionary*parmeters=@{
//                             @"phoneNumber":self.phoneNumber,
//                             @"verificationCode":self.verificationCode,
//                             @"name":self.phoneNumber,//姓名是手机号码
//                             @"group":@"CUSTOMER"
//                             };
    [manager POST:url parameters:parmeters progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse * responses = (NSHTTPURLResponse *)task.response;
        NSInteger code = responses.statusCode;
        if (code == 201) {
            [self loginToServer:parmeters refresh:NO completion:nil];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (ValidData(data)) {
            id body = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSString*code=body[@"code"];
            if ([code isEqualToString:@"user.PhoneNumberExisted"]) {
                //            [self EcommerceOfLogin];
                [self loginToServer:parmeters refresh:NO  completion:nil];
            }
            else if ([code isEqualToString:@"user.SmsVerificationCodeNotMatched"]){
                [PSTipsView showTips:@"短信验证码不匹配"];
            }
            
            else {
               [PSTipsView showTips:@"服务器异常"];
            }
        }
    }];

}

#pragma mark ————— 手动登录到服务器 —————

//获取公共服务token  //refresh 是否是刷新token
static const NSString *uid =  @"assistant.app";
static const NSString *cipherText =  @"506a7b6dfc5d42fe857ea9494bb24014";
-(void)loginToServer:(NSDictionary *)params
             refresh:(BOOL)refresh
          completion:(loginBlock)completion {
    
    NSDictionary *paames = [NSDictionary dictionary];
    if (!refresh) {
        NSString *username = [params valueForKey:@"name"];
        NSString *password = [params valueForKey:@"verificationCode"];
        paames = @{
                      @"username":username,
                      @"password":password,
                      @"grant_type":@"password"
                    };
    }  else {
        NSString *refresh_token = [params valueForKey:@"refresh_token"];
        paames=@{
                 @"refresh_token":refresh_token,
                 @"grant_type":@"refresh_token"
                };
    }

    NSString *part1 = [NSString stringWithFormat:@"%@:%@",uid,cipherText];
    NSData   *data = [part1 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *stringBase64 = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *authorization = [NSString stringWithFormat:@"Basic %@",stringBase64];
    NSString*url=[NSString stringWithFormat:@"%@%@",EmallHostUrl,URL_get_oauth_token];
    NSMutableURLRequest *formRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:url parameters:paames error:nil];
    
    [formRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8"forHTTPHeaderField:@"Content-Type"];
    
    [formRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
    
    AFHTTPSessionManager*manager = [AFHTTPSessionManager manager];
    
    AFJSONResponseSerializer* responseSerializer = [AFJSONResponseSerializer serializer];
    
    [responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain",nil]];
    
    manager.responseSerializer= responseSerializer;
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:formRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSInteger responseStatusCode = [httpResponse statusCode];
        if (error) {
            NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if (data) {
                id body = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString*code=body[@"code"];
                NSString*message = body[@"message"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (message) {
                        [MBProgressHUD showInfoMessage:message];
                    } else {
                         [PSTipsView showTips:@"登录失败"];
                    }
                });
            } else {
                [PSTipsView showTips:@"登录失败"];
            }
            
        }
        else {
            if (responseStatusCode == 200) { //
                //保存最新的Ouath认证信息
                //登录成功
                OauthInfo *oauthInfo = [OauthInfo modelWithJSON:responseObject];
                self.oathInfo = oauthInfo;
                @weakify(self);
                [self removeUserOuathInfo:^{
                    @strongify(self)
                    [self saveUserOuathInfo];
                    self.curUserInfo = [[UserInfo alloc] init];
                    self.curUserInfo.username = [params valueForKey:@"name"];
                    [self saveUserInfo];
                    //获取云信账号信息
                    [self autoLoginToServer:nil];
                }];
            }
        }
    }];
    
    [dataTask resume];
}

#pragma mark ————— 重新刷新获取Token —————
- (void)refreshOuathToken {
    NSString *refresh_token = self.oathInfo.refresh_token?self.oathInfo.refresh_token:@"";
    NSDictionary*parmeters=@{
                             @"refresh_token":refresh_token,
                             @"grant_type":@"refresh_token"
                             };
    [self loginToServer:parmeters refresh:YES  completion:nil];
}

#pragma mark ————— 判断是否是用户还是律师  —————
//判断是否是用户还是律师
-(void)JudgeIdentityCallback:(loginBlock)callback{
    Mine_AuthLogic *authLogin = [Mine_AuthLogic new];
    [authLogin getLawyerProfilesData:^(id data) {
        if (ValidDict(data)) {
            NSString *userStaus = [data valueForKey:@"certificationStatus"];
            if ([userStaus isEqualToString:@"PENDING_CERTIFIED"]) {
                self.userStatus = PENDING_CERTIFIED;
            } else if ([userStaus isEqualToString:@"PENDING_APPROVAL"]){
                self.userStatus = PENDING_APPROVAL;
            } else if ([userStaus isEqualToString:@"APPROVAL_FAILURE"]){
                self.userStatus = APPROVAL_FAILURE;
            } else if ([userStaus isEqualToString:@"CERTIFIED"]){
                self.userStatus = CERTIFIED;
            }
            [self saveUserState];
            LawUserInfo *lawUserInfo = [LawUserInfo modelWithJSON:data];
            self.lawUserInfo = lawUserInfo;
            [self saveLawUserInfo];
        }
        if (callback) {
            callback(YES,nil);
        }
    } failed:^(NSError *error) {
        if (![self loadUserState]) {
            self.userStatus = PENDING_CERTIFIED;
        }
    }];
}
#pragma mark ————— 自动登录到服务器 —————
//获取IM信息
-(void)autoLoginToServer:(loginBlock)completion{

    //判断律师身份
    [self JudgeIdentityCallback:^(BOOL success, NSString *des) {
        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showActivityMessageInView:@"登录中..."];
    });
    NSString *access_token = self.oathInfo.access_token;
    NSString *token = NSStringFormat(@"Bearer %@",access_token);
    [PPNetworkHelper setValue:token forHTTPHeaderField:@"Authorization"];
    NSString *url = NSStringFormat(@"%@%@",EmallHostUrl,URL_get_im_info);
    [PPNetworkHelper GET:url parameters:nil success:^(id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
        });
        if (ValidDict(responseObject)) {
            UserInfo *userInfo = [UserInfo modelWithDictionary:responseObject];
            if ([self loadUserInfo]) {
                userInfo.username = self.curUserInfo.username;
                self.curUserInfo = userInfo;
            }
            NSLog(@"%@",self.curUserInfo);
            //登录成功储存用户信息
            [self saveUserInfo];
    
            [self LoginSuccess:responseObject completion:^(BOOL success, NSString *des) {
    
            }];
        } else {
            
        }
    } failure:^(NSError *error) {
        NSString *errorInfo = error.userInfo[@"NSLocalizedDescription"];
        if ([errorInfo isEqualToString:@"Request failed: unauthorized (401)"]) {
            [self refreshOuathToken];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
        });
    }];

}

#pragma mark ————— 登录成功处理 —————
-(void)LoginSuccess:(id )responseObject completion:(loginBlock)completion{
    
    if (ValidDict(responseObject)) {
        NSDictionary *data = responseObject;
        if (ValidStr(data[@"account"]) && ValidStr(data[@"token"])) {
            //登录IM
            [[IMManager sharedIMManager] IMLogin:data[@"account"] IMPwd:data[@"token"] completion:^(BOOL success, NSString *des) {
                if (success) {
                    self.isLogined = YES;
                    
                    if (completion) {
                        completion(YES,nil);
                    }
                    KPostNotification(KNotificationLoginStateChange, @YES);
                }else{
                    if (completion) {
                        completion(NO,@"IM登录失败");
                    }
                    KPostNotification(KNotificationLoginStateChange, @NO);
                }
            }];
        }else{
            if (completion) {
                completion(NO,@"登录返回数据异常");
            }
            KPostNotification(KNotificationLoginStateChange, @NO);
        }
    }else{
        if (completion) {
            completion(NO,@"登录返回数据异常");
        }
        KPostNotification(KNotificationLoginStateChange, @NO);
    }
    
}
#pragma mark ————— 储存用户信息 —————
-(void)saveUserInfo{
    if (self.curUserInfo) {
        YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
        NSDictionary *dic = [self.curUserInfo modelToJSONObject];
        [cache setObject:dic forKey:KUserModelCache];
    }
}

-(void)saveLawUserInfo{
    if (self.lawUserInfo) {
        YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
        NSDictionary *dic = [self.lawUserInfo modelToJSONObject];
        [cache setObject:dic forKey:KUserLawModel];
    }
}

-(BOOL)loadLawUserInfo {
    YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
    NSDictionary * LawUserDic = (NSDictionary *)[cache objectForKey:KUserLawModel];
    if (LawUserDic) {
        self.lawUserInfo = [LawUserInfo modelWithJSON:LawUserDic];
        return YES;
    }
    return NO;
}

-(void)saveUserState {
    YYCache *cache = [[YYCache alloc] initWithName:KUserCacheName];
    NSString *state = NSStringFormat(@"%ld",(long)self.userStatus);
    [cache setObject:state forKey:KUserStateName];
}

-(BOOL)loadUserState {
    YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
    NSString *stateStr = (NSString *)[cache objectForKey:KUserStateName];
    if (stateStr) {
        self.userStatus = [stateStr integerValue];
        return YES;
    }
    return NO;
}

#pragma mark ————— 加载缓存的用户信息 —————
-(BOOL)loadUserInfo{
    YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
    NSDictionary * userDic = (NSDictionary *)[cache objectForKey:KUserModelCache];
    if (userDic) {
        self.curUserInfo = [UserInfo modelWithJSON:userDic];
        return YES;
    }
    return NO;
}

#pragma mark ————— 加载公共服务token信息 —————
-(BOOL)loadUserOuathInfo{
    YYCache *cache = [[YYCache alloc]initWithName:KOauthCacheName];
    NSDictionary * userDic = (NSDictionary *)[cache objectForKey:KOauthModelCache];
    if (userDic) {
        self.oathInfo = [OauthInfo modelWithJSON:userDic];
        return YES;
    }
    return NO;
}
#pragma mark ————— 储存用户公共服务获取的信息 —————
-(void)saveUserOuathInfo {
    if (self.oathInfo) {
        YYCache *cache = [[YYCache alloc]initWithName:KOauthCacheName];
        NSDictionary *dic = [self.oathInfo modelToJSONObject];
        [cache setObject:dic forKey:KOauthModelCache];
    }
}

#pragma mark ————— 移除用户公共服务获取的信息 —————
-(void)removeUserOuathInfo:(Complete)complete {
    YYCache *cache = [[YYCache alloc]initWithName:KOauthModelCache];
    [cache removeAllObjectsWithBlock:^{
        if (complete) {
            complete();
        }
    }];
}


-(void)removeLawyerInfo:(Complete)complete {
    YYCache *cache = [[YYCache alloc]initWithName:KLawyerModelCache];
    [cache removeAllObjectsWithBlock:^{
        if (complete) {
            complete();
        }
    }];
}


#pragma mark ————— 获取oauthtoken
- (OauthInfo *)loadOuathInfo {
    YYCache *cache = [[YYCache alloc] initWithName:KOauthModelCache];
    NSDictionary * oauthInfo = (NSDictionary *)[cache objectForKey:KOauthModelCache];
    if (oauthInfo) {
        OauthInfo *curOauthInfo = [OauthInfo modelWithJSON:oauthInfo];
        return curOauthInfo;
    }
    return nil;
}

#pragma mark ————— 被踢下线 —————
-(void)onKick{
    [self logout:nil];
}
#pragma mark ————— 退出登录 —————
- (void)logout:(void (^)(BOOL, NSString *))completion{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:KNotificationLogout object:nil];//被踢下线通知用户退出直播间
    
    [[IMManager sharedIMManager] IMLogout];
    
    self.curUserInfo = nil;
    self.oathInfo = nil;
    self.isLogined = NO;

//    //移除缓存
    YYCache *cache = [[YYCache alloc]initWithName:KUserCacheName];
    [cache removeAllObjectsWithBlock:^{
        if (completion) {
            completion(YES,nil);
        }
    }];
    YYCache *cache1 = [[YYCache alloc] initWithName:KOauthCacheName];
    [cache1 removeAllObjectsWithBlock:^{
        if (completion) {
            completion(YES,nil);
        }
    }];
    
    YYCache*LawyerCache=[[YYCache alloc]initWithName:KLawyerModelCache];
    [LawyerCache removeAllObjectsWithBlock:^{
        if (completion) {
            completion(YES,nil);
        }
    }];
    
    KPostNotification(KNotificationLoginStateChange, @NO);
}
@end
