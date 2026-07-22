import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static const _rewardedAdUnitId = 'ca-app-pub-2707874353926722/6843875092';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    if (!Platform.isAndroid) return;
    // 이미 준비됐거나 로드 중이면 중복 요청하지 않는다.
    if (_rewardedAd != null || _isLoading) return;

    _isLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _rewardedAd = ad;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
          debugPrint('[AdService] Rewarded ad failed to load: $error');
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
      // 아직 준비 안 됨 — 다음 기회를 위해 미리 받아두고 호출자에게 알린다.
      loadRewardedAd();
      onAdNotAvailable?.call();
      return;
    }

    // 광고를 끝까지 보지 않고 닫아도 호출자가 멈춰 있지 않도록,
    // 보상 여부와 무관하게 콜백이 정확히 한 번은 불리게 한다.
    var settled = false;
    void settle(void Function() action) {
      if (settled) return;
      settled = true;
      action();
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        // 보상 없이 닫힌 경우 — 무료 기능이므로 그대로 통과시킨다.
        settle(() {
          if (onAdNotAvailable != null) {
            onAdNotAvailable();
          } else {
            onRewarded();
          }
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show rewarded ad: $error');
        ad.dispose();
        loadRewardedAd();
        settle(() {
          if (onAdNotAvailable != null) {
            onAdNotAvailable();
          } else {
            onRewarded();
          }
        });
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        settle(onRewarded);
      },
    );
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
