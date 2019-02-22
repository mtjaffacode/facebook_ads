package com.example.facebookads

import android.app.Application
import com.facebook.ads.Ad
import com.facebook.ads.AdError
import com.facebook.ads.AdSettings
import com.facebook.ads.RewardedVideoAdListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FacebookAdsPlugin: MethodCallHandler, RewardedVideoAdListener {

  companion object {
    var instanceChannel: MethodChannel? = null
    var facebookRewardedAd: com.facebook.ads.RewardedVideoAd? = null
    var registrar: Registrar? = null
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      FacebookAdsPlugin.registrar = registrar
      val channel = MethodChannel(registrar.messenger(), "facebook_ads")
      channel.setMethodCallHandler(FacebookAdsPlugin())
      FacebookAdsPlugin.instanceChannel = channel
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "loadAd") {
      val placementId: String? = call.argument<String>("placementId")
      initRewardVideoAd(placementId)
      FacebookAdsPlugin.facebookRewardedAd?.loadAd()
    } else if (call.method == "showAd") {
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
    AdSettings.setTestMode(true)
    val context = FacebookAdsPlugin.registrar?.context()
    FacebookAdsPlugin.facebookRewardedAd = com.facebook.ads.RewardedVideoAd(context, placementId)
    FacebookAdsPlugin.facebookRewardedAd?.setAdListener(this)
  }

  override fun onRewardedVideoClosed() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClose", {})
  }

  override fun onAdClicked(p0: Ad?) {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClick", {})
  }

  override fun onAdLoaded(p0: Ad?) {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidLoad", {})
  }

  override fun onError(p0: Ad?, p1: AdError?) {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidFail", mapOf("Error" to p1.toString()))
  }

  override fun onLoggingImpression(p0: Ad?) {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdWillLogImpression", {})
  }

  override fun onRewardedVideoCompleted() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdVideoComplete", {})
  }
}
