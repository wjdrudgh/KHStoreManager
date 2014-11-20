//
//  KHStoreManager.m
//
//  Created by Jung Kyungho on 2014. 11. 18..
//  Copyright (c) 2014년 Jung Kyungho. All rights reserved.
//

#import "KHStoreManager.h"

#define PRODUCT_ID @"iosStoreKit"

#import "CustomNetwork.h"
#import "CustomData.h"

@interface KHStoreManager () <SKProductsRequestDelegate, SKRequestDelegate, SKPaymentTransactionObserver>
{
	NSArray *_products;
	NSMutableArray *_purchasedProducts;
	
	NSString *_subscribeProductId;
	
	SKPaymentTransaction *_subscribeTransaction;
	BOOL _isSubscribed;
}

@end

@implementation KHStoreManager

#pragma mark - singleton pattern

static KHStoreManager *sharedManager = nil;

+ (KHStoreManager *)sharedManager
{
	if (sharedManager == nil) {
		sharedManager = [[self alloc] init];
		
		[sharedManager initialize];
	}
	
	return sharedManager;
}

- (void)initialize
{
	_purchasedProducts = [NSMutableArray array];
	_products = [NSArray array];
	
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)requestRestore
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)requestProducts:(NSArray *)productIdList
{
	NSMutableSet *skuSet = [NSMutableSet set];

    //검증할 In-App ID를 skuSet 추가
    for (int i = 0; i < productIdList.count; i++) {
        [skuSet addObject:productIdList[i]];
    }
	
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:skuSet];
	productsRequest.delegate = self;
	[productsRequest start];
}

#pragma mark - getter

- (NSArray *)availableProducts
{
	if (_products) {
		return _products;
	} else {
		return [NSArray array];
	}
}

- (BOOL)isSubscribed
{
	return _isSubscribed;
}

- (NSDate *)subscribedDate
{
    if (_isSubscribed && _subscribeTransaction) {
        return _subscribeTransaction.transactionDate;
    } else {
        return nil;
    }
}

- (void)restore
{
	[self requestRestore];
}

- (void)prepare
{
    [self requestProducts:[NSArray array]];
	[self requestRestore];
}

#pragma mark - actions

- (void)buyProduct:(SKProduct *)product
{
	if ([SKPaymentQueue canMakePayments]) {
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
        //중복구매 막으려면
        //		if (![_purchasedProducts containsObject:product.productIdentifier]) {
        //			[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
        //		}
    } else {
        [self.delegate purchaseFailed:transaction];
    }
}

- (void)buySubscribeProduct
{
    if (_subscribeProductId == nil || _subscribeProductId.length == 0) {
        [self.delegate purchaseFailed:transaction];
        return;
    }
    
	if ([SKPaymentQueue canMakePayments]) {
        for (SKProduct *product in _products) {
            if ([product.productIdentifier isEqualToString:_subscribeProductId]) {
                [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
                break;
            }
        }
        //중복구매 막으려면
        //		if (![_purchasedProducts containsObject:_subscribeProductId]) {
        //			
        //			for (SKProduct *product in _products) {
        //				if ([product.productIdentifier isEqualToString:_subscribeProductId]) {
        //					[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
        //					break;
        //				}
        //			}
        //		}
    } else {
        [self.delegate purchaseFailed:transaction];
    }
}

- (BOOL)isAvailableProduct:(NSString *)productId
{
	for (SKProduct *product in _products) {
		if ([product.productIdentifier isEqualToString:productId]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)isPurchased:(NSString *)productId
{
	if ([_purchasedProducts containsObject:productId]) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)isSubscribeExpired:(NSString *)productId
{
    NSDate *currentDate = [NSDate date];
    NSDate *transactionDate = _subscribeTransaction.transactionDate;
    
    if ([transactionDate compare:currentDate] == NSOrderedSame
        || [transactionDate compare:currentDate] == NSOrderedAscending) {
        
        //구독상태임
        return NO;
    }
    
    //구독상태 아님
	return YES;
}

- (SKProduct *)productForId:(NSString *)productId
{
	for (int i = 0; i < _products.count; i++) {
		SKProduct *product = _products[i];
		if ([product.productIdentifier isEqualToString:productId]) {
			return product;
		}
	}
	
	return nil;
}

#pragma mark - products

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSMutableArray *products = [NSMutableArray array];
	for (int i = 0; i < response.products.count; i++) {
		SKProduct *product = response.products[i];
		
		[products addObject:product];
	}
	
	_products = products;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"no products");
}

#pragma mark - transaction

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
			[self purchased:transaction];
		} else if (transaction.transactionState == SKPaymentTransactionStateRestored) {
			[self purchaseRestored:transaction];
		} else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
			[self purchaseFailed:transaction];
		} else if (transaction.transactionState == SKPaymentTransactionStateDeferred) {
			
		}
	}
}

- (void)purchased:(SKPaymentTransaction *)transaction
{
	NSString *productId = transaction.payment.productIdentifier;
	
	if (![_purchasedProducts containsObject:productId]) {
		[_purchasedProducts addObject:productId];
		
		if ([productId isEqualToString:_subscribeProductId]) {
			_isSubscribed = YES;
			
			_subscribeTransaction = transaction;
		}
	}
	
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
    [self.delegate purchaseCompleted:transaction];
}

- (void)purchaseRestored:(SKPaymentTransaction *)transaction
{
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)purchaseFailed:(SKPaymentTransaction *)transaction
{
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
    [self.delegate purchaseFailed:transaction];
}

#pragma mark - restore

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	[_purchasedProducts removeAllObjects];
	_isSubscribed = NO;
	_subscribeTransaction = nil;
	
	for (SKPaymentTransaction *transaction in queue.transactions) {
		NSString *productId = transaction.payment.productIdentifier;
		if (![_purchasedProducts containsObject:productId]) {
			[_purchasedProducts addObject:productId];
			
			if ([productId isEqualToString:_subscribeProductId]) {
				_isSubscribed = YES;
				
				_subscribeTransaction = transaction;
			}
		}
	}
	
    [self.delegate restoreCompleted];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self.delegate restoreFailed];
}

#pragma mark - verify

//transaction data 검증하고싶을때 사용
- (NSString*)base64forData:(NSData*)theData {
	const uint8_t* input = (const uint8_t*)[theData bytes];
	NSInteger length = [theData length];
	
	static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
	NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
	uint8_t* output = (uint8_t*)data.mutableBytes;
	
	NSInteger i;
	for (i=0; i < length; i += 3) {
		NSInteger value = 0;
		NSInteger j;
		for (j = i; j < (i + 3); j++) {
			value <<= 8;
			
			if (j < length) {
				value |= (0xFF & input[j]);
			}
		}
		
		NSInteger theIndex = (i / 3) * 4;
		output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
		output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
		output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
		output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
	}
	
	return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}


//Service URL : https://buy.itunes.apple.com/verifyReceipt
- (NSDictionary *)verifyReceipt:(SKPaymentTransaction*)transaction
{
	NSString* recieptString = [self base64forData:transaction.transactionReceipt];
	
	NSError* error = nil;
	NSDictionary* dict = [NSDictionary dictionaryWithObject:recieptString forKey:@"receipt-data"];
	
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://buy.itunes.apple.com/verifyReceipt"]]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:jsonData];
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
	
	NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
	return jsonDict;
}

#pragma mark - memory

- (void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
