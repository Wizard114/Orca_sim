import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String nomeArquivo;

  const PdfPreviewPage(
      {super.key, required this.pdfBytes, required this.nomeArquivo});

  // Função para voltar ao menu inicial
  void _voltarParaMenu(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _voltarParaMenu(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Orçamento Pronto"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _voltarParaMenu(context),
          ),
        ),
        body: PdfPreview(
          // Constrói o PDF
          build: (format) => pdfBytes,

          // --- CONFIGURAÇÕES IMPORTANTES ---
          allowPrinting: false, // DESATIVA O BOTÃO DE IMPRIMIR (Evita o erro)
          allowSharing: true, // Mantém o compartilhar padrão
          canChangeOrientation: false,
          canDebug: false,

          pdfFileName: nomeArquivo,

          // Adicionamos um botão extra de "Salvar" destacado
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Usa a função nativa de compartilhar/salvar do pacote Printing
                  await Printing.sharePdf(
                      bytes: pdfBytes, filename: nomeArquivo);
                },
                icon: const Icon(Icons.save_alt),
                label: const Text("SALVAR / ENVIAR"),
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
