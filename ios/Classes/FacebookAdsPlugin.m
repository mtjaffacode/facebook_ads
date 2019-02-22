#import "FacebookAdsPlugin.h"
#import <facebook_ads/facebook_ads-Swift.h>

@implementation FacebookAdsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFacebookAdsPlugin registerWithRegistrar:registrar];
}
@end
