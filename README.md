# orca_sim

Gerenciador de orçamentos para prestadores de serviço.

## 📁 Estrutura de Diretórios

```text
orca_sim/
├── android/                  # Configurações nativas Android
├── assets/                   # Recursos estáticos (imagens, ícones)
│   ├── google_icon.png
│   ├── icone_app.png
│   ├── icone_novo.png
│   └── logo.png
├── ios/                      # Configurações nativas iOS
├── lib/                      # Código fonte do aplicativo
│   ├── pages/                # Telas da interface do usuário
│   │   ├── cadastro_empresa_page.dart
│   │   ├── home_page.dart
│   │   ├── login_page.dart
│   │   ├── novo_orcamento_page.dart
│   │   ├── pdf_preview_page.dart
│   │   ├── relatorio_page.dart
│   │   └── splash_page.dart
│   ├── services/             # Lógica de negócio e integrações
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── pdf_service.dart
│   ├── firestore_service.dart # Serviço legatário/base de dados
│   └── main.dart             # Ponto de entrada do aplicativo
├── linux/                    # Configurações nativas Linux
├── macos/                    # Configurações nativas macOS
├── web/                      # Configurações para Web
├── windows/                  # Configurações nativas Windows
├── pubspec.yaml              # Definição de dependências e assets
└── README.md                 # Documentação do projeto
```

## 🔌 Plugins e Dependências

### Dependências de Produção
- `firebase_core`: Integração básica com Firebase.
- `firebase_auth`: Autenticação de usuários.
- `cloud_firestore`: Banco de Dados NoSQL em nuvem.
- `google_sign_in`: Login via Google.
- `intl`: Internacionalização e formatação de datas/números.
- `pdf`: Geração de documentos PDF.
- `printing`: Visualização e impressão de arquivos.
- `image_picker`: Seleção de imagens da galeria ou câmera.
- `brasil_fields`: Máscaras e validações para padrões brasileiros.
- `path_provider`: Acesso a diretórios locais do sistema.
- `path`: Manipulação de caminhos de arquivos.
- `cupertino_icons`: Ícones padrão iOS.

### Dependências de Desenvolvimento
- `flutter_test`: Framework de testes unitários e de widget.
- `flutter_lints`: Regras de análise estática recomendadas.
- `flutter_launcher_icons`: Gerador automático de ícones do app.
- `flutter_native_splash`: Gerador de tela de abertura nativa.

---
*Este documento foi gerado automaticamente para mapear a extrutura do projeto.*
