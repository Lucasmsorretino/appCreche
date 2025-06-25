# PLANNING.md

## 📱 Projeto: Aplicativo Mobile para CMEI (Creche Pública)

### 🧭 Visão Geral
Criação de um aplicativo mobile com backend em Python para facilitar a comunicação entre os profissionais de um CMEI (Centro Municipal de Educação Infantil) e as famílias, promovendo inclusão digital e melhorando o bem-estar infantil. Substitui a agenda física usada atualmente por um sistema digital com funcionalidades integradas.

### 🎯 Objetivos
- Melhorar a comunicação entre CMEI e famílias.
- Compartilhar avisos, rotina das crianças, dados de saúde e calendário escolar.
- Centralizar informações que atualmente estão espalhadas em documentos físicos ou sites pouco atualizados.

### 🧱 Arquitetura
- **Frontend mobile**: Flutter (Dart) [pode ser substituído futuramente]
- **Backend**: FastAPI (Python)
- **Banco de dados**: SQLite (desenvolvimento) /  (produção)
- **Autenticação**: JWT
- **Notificações Push**: Firebase Cloud Messaging (FCM)
- **Hospedagem backend**: Render, Railway ou Heroku

### 🔧 Tecnologias
| Camada         | Ferramenta             | Linguagem |
|----------------|------------------------|-----------|
| Frontend       | Flutter                | Dart      |
| Backend        | FastAPI                | Python    |
| Banco de dados | SQLite / SQLModel      | SQL       |
| CI/CD          | GitHub Actions         | YAML      |
| Versionamento  | Git + GitHub           | -         |
| Notificações   | Firebase Cloud Messaging| -        |

### 🗂️ Estrutura Inicial do Projeto
```
app-creche/
├── backend/
│   ├── main.py
│   ├── models.py
│   ├── routes/
│   └── database/
├── frontend/
│   └── flutter_project/ 
├── planning.md
├── task.md
└── README.md
```

## 🚧 Status do MVP
- CRUD de avisos sem autenticação
- Configuração de CORS no backend para permitir requisições do frontend
- Bypass de login no app (Device Preview) para fluxo rápido
- Integração com Device Preview para testes de UI

### 📌 Funcionalidades principais
- Login (pais e funcionários)
- Avisos e recados
- Rotina diária da criança
- Notificações/especficações de saúde (remédios, doenças)
- Calendário escolar e cardápio
- Notificações push

### 🧾 Restrições e Considerações
- O app precisa funcionar offline parcialmente (ex: salvar dados e sincronizar depois).
- Código será open source.
- Pode ser adaptado para uso em CEIs privados futuramente.

### 🧠 Prompt para uso futuro:
> “Use the structure and decisions outlined in PLANNING.md.”
