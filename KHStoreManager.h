//
//  KHStoreManager.h
//
//  Created by Jung Kyungho on 2014. 11. 18..
//  Copyright (c) 2014년 Jung Kyungho. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol KHStoreManagerDelegate <NSObject>

- (void)restoreCompleted;
- (void)restoreFailed;

- (void)purchaseCompleted:(SKPaymentTransaction *)transaction;
- (void)purchaseFailed:(SKPaymentTransaction *)transaction;


@end

@interface KHStoreManager : NSObject

@property (assign) id<KHStoreManagerDelegate> delegate;

+ (KHStoreManager *)sharedManager;


- (void)buyProduct:(SKProduct *)product;

- (void)buySubscribeProduct;

- (BOOL)isAvailableProduct:(NSString *)productId;
- (BOOL)isPurchased:(NSString *)productId;
- (BOOL)isSubscribeExpired:(NSString *)productId;

- (SKProduct *)productForId:(NSString *)productId;

- (void)restore;
- (void)prepare;

- (void)requestProducts:(NSArray *)productIdList;

- (NSArray *)availableProducts;

- (BOOL)isSubscribed;
- (NSDate *)subscribedDate;

@end
