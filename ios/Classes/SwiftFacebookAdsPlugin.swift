import Flutter
import UIKit
import FBAudienceNetwork

public class SwiftFacebookAdsPlugin: NSObject, FlutterPlugin, FBRewardedVideoAdDelegate {
    var facebookRewardedAd: FBRewardedVideoAd? = nil
    static var theInstance: FlutterMethodChannel? = nil
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "facebook_ads", binaryMessenger: registrar.messenger())
    let instance = SwiftFacebookAdsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    theInstance = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "getPlatformVersion") {
        result("iOS " + UIDevice.current.systemVersion)
    } else if (call.method == "loadAd") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        initRewardVideoAd(placementId: arguments["placementId"] as! String)
        facebookRewardedAd?.load()
        result(true)
    } else if (call.method == "showAd") {
        if let valid = facebookRewardedAd?.isAdValid {
            if valid {
                facebookRewardedAd?.show(fromRootViewController: (UIApplication.shared.windows.first?.rootViewController)!, animated: true)
                result(true)
            }
        }
        result(false)
    }
//    else if (call.method == "isAdLoaded") {
//        result(facebookRewardedAd?.isAdValid ?? false)
//    }
  }
    
    public func initRewardVideoAd(placementId: String) {
        facebookRewardedAd = FBRewardedVideoAd(placementID: placementId)
        facebookRewardedAd?.delegate = self
    }
    
    public func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdDidClick", arguments: Dictionary<String, Any>())
    }
    
    public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdDidLoad", arguments: Dictionary<String, Any>())
    }
    
    public func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdDidClose", arguments: Dictionary<String, Any>())
    }
    
    public func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        
    }
    
    public func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdVideoComplete", arguments: Dictionary<String, Any>())
    }
    
    public func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdWillLogImpression", arguments: Dictionary<String, Any>())
    }
    
    public func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        
    }
    
    public func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        
    }
    
    public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdDidFail", arguments: ["Error" : error])
    }
    

}
