# Orça Sim

Gerenciador de orçamentos para prestadores de serviço. 

O **Orça Sim** é um aplicativo móvel desenvolvido em Flutter, focado em simplificar a vida de prestadores de serviço e freelancers. Ele atua como um gerenciador de orçamentos prático e rápido, permitindo que o profissional crie, organize e envie orçamentos profissionais em formato PDF diretamente do celular.

---

## ✨ Funcionalidades Principais

* **Autenticação Segura:** Login rápido e seguro utilizando conta Google ou E-mail/Senha.
* **Perfil da Empresa:** Cadastro dos dados do prestador (logo, nome, contato) para personalização automática dos documentos.
* **Geração de Orçamentos em PDF:** Criação de orçamentos detalhados, com cálculo automático de valores e layout profissional pronto para envio via WhatsApp ou E-mail.
* **Gestão de Clientes e Serviços:** Histórico e organização fácil para agilizar a criação de orçamentos recorrentes.
* **Painel de Controle:** Relatórios e acompanhamento do status financeiro dos orçamentos gerados.

---

## 📖 Manual do Usuário (Como Funciona)

O fluxo do aplicativo foi desenhado para ter o menor atrito possível no dia a dia corrido do prestador de serviço:

1. **Acesso:** Ao abrir o app, o usuário realiza o login (via Google).
2. **Configuração Inicial:** No primeiro acesso, preenche os dados da sua empresa ou negócio autônomo.
3. **Novo Orçamento:** Na tela inicial, acessa a criação de um novo documento, preenchendo os dados do cliente, descrição dos serviços e valores.
4. **Visualização e Envio:** O app gera um PDF (Preview) com os dados estruturados. Com um clique, o usuário pode salvar no dispositivo ou compartilhar diretamente com o cliente.
5. **Acompanhamento:** Na aba de relatórios, o usuário pode revisar todos os orçamentos emitidos anteriormente.

---

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

---

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