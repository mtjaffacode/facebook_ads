import Flutter
import UIKit
import UnityAds

public class SwiftFacebookAdsPlugin: NSObject, FlutterPlugin, UnityAdsDelegate, UnityAdsExtendedDelegate {
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
    }
  }

    

}
