import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';




/// [RewardedVideoAd] status changes reported to [RewardedVideoAdListener]s.
///
/// The [rewarded] event is particularly important, since it indicates that the
/// user has watched a video for long enough to be given an in-app reward.
enum RewardedVideoAdEvent {
  loaded,
  failedToLoad,
  clicked,
  impression,
//  opened,
//  leftApplication,
  closed,
//  rewarded,
//  started,
  completed,
}

/// Signature for a [RewardedVideoAd] status change callback. The optional
/// parameters are only used when the [RewardedVideoAdEvent.rewarded] event
/// is sent, when they'll contain the reward amount and reward type that were
/// configured for the AdMob ad unit when it was created. They will be null for
/// all other events.
typedef void RewardedVideoAdListener(RewardedVideoAdEvent event,
    {String rewardType, int rewardAmount});

/// An AdMob rewarded video ad.
///
/// This class is a singleton, and [RewardedVideoAd.instance] provides a
/// reference to the single instance, which is created at launch. The native
/// Android and iOS APIs for AdMob use a singleton to manage rewarded video ad
/// objects, and that pattern is reflected here.
///
/// Apps should assign a callback function to [RewardedVideoAd]'s listener
/// property in order to receive reward notifications from the AdMob SDK:
/// ```
/// RewardedVideoAd.instance.listener = (RewardedVideoAdEvent event,
///     [String rewardType, int rewardAmount]) {
///     print("You were rewarded with $rewardAmount $rewardType!");
///   }
/// };
/// ```
///
/// The function will be invoked when any of the events in
/// [RewardedVideoAdEvent] occur.
///
/// To load and show ads, call the load method:
/// ```
/// RewardedVideoAd.instance.load(myAdUnitString, myTargetingInfoObj);
/// ```
///
/// Later (any point after your listener callback receives the
/// RewardedVideoAdEvent.loaded event), call the show method:
/// ```
/// RewardedVideoAd.instance.show();
/// ```
///
/// Only one rewarded video ad can be loaded at a time. Because the video assets
/// are so large, it's a good idea to start loading an ad well in advance of
/// when it's likely to be needed.
class RewardedVideoAd {
  RewardedVideoAd._();

  /// A platform-specific AdMob test ad unit ID for rewarded video ads. This ad
  /// unit has been specially configured to always return test ads, and
  /// developers are encouraged to use it while building and testing their apps.
//  static final String testAdUnitId = Platform.isAndroid
//      ? 'ca-app-pub-3940256099942544/5224354917'
//      : 'ca-app-pub-3940256099942544/1712485313';

  static final RewardedVideoAd _instance = RewardedVideoAd._();

  /// The one and only instance of this class.
  static RewardedVideoAd get instance => _instance;

  /// Callback invoked for events in the rewarded video ad lifecycle.
  RewardedVideoAdListener listener;

  /// Shows a rewarded video ad if one has been loaded.
  Future<bool> show() {
    return _invokeBooleanMethod("showAd");
  }

  /// Loads a rewarded video ad using the provided ad unit ID.
  Future<bool> load(
      {@required String placementId}) {
    assert(placementId.isNotEmpty);
    return _invokeBooleanMethod("loadAd", <String, dynamic>{
      'placementId': placementId,
    });
  }
}

/// Support for Google AdMob mobile ads.
///
/// Before loading or showing an ad the plugin must be initialized with
/// an AdMob app id:
/// ```
/// FirebaseAdMob.instance.initialize(appId: myAppId);
/// ```
///
/// Apps can create, load, and show mobile ads. For example:
/// ```
/// BannerAd myBanner = BannerAd(unitId: myBannerAdUnitId)
///   ..load()
///   ..show();
/// ```
///
/// See also:
///
///  * The example associated with this plugin.
///  * [BannerAd], a small rectangular ad displayed at the bottom of the screen.
///  * [InterstitialAd], a full screen ad that must be dismissed by the user.
///  * [RewardedVideoAd], a full screen video ad that provides in-app user
///    rewards.
class FacebookAds {
  @visibleForTesting
  FacebookAds.private(MethodChannel channel) : _channel = channel {
    _channel.setMethodCallHandler(_handleMethod);
  }
//
//  // A placeholder AdMob App ID for testing. AdMob App IDs and ad unit IDs are
//  // specific to a single operating system, so apps building for both Android and
//  // iOS will need a set for each platform.
//  static final String testAppId = Platform.isAndroid
//      ? 'ca-app-pub-3940256099942544~3347511713'
//      : 'ca-app-pub-3940256099942544~1458002511';

  static final FacebookAds _instance = FacebookAds.private(
    const MethodChannel('facebook_ads'),
  );

  /// The single shared instance of this plugin.
  static FacebookAds get instance => _instance;

  final MethodChannel _channel;

  Future<String> get platformVersion => _invokeStringMethod("getPlatformVersion");

  static const Map<String, RewardedVideoAdEvent> _methodToRewardedVideoAdEvent =
  <String, RewardedVideoAdEvent>{
//    'onRewarded': RewardedVideoAdEvent.rewarded,
    'onRewardedVideoAdDidClick': RewardedVideoAdEvent.clicked,
    'onRewardedVideoAdDidClose': RewardedVideoAdEvent.closed,
    'onRewardedVideoAdDidFail': RewardedVideoAdEvent.failedToLoad,
//    'onRewardedVideoAdLeftApplication': RewardedVideoAdEvent.leftApplication,
    'onRewardedVideoAdDidLoad': RewardedVideoAdEvent.loaded,
//    'onRewardedVideoAdOpened': RewardedVideoAdEvent.opened,
    'onRewardedVideoAdWillLogImpression': RewardedVideoAdEvent.impression,
//    'onRewardedVideoStarted': RewardedVideoAdEvent.started,
    'onRewardedVideoAdVideoComplete': RewardedVideoAdEvent.completed,
  };


  Future<dynamic> _handleMethod(MethodCall call) {
    assert(call.arguments is Map);
    final Map<dynamic, dynamic> argumentsMap = call.arguments;
    final RewardedVideoAdEvent rewardedEvent =
    _methodToRewardedVideoAdEvent[call.method];
    if (rewardedEvent != null) {
      if (RewardedVideoAd.instance.listener != null) {
        if (rewardedEvent == RewardedVideoAdEvent.completed) {
          RewardedVideoAd.instance.listener(rewardedEvent);
        } else {
          RewardedVideoAd.instance.listener(rewardedEvent);
        }
      }
    }

    return Future<dynamic>.value(null);
  }
}

Future<bool> _invokeBooleanMethod(String method, [dynamic arguments]) async {
  final bool result = await FacebookAds.instance._channel.invokeMethod(
    method,
    arguments,
  );
  return result;
}

Future<String> _invokeStringMethod(String method, [dynamic arguments]) async {
  final String result = await FacebookAds.instance._channel.invokeMethod(
    method,
    arguments,
  );
  return result;
}
