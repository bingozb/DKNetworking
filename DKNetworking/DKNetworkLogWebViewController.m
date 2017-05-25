//
//  DKNetworkLogWebViewController.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/5/26.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkLogWebViewController.h"

@interface DKNetworkLogWebViewController ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation DKNetworkLogWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Error Message";
    
    [self setupWebView];
    
    [self setupNavItem];
}

- (void)setupWebView
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 64)];
    webView.scalesPageToFit = YES;
    webView.opaque = NO;
    webView.backgroundColor = [UIColor whiteColor];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.logFilePath]];
    [webView loadRequest:request];
    self.webView = webView;
    
    [self.view addSubview:webView];
}

- (void)setupNavItem
{
    UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 44)];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"DKN Error Report"];
    [nav pushNavigationItem:navItem animated:YES];
    nav.items = @[navItem];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(back)];
    navItem.leftBarButtonItem = cancelItem;
    
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    navItem.rightBarButtonItem = shareItem;
    
    [self.view addSubview:nav];
}

- (void)share
{
    id shareController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:self.logFilePath]] applicationActivities:nil];
        vc.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popPc = vc.popoverPresentationController;
        popPc.sourceView = self.view;
        popPc.permittedArrowDirections = UIPopoverArrowDirectionRight;
        shareController = vc;
    } else {
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:self.logFilePath]] applicationActivities:nil];
        shareController = controller;
    }
    [self presentViewController:shareController animated:YES completion:nil];
}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
