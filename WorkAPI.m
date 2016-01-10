//
//  WorkAPI.m
//  testVKproject
//
//  Created by Alexonis on 02.12.15.
//  Copyright © 2015 Alexonis. All rights reserved.
//

#import "WorkAPI.h"
#import "User.h"
#import "Messages.h"
Boolean *friensorphoto;
@implementation WorkAPI
int whatIdo=0;

-(void)sendMsg:(NSString *)message andId: (NSString*) idUser
{
   
    whatIdo=0;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *urlS=[NSString stringWithFormat:
                    @"https://api.vk.com/method/messages.send?user_id=%@&message=%@&v=5.42&access_token=%@",
                    idUser,
                    message,
                    [userDefaults objectForKey:@"token"]];
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request delegate:self];
    [theConnect start];
    
}
-(void)getUsers

{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    whatIdo=1;
    dataVK = [NSMutableData data];
    NSString *urlS=[NSString stringWithFormat:
                    @"https://api.vk.com/method/friends.get?user_id=%@&fields=nickname,photo_50&v=5.40&access_token=%@",[userDefaults objectForKey:@"myId"],[userDefaults objectForKey:@"token"]];
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request
                                 delegate:self];
    [theConnect start];
}
-(void)getImages:(int) imgNext{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    whatIdo=2;
    dataVK = [NSMutableData data];
    NSString *urlS=[NSString stringWithFormat:
                    @"https://api.vk.com/method/photos.getAll?owner_id=%@&offset=%i&access_token=%@",
                    self.usertmp.usId,imgNext,[userDefaults objectForKey:@"token"]];
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request delegate:self];
    [theConnect start];
}
-(void) getMessag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    whatIdo=3;
    dataVK = [NSMutableData data];
    NSString *urlS=[NSString stringWithFormat:
                    @"https://api.vk.com/method/messages.getHistory?user_id=%@&count=50&v=5.40&access_token=%@",self.usertmp.usId,[userDefaults objectForKey:@"token"]];
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request
                                 delegate:self];
    [theConnect start];
}

-(NSMutableArray*) parserUser
{
    NSMutableArray *arFin=[NSMutableArray arrayWithCapacity:[arrUserJson count]];
    for( NSDictionary *friend in arrUserJson)
    {
        User *user=[[User alloc] init];
        user.fullName = [NSString stringWithFormat:@"%@ %@",
                         friend[@"first_name"],
                         friend[@"last_name"]];
        user.imgUrl = friend[@"photo_50"];
        user.usId = friend[@"id"];
        [arFin addObject:user];
    }
    return arFin;
}
-(NSMutableArray*) parserMessag
{
    NSMutableArray *arFin=[NSMutableArray arrayWithCapacity:[arrMsg count]];
    for( NSDictionary *messag in arrMsg)
    {
        Messages* mStr=[Messages alloc];
        mStr.mainString = [NSString stringWithFormat:@"%@",messag[@"body"]];
        mStr.idString = [NSString stringWithFormat:@"%@",messag[@"id"]];
        mStr.outString = [NSString stringWithFormat:@"%@",messag[@"out"]];
        if ([messag valueForKey:@"attachments"]!=nil) {
            NSLog(@"! %lu", [[messag valueForKey:@"attachments"] count]);
            if ([[[NSString alloc] initWithString:[messag[@"attachments"]valueForKey:@"type"][0]] isEqual: @"photo"]) {
                mStr.attachImgURL=[NSMutableArray arrayWithCapacity:[[messag valueForKey:@"attachments"] count]];
                for( NSDictionary *attachment in [messag valueForKey:@"attachments"])
                {
                    [mStr.attachImgURL addObject:[[NSString alloc] initWithString:attachment[@"photo"][@"photo_130"]]];
                }
            }
            
        }
        [arFin addObject:mStr];
    }
    return arFin;
}
-(NSMutableArray*) parserImages
{
    NSMutableArray *arphotos=[NSMutableArray arrayWithCapacity:[arrUserJsonImg count]];
    self.usertmp.colvoImg=(int) [arrUserJsonImg[0] integerValue];
    for( NSDictionary *photo in arrUserJsonImg)
    {
        NSString *strImgUrl=[[NSString alloc] init];
        @try {
            
            strImgUrl=[NSString stringWithFormat:@"%@",photo[@"src_big"]];
        }
        @catch (NSException *exception) {
        }
        if (![strImgUrl isEqual:@""]) {
             [arphotos addObject:strImgUrl];
        }
       
    }
    return arphotos;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [dataVK setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [dataVK appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   
    switch (whatIdo)
    {
        case 0:
            NSLog(@"%@", [[NSString alloc] initWithData:dataVK encoding:NSUTF8StringEncoding]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SendComplete" object:nil];
            break;
        case 1:
        {
            NSError *error;
            NSDictionary *json = [NSJSONSerialization
                                  JSONObjectWithData:dataVK
                                  options:kNilOptions
                                  error:&error];
             arrUserJson=json[@"response"][@"items"];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"GetUserComlete" object:nil];
        }
            break;
        case 2:
        {
            NSError *error;
            NSDictionary *json = [NSJSONSerialization
                                  JSONObjectWithData:dataVK
                                  options:kNilOptions
                                  error:&error];
            arrUserJsonImg =json[@"response"] ;
            self.usertmp.imgsUsr_url =[self parserImages];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GetImagesComplete" object:nil];
            
        }
            break;
        case 3:
        {
            NSLog(@"%@",@"ALOHADANCE");
            NSError *error;
            NSDictionary *json = [NSJSONSerialization
                                  JSONObjectWithData:dataVK
                                  options:kNilOptions
                                  error:&error];
            arrMsg =json[@"response"][@"items"] ;
             self.usertmp.msgHist=[self parserMessag];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GetHistoryComplete" object:nil];
           // NSLog(@"%@",[[NSString alloc] initWithData:dataVK encoding:NSUTF8StringEncoding]);
        }
            break;
        default:
            break;
    }
   
}


@end
