//
//  SDLSoftButtonManager.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 2/22/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLSoftButtonManager.h"

#import "SDLConnectionManagerType.h"
#import "SDLError.h"
#import "SDLFileManager.h"
#import "SDLLogMacros.h"
#import "SDLOnHMIStatus.h"
#import "SDLPredefinedWindows.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLRPCResponseNotification.h"
#import "SDLSetDisplayLayoutResponse.h"
#import "SDLShow.h"
#import "SDLSoftButton.h"
#import "SDLSoftButtonCapabilities.h"
#import "SDLSoftButtonObject.h"
#import "SDLSoftButtonReplaceOperation.h"
#import "SDLSoftButtonState.h"
#import "SDLSoftButtonTransitionOperation.h"
#import "SDLSystemCapabilityManager.h"
#import "SDLWindowCapability.h"
#import "SDLSystemCapability.h"
#import "SDLDisplayCapability.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLSoftButtonObject()

@property (assign, nonatomic) NSUInteger buttonId;
@property (weak, nonatomic) SDLSoftButtonManager *manager;

@end

@interface SDLSoftButtonManager()

@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;
@property (weak, nonatomic) SDLSystemCapabilityManager *systemCapabilityManager;

@property (strong, nonatomic) NSOperationQueue *transactionQueue;

@property (strong, nonatomic, nullable) SDLWindowCapability *windowCapability;
@property (copy, nonatomic, nullable) SDLHMILevel currentLevel;

@property (strong, nonatomic) NSMutableArray<SDLAsynchronousOperation *> *batchQueue;

@end

@implementation SDLSoftButtonManager

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(SDLFileManager *)fileManager systemCapabilityManager:(SDLSystemCapabilityManager *)systemCapabilityManager{
    self = [super init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;
    _fileManager = fileManager;
    _systemCapabilityManager = systemCapabilityManager;
    _softButtonObjects = @[];

    _currentLevel = nil;
    _transactionQueue = [self sdl_newTransactionQueue];
    _batchQueue = [NSMutableArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_hmiStatusNotification:) name:SDLDidChangeHMIStatusNotification object:nil];

    return self;
}

- (void)start {
    [self.systemCapabilityManager subscribeToCapabilityType:SDLSystemCapabilityTypeDisplays withObserver:self selector:@selector(sdl_displayCapabilityDidUpdate:)];
}

- (void)stop {
    _softButtonObjects = @[];
    _currentMainField1 = nil;
    _currentLevel = nil;
    _windowCapability = nil;

    [_transactionQueue cancelAllOperations];
    self.transactionQueue = [self sdl_newTransactionQueue];

    [self.systemCapabilityManager unsubscribeFromCapabilityType:SDLSystemCapabilityTypeDisplays withObserver:self];
}

- (NSOperationQueue *)sdl_newTransactionQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"SDLSoftButtonManager Transaction Queue";
    queue.maxConcurrentOperationCount = 1;
    queue.qualityOfService = NSQualityOfServiceUserInitiated;
    queue.suspended = YES;

    return queue;
}


#pragma mark - Sending Soft Buttons

- (void)setSoftButtonObjects:(NSArray<SDLSoftButtonObject *> *)softButtonObjects {
    // Only update if something changed. This prevents, for example, an empty array being reset
    if (_softButtonObjects == softButtonObjects) {
        return;
    }

    // Set the soft button ids. Check to make sure no two soft buttons have the same name, there aren't many soft buttons, so n^2 isn't going to be bad
    for (NSUInteger i = 0; i < softButtonObjects.count; i++) {
        NSString *buttonName = softButtonObjects[i].name;
        softButtonObjects[i].buttonId = i * 100;
        for (NSUInteger j = (i + 1); j < softButtonObjects.count; j++) {
            if ([softButtonObjects[j].name isEqualToString:buttonName]) {
                _softButtonObjects = @[];
                SDLLogE(@"Attempted to set soft button objects, but two buttons had the same name: %@", softButtonObjects);
                return;
            }
        }
    }

    for (SDLSoftButtonObject *button in softButtonObjects) {
        button.manager = self;
    }

    _softButtonObjects = softButtonObjects;

    SDLSoftButtonReplaceOperation *op = [[SDLSoftButtonReplaceOperation alloc] initWithConnectionManager:self.connectionManager fileManager:self.fileManager capabilities:self.windowCapability.softButtonCapabilities.firstObject softButtonObjects:_softButtonObjects mainField1:self.currentMainField1];

    if (self.isBatchingUpdates) {
        [self.batchQueue removeAllObjects];
        [self.batchQueue addObject:op];
    } else {
        [self.transactionQueue cancelAllOperations];
        [self.transactionQueue addOperation:op];
    }
}

