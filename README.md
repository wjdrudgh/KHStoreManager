KHStoreManager
==============

// You can use delegate for result

<KHStoreManagerDelegate>

- (void)restoreCompleted;
- (void)restoreFailed;

- (void)purchaseCompleted:(SKPaymentTransaction *)transaction;
- (void)purchaseFailed:(SKPaymentTransaction *)transaction;

// init

- (void)prepare;

// restore

- (void)restore;

// fetch SKProduct

- (void)requestProducts:(NSArray *)productIdList;

// get SKProduct

- (SKProduct *)productForId:(NSString *)productId;

// buy product

- (void)buyProduct:(SKProduct *)product;

// you can use some methods for check status

- (BOOL)isAvailableProduct:(NSString *)productId;
- (BOOL)isPurchased:(NSString *)productId;
- (BOOL)isSubscribeExpired:(NSString *)productId;

- (BOOL)isSubscribed;
- (NSDate *)subscribedDate;

// get available SKProducts

- (NSArray *)availableProducts;


