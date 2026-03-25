import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../services/ad_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/share_button.dart';
import '../widgets/pdf_button.dart';
import 'input_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  bool _adLoading = false;

  Future<void> _fetchWithAd(BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) async {
    if (fortuneProvider.isLoading || _adLoading) return;

    if (!Platform.isAndroid) {
      await fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
      return;
    }

    final adService = AdService();

    if (adService.isRewardedAdReady) {
      await adService.showRewardedAd(
        onRewarded: () {
          fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
        },
        onAdNotAvailable: () {
          fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
        },
      );
    } else {
      // Ad not ready — load and wait
      setState(() => _adLoading = true);
      adService.loadRewardedAd();
      // Wait up to 5 seconds for the ad to load
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (adService.isRewardedAdReady) break;
      }
      if (!mounted) return;
      setState(() => _adLoading = false);

      if (adService.isRewardedAdReady) {
        await adService.showRewardedAd(
          onRewarded: () {
            fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
          },
          onAdNotAvailable: () {
            fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
          },
        );
      } else {
        // Ad failed to load — allow access anyway
        await fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    if (!birthProvider.hasBirthInfo) {
      return _noBirthInfo(context);
    }

    final daily = fortuneProvider.dailyFortune;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 운세'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          daily == null
              ? _emptyState(context, birthProvider, fortuneProvider)
              : _resultView(context, daily, fortuneProvider, birthProvider),
          if (fortuneProvider.isLoading || _adLoading)
            LoadingOverlay(message: _adLoading ? '광고를 불러오는 중...' : '운명선생이 오늘의 운세를 살피고 있습니다...'),
        ],
      ),
    );
  }

  Widget _noBirthInfo(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InputScreen()),
              ),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
              child: const Text('사주 입력하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          const Text('오늘의 운세', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('사주와 오늘의 일진으로 운세를 봅니다.', style: TextStyle(color: Color(0xFF6B7280))),
          if (fortuneProvider.error != null) ...[
            const SizedBox(height: 12),
            Text(fortuneProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _fetchWithAd(birthProvider, fortuneProvider),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
            child: const Text('오늘의 운세 보기'),
          ),
        ],
      ),
    );
  }

  Widget _resultView(BuildContext context, daily, FortuneProvider fortuneProvider, BirthInfoProvider birthProvider) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('오늘의 운세', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const Spacer(),
                PdfButton(
                  type: 'daily',
                  data: {
                    'date': daily.date,
                    'iljinHanja': daily.iljinHanja,
                    'iljinHangul': daily.iljinHangul,
                    'reading': daily.reading,
                  },
                ),
                const SizedBox(width: 12),
                ShareButton(
                  type: 'daily',
                  data: {
                    'date': daily.date,
                    'iljinHanja': daily.iljinHanja,
                    'iljinHangul': daily.iljinHangul,
                    'reading': daily.reading,
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daily.date,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A4FFF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF312E81)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('오늘의 일진', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${daily.iljinHanja} (${daily.iljinHangul})',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: MarkdownBody(
                data: daily.reading,
                styleSheet: MarkdownStyleSheet(
                  h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
    );
  }
}
