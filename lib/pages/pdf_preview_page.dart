import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String nomeArquivo;

  const PdfPreviewPage(
      {super.key, required this.pdfBytes, required this.nomeArquivo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visualizar Orçamento"),
      ),
      body: PdfPreview(
        // Esta função constrói o preview com os bytes que passamos
        build: (format) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canDebug: false,
        // Nome do arquivo para quando for compartilhar
        pdfFileName: nomeArquivo,
        // Tradução básica dos botões (opcional, mas bom para J7)
        actions: null,
      ),
    );
  }
}
