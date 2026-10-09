import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// A single small banner ad - nothing else in the app uses ads. Takes up no
/// space and shows nothing until (if) it loads, so a slow or failed ad
/// never leaves a broken-looking gap; there is no interstitial, rewarded or
/// full-screen ad anywhere in the app.
///
/// Uses the real "Home Banner" ad unit from AdMob for both platforms.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  static String get _adUnitId => Platform.isIOS
      ? 'ca-app-pub-3225473284077595/7073299444'
      : 'ca-app-pub-3225473284077595/3060893088';

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: BannerAdWidget._adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          VoidLogger.error('Banner ad failed to load', error);
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
