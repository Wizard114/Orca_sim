import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:orca_sim/app/pages/pdf_preview/pdf_preview_controller.dart';
import 'package:orca_sim/injection.dart';
import 'package:printing/printing.dart';

class PdfPreviewView extends StatelessWidget {
  const PdfPreviewView({
    super.key,
    required this.pdfBytes,
    required this.nomeArquivo,
  });

  final Uint8List pdfBytes;
  final String nomeArquivo;

  @override
  Widget build(BuildContext context) {
    final controller = getIt<PdfPreviewController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        controller.voltarParaMenu(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orcamento Pronto'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => controller.voltarParaMenu(context),
          ),
        ),
        body: PdfPreview(
          build: (format) => pdfBytes,
          allowPrinting: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: nomeArquivo,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                onPressed: () => controller.compartilharPdf(
                  pdfBytes: pdfBytes,
                  nomeArquivo: nomeArquivo,
                ),
                icon: const Icon(Icons.save_alt),
                label: const Text('SALVAR / ENVIAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
