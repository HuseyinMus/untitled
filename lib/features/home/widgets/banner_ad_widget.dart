import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled/ads/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AdsService.init();
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdsService.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _ready = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );
    await ad.load();
    if (mounted) setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}


