package com.example.facebookads

import android.app.Application
import com.facebook.ads.*
import com.adcolony.sdk.*
import com.startapp.android.publish.adsCommon.StartAppAd
import com.startapp.android.publish.adsCommon.StartAppSDK
import com.startapp.android.publish.adsCommon.VideoListener
import com.startapp.android.publish.adsCommon.adListeners.AdDisplayListener
import com.startapp.android.publish.adsCommon.adListeners.AdEventListener
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
    var facebookInterstitialAd: com.facebook.ads.InterstitialAd? = null
    var adColonyAd: AdColonyInterstitial? = null
    var startAppAd: StartAppAd? = null
    var registrar: Registrar? = null
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      FacebookAdsPlugin.registrar = registrar
      val channel = MethodChannel(registrar.messenger(), "facebook_ads")
      channel.setMethodCallHandler(FacebookAdsPlugin())
      FacebookAdsPlugin.instanceChannel = channel
      com.facebook.ads.AudienceNetworkAds.initialize(registrar.activity())

//      AdSettings.setIntegrationErrorMode(AdSettings.IntegrationErrorMode.INTEGRATION_ERROR_CRASH_DEBUG_MODE)
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "initAppStartAdsWithAppId") {
      val appId: String = call.argument<String>("appId")!!
      StartAppSDK.init(FacebookAdsPlugin.registrar?.activity(), appId, false)
      StartAppSDK.setUserConsent (FacebookAdsPlugin.registrar?.activity(),
              "pas",
              System.currentTimeMillis(),
              true)
    } else if (call.method == "loadAppStartAd") {
      startAppAd = StartAppAd(FacebookAdsPlugin.registrar?.activity())
      startAppAd?.loadAd(StartAppAd.AdMode.REWARDED_VIDEO, object: AdEventListener {
        override fun onFailedToReceiveAd(p0: com.startapp.android.publish.adsCommon.Ad?) {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidFail", mapOf("" to ""))
        }

        override fun onReceiveAd(p0: com.startapp.android.publish.adsCommon.Ad?) {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidLoad", mapOf("" to ""))
        }
      })
//      StartAppAd. .loadAd(AdMode.REWARDED_VIDEO);
    } else if (call.method == "showAppStartAd") {
      startAppAd?.setVideoListener(object: VideoListener {
        override fun onVideoCompleted() {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidReward", mapOf("" to ""))
        }
      })
      startAppAd?.showAd(object: AdDisplayListener {
        override fun adClicked(p0: com.startapp.android.publish.adsCommon.Ad?) {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidClick", mapOf("" to ""))
        }

        override fun adDisplayed(p0: com.startapp.android.publish.adsCommon.Ad?) {

        }

        override fun adNotDisplayed(p0: com.startapp.android.publish.adsCommon.Ad?) {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidFail", mapOf("" to ""))
        }

        override fun adHidden(p0: com.startapp.android.publish.adsCommon.Ad?) {
          FacebookAdsPlugin.instanceChannel?.invokeMethod("onStartAppAdDidClose", mapOf("" to ""))
          startAppAd = null
        }
      })
    } else if (call.method == "initAdColonyAdsWithZones") {
      val appId: String = call.argument<String>("appId")!!
      val zoneIds: List<String> = call.argument<List<String>>("zoneIds")!!

        var options = AdColonyAppOptions()
        options.gdprConsentString = "1.0"
        options.gdprRequired = true
        options.keepScreenOn = true

      AdColony.configure(FacebookAdsPlugin.registrar?.activity()?.application, options, appId, *zoneIds.toTypedArray())
      AdColony.setRewardListener {
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidReward", mapOf("" to ""))
      }
      result.success(true)
    } else if (call.method == "loadAdColonyRewardedAd") {
      val zoneId: String = call.argument<String>("zoneId")!!
      initAdColonyRewardedAd(zoneId)
      result.success(true)
    } else if (call.method == "showAdColonyRewardedAd") {
      if (adColonyAd != null && !adColonyAd!!.isExpired) {
        adColonyAd!!.show()
      } else {
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidFail", mapOf("Error" to "Unknown"))
      }
      result.success(true)
    } else if (call.method == "loadInterstitialAd") {
      val placementId: String? = call.argument<String>("placementId")
      initInterstitialAd(placementId)
      FacebookAdsPlugin.showingRewardedAd = false
      FacebookAdsPlugin.facebookInterstitialAd?.loadAd()
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

  fun initAdColonyRewardedAd(zoneId: String?) {
    AdColony.requestInterstitial(zoneId!!, object : AdColonyInterstitialListener() {
      override fun onRequestFilled(p0: AdColonyInterstitial?) {
        adColonyAd = p0
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidLoad", mapOf("" to ""))
      }

      override fun onRequestNotFilled(zone: AdColonyZone?) {
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidFail", mapOf("Error" to "Unknown"))
      }

      override fun onClicked(ad: AdColonyInterstitial?) {
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidClick", mapOf("" to ""))
      }

      override fun onClosed(ad: AdColonyInterstitial?) {
        ad?.destroy()
        adColonyAd = null
        FacebookAdsPlugin.instanceChannel?.invokeMethod("onAdColonyInterstitialDidClose", mapOf("" to ""))
      }
    })
  }

  fun initRewardVideoAd(placementId: String?) {
    AdSettings.setIsChildDirected(true)
//    AdSettings.addTestDevice("6eb6ed7d-becc-42af-8d50-5ebaf6ec1ec7")
//    AdSettings.setTestMode(true)
    val context = FacebookAdsPlugin.registrar?.activity()
    FacebookAdsPlugin.facebookRewardedAd = com.facebook.ads.RewardedVideoAd(context, placementId)
    FacebookAdsPlugin.facebookRewardedAd?.setAdListener(this)
  }

  fun initInterstitialAd(placementId: String?) {
    AdSettings.setIsChildDirected(true)
    AdSettings.addTestDevice("6eb6ed7d-becc-42af-8d50-5ebaf6ec1ec7")
//    AdSettings.setTestMode(true)
    val context = FacebookAdsPlugin.registrar?.activity()
    FacebookAdsPlugin.facebookInterstitialAd = com.facebook.ads.InterstitialAd(context, placementId)
    FacebookAdsPlugin.facebookInterstitialAd?.setAdListener(this)
  }

  override fun onInterstitialDismissed(p0: Ad?) {
    FacebookAdsPlugin.facebookInterstitialAd?.destroy()
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidClose", mapOf("" to ""))
  }

  override fun onInterstitialDisplayed(p0: Ad?) {

  }

  override fun onRewardedVideoClosed() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClose", mapOf("" to ""))
  }

  override fun onAdClicked(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidClick", mapOf("" to ""))
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidClick", mapOf("" to ""))
    }
  }

  override fun onAdLoaded(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidLoad", mapOf("" to ""))
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidLoad", mapOf("" to ""))
    }
  }

  override fun onError(p0: Ad?, p1: AdError?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdDidFail", mapOf("Error" to p1?.errorMessage))
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdDidFail", mapOf("Error" to p1?.errorMessage))
    }
  }

  override fun onLoggingImpression(p0: Ad?) {
    if (FacebookAdsPlugin.showingRewardedAd) {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdWillLogImpression", mapOf("" to ""))
    } else {
      FacebookAdsPlugin.instanceChannel?.invokeMethod("onInterstitialAdWillLogImpression", mapOf("" to ""))
    }
  }

  override fun onRewardedVideoCompleted() {
    FacebookAdsPlugin.instanceChannel?.invokeMethod("onRewardedVideoAdVideoComplete", mapOf("" to ""))
  }
}
