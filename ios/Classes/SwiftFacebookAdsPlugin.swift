import Flutter
import UIKit
import FBAudienceNetwork
import AdColony
import UnityAds

public class SwiftFacebookAdsPlugin: NSObject, FlutterPlugin, FBInterstitialAdDelegate, FBRewardedVideoAdDelegate, UnityAdsDelegate, UnityAdsExtendedDelegate {
    public func unityAdsDidClick(_ placementId: String) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidClick", arguments: Dictionary<String, Any>())
    }
    
    public func unityAdsPlacementStateChanged(_ placementId: String, oldState: UnityAdsPlacementState, newState: UnityAdsPlacementState) {
    }
    
    public func unityAdsReady(_ placementId: String) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidLoad", arguments: Dictionary<String, Any>())
    }
    
    public func unityAdsDidError(_ error: UnityAdsError, withMessage message: String) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidFail", arguments: ["Error" : message])
    }
    
    public func unityAdsDidStart(_ placementId: String) {
        
    }
    
    public func unityAdsDidFinish(_ placementId: String, with state: UnityAdsFinishState) {
        if state == UnityAdsFinishState.completed {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidReward", arguments: Dictionary<String, Any>())
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidClose", arguments: Dictionary<String, Any>())
        } else if state == UnityAdsFinishState.skipped {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidClose", arguments: Dictionary<String, Any>())
        } else if state == UnityAdsFinishState.error {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidFail", arguments: ["Error", "Ad did fail to load"])
        } else {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidFail", arguments: ["Error", "Ad did fail to load"])
        }
    }
    
    var facebookRewardedAd: FBRewardedVideoAd? = nil
    var facebookInterstitialAd: FBInterstitialAd? = nil
    var adColonyInterstitialAd: AdColonyInterstitial? = nil
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
    } else if (call.method == "initUnityAds") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        let gameId = arguments["gameId"] as! String
        UnityAds.initialize(gameId, delegate: self)
        result(true)
    } else if (call.method == "loadUnityAd") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        if (UnityAds.isReady(arguments["placementId"] as! String)) {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidLoad", arguments: Dictionary<String, Any>())
        } else {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onUnityAdDidFail", arguments: ["Error": "Ad not ready"])
        }
        result(true)
    } else if (call.method == "showUnityAd") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        UnityAds.show((UIApplication.shared.windows.first?.rootViewController)!, placementId: arguments["placementId"] as! String)
        result(true)
    } else if (call.method == "initAdColonyAdsWithZones") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        let options = AdColonyAppOptions()
        options.gdprConsentString = "1.0"
        options.gdprRequired = true

        AdColony.configure(withAppID: arguments["appId"] as! String, zoneIDs: arguments["zoneIds"] as! [String], options: options) { (zones) in
            zones.forEach({ (zone) in
                if (zone.rewarded) {
                    zone.setReward({ (one, two, three) in
                        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidReward", arguments: Dictionary<String, Any>())
                    })
                }
            })
            result(true)
        }
    } else if (call.method == "loadAdColonyRewardedAd") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        initAdColonyRewardedAd(zoneId: arguments["zoneId"] as! String)
        result(true)
    } else if (call.method == "showAdColonyRewardedAd") {
        if let ad = self.adColonyInterstitialAd, !ad.expired {
            ad.setClose {
                SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidClose", arguments: Dictionary<String, Any>())
                self.adColonyInterstitialAd = nil
            }
            ad.setClick {
                SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidClick", arguments: Dictionary<String, Any>())
            }
            ad.show(withPresenting: (UIApplication.shared.windows.first?.rootViewController)!)
        } else {
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidFail", arguments: ["Error" : "Invalid ad"])
        }
        result(true)
    } else if (call.method == "loadInterstitialAd") {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        initInterstitialAd(placementId: arguments["placementId"] as! String)
        facebookInterstitialAd?.load()
        result(true)
    } else if (call.method == "showInterstitialAd") {
        if let valid = facebookInterstitialAd?.isAdValid {
            if valid {
                facebookInterstitialAd?.show(fromRootViewController: (UIApplication.shared.windows.first?.rootViewController)!)
                result(true)
            }
        }
        result(false)
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
    
    public func initAdColonyRewardedAd(zoneId: String) {
        AdColony.requestInterstitial(inZone: zoneId, options: nil, success: { (ad) in
            self.adColonyInterstitialAd = ad
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidLoad", arguments: Dictionary<String, Any>())
        }) { (error) in
            SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onAdColonyInterstitialDidFail", arguments: ["Error" : error.localizedFailureReason])
        }
    }
    
    public func initRewardVideoAd(placementId: String) {
        FBAdSettings.setIsChildDirected(true)
        facebookRewardedAd = FBRewardedVideoAd(placementID: placementId)
        facebookRewardedAd?.delegate = self
    }
    
    public func initInterstitialAd(placementId: String) {
        FBAdSettings.setIsChildDirected(true)
        facebookInterstitialAd = FBInterstitialAd(placementID: placementId)
        facebookInterstitialAd?.delegate = self
    }
    
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onInterstitialAdDidLoad", arguments: Dictionary<String, Any>())
    }
    
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onInterstitialAdDidClick", arguments: Dictionary<String, Any>())
    }
    
    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onInterstitialAdDidClose", arguments: Dictionary<String, Any>())
    }
    
    public func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        
    }
    
    public func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onInterstitalAdWillLogImpression", arguments: Dictionary<String, Any>())
    }
    
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onInterstitialAdDidFail", arguments: ["Error" : error.localizedDescription])
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
        SwiftFacebookAdsPlugin.theInstance?.invokeMethod("onRewardedVideoAdDidFail", arguments: ["Error" : error.localizedDescription])
    }
    

}
