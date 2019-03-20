package com.example.facebookads

import android.app.Application
import com.facebook.ads.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FacebookAdsPlugin: MethodCallHandler, RewardedVideoAdListener, InterstitialAdListener {

  companion object {
    var instanceChannel: MethodChannel? = null
    var showingRewardedAd = false
    var facebookRewardedAd: com.facebook.ads.RewardedVideoAd? = null
    var facebookInterstitialAd: com.facebook.ads.InterstitialAd? = null;
    var registrar: Registrar? = null
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      FacebookAdsPlugin.registrar = registrar
      val channel = MethodChannel(registrar.messenger(), "facebook_ads")
      channel.setMethodCallHandler(FacebookAdsPlugin())
      FacebookAdsPlugin.instanceChannel = channel
      com.facebook.ads.AudienceNetworkAds.initialize(registrar.context())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "loadInterstitialAd") {
      val placementId: String? = call.argument<String>("placementId")
      initInterstitialAd(placementId)
      FacebookAdsPlugin.showingRewardedAd = false
      FacebookAdsPlugin.facebookRewardedAd?.loadAd()
    } else if (call.method == "showInterstitialAd") {
      FacebookAdsPlugin.showingRewardedAd = false
      val a = FacebookAdsPlugin.facebookInterstitialAd?.isAdLoaded.let {
        if (FacebookAdsPlugin.facebookInterstitialAd?.isAdLoaded!!) {
          result.success(FacebookAdsPlugin.facebookInterstitialAd?.show())
        }
      }

      result.success(false)

    } else if (call.method == "loadAd") {
      FacebookAdsPlugin.showingRewardedAd = true
      val placementId: String? = call.argument<String>("placementId")
      initRewardVideoAd(placementId)
      FacebookAdsPlugin.facebookRewardedAd?.loadAd()
    } else if (call.method == "showAd") {
      FacebookAdsPlugin.showingRewardedAd = true
      val a = FacebookAdsPlugin.facebookRewardedAd?.isAdLoaded.let {
        if (FacebookAdsPlugin.facebookRewardedAd?.isAdLoaded!!) {
          result.success(FacebookAdsPlugin.facebookRewardedAd?.show())
        }
      }

      result.success(false)

    }
  }

  fun initRewardVideoAd(placementId: String?) {
    AdSettings.setIsChildDirected(true)
//    AdSettings.setTestMode(true)
    val context = FacebookAdsPlugin.registrar?.context()
    FacebookAdsPlugin.facebookRewardedAd = com.facebook.ads.RewardedVideoAd(context, placementId)
    FacebookAdsPlugin.facebookRewardedAd?.setAdListener(this)
  }

  fun initInterstitialAd(placementId: String?) {
    AdSettings.setIsChildDirected(true)
//    AdSettings.setTestMode(true)
    val context = FacebookAdsPlugin.registrar?.context()
    FacebookAdsPlugin.facebookInterstitialAd = com.facebook.ads.InterstitialAd(context, placementId)
    FacebookAdsPlugin.facebookInterstitialAd?.setAdListener(this)
  }

  override fun onInterstitialDismissed(p0: Ad?) {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidClose", {})
  }

  override fun onInterstitialDisplayed(p0: Ad?) {

  }

  override fun onRewardedVideoClosed() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClose", {})
  }

  override fun onAdClicked(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClick", {})
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidClick", {})
    }
  }

  override fun onAdLoaded(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidLoad", {})
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidLoad", {})
    }
  }

  override fun onError(p0: Ad?, p1: AdError?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidFail", mapOf("Error" to p1.toString()))
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidFail", mapOf("Error" to p1.toString()))
    }
  }

  override fun onLoggingImpression(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdWillLogImpression", {})
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdWillLogImpression", {})
    }
  }

  override fun onRewardedVideoCompleted() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdVideoComplete", {})
  }
}
