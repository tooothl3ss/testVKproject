//
//  LongPollServer.m
//  testVKproject
//
//  Created by Alexonis on 28.01.16.
//  Copyright © 2016 Alexonis. All rights reserved.
//   [[NSNotificationCenter defaultCenter] postNotificationName:@"GetImagesComplete" object:nil];

#import "LongPollServer.h"
#import "Messages.h"
NSArray *arrayUpdates;
NSMutableData* dataVK;
NSString *longPoll;
NSString *longPollKey;
NSString *longPollts;
NSDictionary *json;
NSArray *arraytmp;
NSString *userIDListen;
Messages *message;
bool listener;
bool listening;
@implementation LongPollServer
+(LongPollServer *) singleton
{
    static LongPollServer *longPollServerObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        longPollServerObject  = [[self alloc] init];
        [longPollServerObject connectToLongPoll];
        NSLog(@"11");
    });
    return longPollServerObject;
}
-(void) connectToLongPoll
{
    listening=0;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *urlS=[NSString stringWithFormat:
                    @"https://api.vk.com/method/messages.getLongPollServer?need_pts=1&access_token=%@",
                    [userDefaults objectForKey:@"token"]];
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request delegate:self];
    [theConnect start];
}
-(void)whoListening: (NSString*) userID
{
    userIDListen=userID;
    listener=true;
}
-(void)unListen{
    listener=false;
}
-(void)listeningLongPollServer
{
    listening=1;
    NSString *urlS=[NSString stringWithFormat:
                    @"http://%@?act=a_check&key=%@&ts=%@&wait=25&mode=2",
                    longPoll,longPollKey,longPollts];
        NSLog(@"%@ %@ %@ ",longPoll,longPollKey,longPollts);
    NSURL *url=[NSURL URLWithString:urlS];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    NSURLConnection *theConnect=[[NSURLConnection alloc]
                                 initWithRequest:request delegate:self];
    [theConnect start];
}
-(void)parserMessageFromLongPoll{
    
    arrayUpdates=json[@"updates"];
    if ([arrayUpdates count]!=0) {
        arraytmp=arrayUpdates[0];
        switch ([arraytmp[0] integerValue]) {
            case 4:
            {
                message=[Messages alloc];
                message.mainString=arraytmp[6];
                if (([arraytmp[2] integerValue]==35)||([arraytmp[2] integerValue]==51)) {
                    message.outString=@"1";
                }
                else
                {
                    message.outString=@"0";
                }
                if (arraytmp[3]==userIDListen) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
                }
                NSLog(@"%@ %@  %@",arraytmp[6],arraytmp[3], userIDListen);
            }
                break;
                
            default:
                break;
        }
    }
    longPollts=json[@"ts"];
    [self listeningLongPollServer];
}
-(Messages*)giveMessage{
    NSLog(@"%@", message.mainString);
    return message;
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
    NSLog(@"Connection failed: %@  LongPollServer! %@", [error description], connection.currentRequest.URL);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (listening) {
        NSError *error;
         json= [NSJSONSerialization
                              JSONObjectWithData:dataVK
                              options:kNilOptions
                              error:&error];
        NSLog(@"%@",[[NSString alloc] initWithData:dataVK encoding:NSUTF8StringEncoding]);
        [self parserMessageFromLongPoll];

    }
    else
    {
    NSError *error;
    json = [NSJSONSerialization
                          JSONObjectWithData:dataVK
                          options:kNilOptions
                          error:&error];
        NSLog(@"%@",[[NSString alloc] initWithData:dataVK encoding:NSUTF8StringEncoding]);
    longPollKey=[NSString stringWithFormat:@"%@",json[@"response"][@"key"]];
    longPoll=[NSString stringWithFormat:@"%@",json[@"response"][@"server"]];
    longPollts=[NSString stringWithFormat:@"%@",json[@"response"][@"ts"]];
    [self listeningLongPollServer];
    }
}
@end
