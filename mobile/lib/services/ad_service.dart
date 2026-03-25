import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static const _rewardedAdUnitId = 'ca-app-pub-2707874353926722/6843875092';

  RewardedAd? _rewardedAd;

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    if (!Platform.isAndroid) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdNotAvailable,
  }) async {
    if (!Platform.isAndroid) {
      onRewarded();
      return;
    }

    if (_rewardedAd == null) {
      // Ad not loaded yet — try loading and show when ready
      onAdNotAvailable?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show rewarded ad: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );
    _rewardedAd = null;
  }

  bool get isRewardedAdReady => Platform.isAndroid && _rewardedAd != null;

  BannerAd createBannerAd(String adUnitId) {
    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('[AdService] Banner loaded: $adUnitId'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner failed: $error');
          ad.dispose();
        },
      ),
    );
  }
}
