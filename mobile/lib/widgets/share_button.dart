import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class ShareButton extends StatefulWidget {
  final String type;
  final Map<String, dynamic> data;
  final String? birthDate;
  final String? birthTime;
  final String? gender;
  final double size;

  const ShareButton({
    super.key,
    required this.type,
    required this.data,
    this.birthDate,
    this.birthTime,
    this.gender,
    this.size = 20,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _loading = false;

  Future<void> _share() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final url = await ApiService().shareResult(
        type: widget.type,
        data: widget.data,
        birthDate: widget.birthDate,
        birthTime: widget.birthTime,
        gender: widget.gender,
      );

      await Share.share(url);
    } catch (e) {
      debugPrint('[ShareButton] API error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 링크 생성에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _share,
      child: _loading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF9CA3AF),
              ),
            )
          : Icon(
              Icons.ios_share,
              size: widget.size,
              color: const Color(0xFF9CA3AF),
            ),
    );
  }
}