- (void)sdl_transitionSoftButton:(SDLSoftButtonObject *)softButton {
    SDLSoftButtonTransitionOperation *op = [[SDLSoftButtonTransitionOperation alloc] initWithConnectionManager:self.connectionManager capabilities:self.windowCapability.softButtonCapabilities.firstObject softButtons:self.softButtonObjects mainField1:self.currentMainField1];

    if (self.isBatchingUpdates) {
        for (SDLAsynchronousOperation *sbOperation in self.batchQueue) {
            if ([sbOperation isMemberOfClass:[SDLSoftButtonTransitionOperation class]]) {
                [self.batchQueue removeObject:sbOperation];
            }
        }

        [self.batchQueue addObject:op];
    } else {
        [self.transactionQueue addOperation:op];
    }
}


#pragma mark - Getting Soft Buttons

- (nullable SDLSoftButtonObject *)softButtonObjectNamed:(NSString *)name {
    for (SDLSoftButtonObject *object in self.softButtonObjects) {
        if ([object.name isEqualToString:name]) {
            return object;
        }
    }

    return nil;
}


#pragma mark - Getters / Setters

- (void)setBatchUpdates:(BOOL)batchUpdates {
    _batchUpdates = batchUpdates;

    if (!_batchUpdates) {
        [self.transactionQueue addOperations:[self.batchQueue copy] waitUntilFinished:NO];
        [self.batchQueue removeAllObjects];
    }
}

- (void)setCurrentMainField1:(nullable NSString *)currentMainField1 {
    _currentMainField1 = currentMainField1;

    for (NSUInteger i = 0; i < self.transactionQueue.operations.count; i++) {
        if ([self.transactionQueue.operations[i] isMemberOfClass:[SDLSoftButtonReplaceOperation class]]) {
            SDLSoftButtonReplaceOperation *op = self.transactionQueue.operations[i];
            op.mainField1 = currentMainField1;
        } else if ([self.transactionQueue.operations[i] isMemberOfClass:[SDLSoftButtonTransitionOperation class]]) {
            SDLSoftButtonTransitionOperation *op = self.transactionQueue.operations[i];
            op.mainField1 = currentMainField1;
        }
    }
}


#pragma mark - RPC Responses

- (void)sdl_displayCapabilityDidUpdate:(SDLSystemCapability *)systemCapability {
    self.windowCapability = self.systemCapabilityManager.defaultMainWindowCapability;

    // Auto-send an updated Show to account for changes to the capabilities
    if (self.softButtonObjects.count > 0) {
        SDLSoftButtonReplaceOperation *op = [[SDLSoftButtonReplaceOperation alloc] initWithConnectionManager:self.connectionManager fileManager:self.fileManager capabilities:self.windowCapability.softButtonCapabilities.firstObject softButtonObjects:self.softButtonObjects mainField1:self.currentMainField1];
        [self.transactionQueue addOperation:op];
    }
}

- (void)sdl_hmiStatusNotification:(SDLRPCNotificationNotification *)notification {
    SDLOnHMIStatus *hmiStatus = (SDLOnHMIStatus *)notification.notification;

    if (hmiStatus.windowID != nil && hmiStatus.windowID.integerValue != SDLPredefinedWindowsDefaultWindow) {
        return;
    }
    
    SDLHMILevel oldHMILevel = self.currentLevel;
    if (![oldHMILevel isEqualToEnum:hmiStatus.hmiLevel]) {
        if ([hmiStatus.hmiLevel isEqualToEnum:SDLHMILevelNone]) {
            self.transactionQueue.suspended = YES;
        } else {
            self.transactionQueue.suspended = NO;
        }
    }

    self.currentLevel = hmiStatus.hmiLevel;
}

@end

NS_ASSUME_NONNULL_END
