# FilaFácil UBS

Aplicativo mobile e web desenvolvido em **Flutter** para gestão inteligente de filas, triagem SUS e agendamentos nas **Unidades Básicas de Saúde (UBS)**.

- **API REST em Produção (Swagger):** [https://backend-filafacil.onrender.com/docs/](https://backend-filafacil.onrender.com/docs/)
- **Design no Figma (Fluxo Completo & Design System):** [FilaFácil UBS - Telas Complementares](https://www.figma.com/design/caSnp2KsStnEkZ5HlVZcvi)
- **Repositório GitHub:** [hiagozavarize/app-filafacil](https://github.com/hiagozavarize/app-filafacil)

---

## Integração com a API (`backend-filafacil`)

O aplicativo já está configurado por padrão para consumir a API em produção (`https://backend-filafacil.onrender.com`) com autenticação **Bearer JWT** persistida em armazenamento criptografado (`FlutterSecureStorage`):

- **Autenticação & Perfil:** `POST /api/auth/login`, `POST /api/auth/register`, `POST /api/auth/forgot-password`, `GET /api/users/profile`, `PUT /api/users/profile`, `PUT /api/users/change-password`
- **Pacientes (CADSUS):** `GET /api/patients/search`, `POST /api/patients`
- **Fila & Senhas (Prioridade Legal SUS):** `GET /api/tickets`, `GET /api/tickets/waiting`, `POST /api/tickets`, `POST /api/tickets/call-next`, `POST /api/tickets/{id}/call`, `POST /api/tickets/{id}/recall`, `POST /api/tickets/{id}/start`, `POST /api/tickets/{id}/finish`, `POST /api/tickets/{id}/absent`
- **Salas & Painel TV:** `GET /api/rooms`, `GET /api/tv/current-call`, `GET /api/tv/upcoming`
- **Métricas & Relatórios:** `GET /api/stats/dashboard`, `GET /api/stats/reports`, `GET /api/stats/export`
- **Histórico & Auditoria:** `GET /api/history`, `GET /api/history/{id}`, `GET /api/history/export`

---

## Arquitetura

O projeto segue **Clean Architecture (Feature-First)** com **Riverpod 3**, **GoRouter** e **Dio**:

```text
lib/
├── core/
│   ├── config/env_config.dart             # URL da API em produção e toggle USE_MOCK_BACKEND
│   ├── errors/app_exception.dart          # Hierarquia selada (AppException)
│   ├── network/
│   │   ├── api_client.dart                # Cliente Dio + Interceptor Bearer JWT e tratamento de erros
│   │   └── api_endpoints.dart             # Endpoints oficiais /api/... do backend-filafacil
│   ├── router/app_router.dart             # Rotas declarativas com GoRouter
│   ├── storage/secure_storage_service.dart# Armazenamento seguro de JWT
│   ├── theme/                             # Tokens "FilaFácil UBS Colors" e tipografia Poppins
│   └── widgets/                           # Componentes reutilizáveis do Design System
└── features/
    ├── auth/                              # Splash, Login, Cadastro, Recuperação de Senha e Perfil
    ├── home/                              # Menu Inicial do Agente de Saúde
    ├── queue/                             # Triagem CADSUS, Emissão de Senha, Fila SUS, Chamada e Consultório
    ├── stats/                             # Dashboard, Relatórios por Período e Exportação CSV
    └── history/                           # Histórico Retroativo, Auditoria de Atendimento e Exportação CSV
```

---

## Como Executar

### Conectado à API em produção (padrão)

```bash
flutter pub get
flutter run
```

### Apontando para servidor local ou modo offline (Mock)

```bash
# Servidor backend local
flutter run --dart-define=API_BASE_URL=http://localhost:3001

# Modo offline (dados mockados em memória)
flutter run --dart-define=USE_MOCK_BACKEND=true
```
