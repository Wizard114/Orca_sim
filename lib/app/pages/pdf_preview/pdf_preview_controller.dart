import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewController {
  bool _isReturning = false;

  void voltarParaMenu(BuildContext context) {
    if (_isReturning) {
      return;
    }

    _isReturning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!context.mounted) {
          return;
        }
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
      } finally {
        _isReturning = false;
      }
    });
  }

  Future<void> compartilharPdf({
    required Uint8List pdfBytes,
    required String nomeArquivo,
  }) {
    return Printing.sharePdf(bytes: pdfBytes, filename: nomeArquivo);
  }
}
