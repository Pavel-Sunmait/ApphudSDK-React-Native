#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(PaywallscreenPresenter, RCTEventEmitter)

RCT_EXTERN_METHOD(displayPaywallScreen:(NSDictionary*)options)

+ (BOOL)requiresMainQueueSetup {
    return YES; // Requires setup on the main JavaScript thread
}

@end
