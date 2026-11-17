# FilaFácil UBS

Aplicativo mobile e web desenvolvido em **Flutter** para gestão inteligente de filas e agendamentos nas **Unidades Básicas de Saúde (UBS)**, projetado para operação pelos **Agentes Comunitários de Saúde**.

- **Design no Figma (Fluxo Completo & Design System):** [FilaFácil UBS - Telas Complementares](https://www.figma.com/design/caSnp2KsStnEkZ5HlVZcvi)
- **Repositório GitHub:** [hiagozavarize/app-filafacil](https://github.com/hiagozavarize/app-filafacil)

---

## Arquitetura e Boas Práticas

O projeto segue **Clean Architecture (Feature-First)** com separação clara entre **Domínio**, **Dados (Repositórios Remotos + Mock)** e **Apresentação (Riverpod + GoRouter)**, já pré-configurado para conexão imediata com Banco de Dados e API REST:

```text
lib/
├── core/
│   ├── config/env_config.dart             # Toggle USE_MOCK_BACKEND e URLs da API/WS
│   ├── errors/app_exception.dart          # Hierarquia selada (AppException)
│   ├── network/
│   │   ├── api_client.dart                # Cliente Dio + Interceptors JWT e Logs
│   │   └── api_endpoints.dart             # Todos os endpoints REST mapeados
│   ├── router/app_router.dart             # Rotas declarativas com GoRouter
│   ├── storage/secure_storage_service.dart# Armazenamento criptografado de tokens JWT
│   ├── theme/                             # Tokens "FilaFácil UBS Colors" e tipografia Poppins
│   └── widgets/                           # Componentes reutilizáveis do Design System
└── features/
    ├── auth/                              # Splash, Login, Cadastro, Perfil e AuthRepository
    ├── home/                              # Menu Inicial do Agente de Saúde
    ├── queue/                             # Adicionar na Fila, Senha Gerada, Consultar Fila, Chamar Paciente
    ├── stats/                             # Painel de Estatísticas e gráficos por especialidade/horário
    └── history/                           # Histórico de atendimentos e filtros por protocolo/status
```

---

## Como Executar

```bash
flutter pub get
flutter run
```

### Alternando para a API REST e Banco de Dados Real

Por padrão, `EnvConfig.useMockBackend` está habilitado (`true`) com dados pré-populados idênticos ao protótipo do Figma. Quando a API e o banco de dados estiverem prontos, basta executar:

```bash
flutter run \
  --dart-define=USE_MOCK_BACKEND=false \
  --dart-define=API_BASE_URL=https://sua-api.saude.gov.br/api/v1
```
