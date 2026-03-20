import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class PdfButton extends StatefulWidget {
  final String type;
  final Map<String, dynamic> data;
  final double size;

  const PdfButton({
    super.key,
    required this.type,
    required this.data,
    this.size = 20,
  });

  @override
  State<PdfButton> createState() => _PdfButtonState();
}

class _PdfButtonState extends State<PdfButton> {
  bool _loading = false;

  Future<void> _download() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final html = await ApiService().downloadPdfHtml(
        type: widget.type,
        data: widget.data,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${widget.type}_${DateTime.now().millisecondsSinceEpoch}.html');
      await file.writeAsString(html);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: '운명일기 리포트',
      );
    } catch (e) {
      debugPrint('[PdfButton] error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리포트 생성에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _download,
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
              Icons.description_outlined,
              size: widget.size,
              color: const Color(0xFF9CA3AF),
            ),
    );
  }
}
