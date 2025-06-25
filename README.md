# README.md

## 📱 App CMEI - Comunicação Digital com Famílias

Este projeto é um aplicativo mobile com backend em Python que visa substituir a agenda física usada por creches públicas (CMEIs), facilitando a comunicação entre profissionais da educação e famílias das crianças matriculadas.

---

### 🚀 Funcionalidades
- Login para pais e profissionais
- Publicação de avisos e recados
- Registro da rotina da criança (alimentação, sono, atividades)
- Notificações de saúde (medicação, doenças)
- Consulta ao calendário escolar e cardápio
- Notificações push (em planejamento)

---

### 🧱 Tecnologias Utilizadas
- **Backend**: FastAPI (Python)
- **Banco de Dados**: SQLite com SQLModel
- **Autenticação**: JWT com python-jose e passlib
- **Notificações**: Firebase Cloud Messaging (planejado)
- **Frontend (mobile)**: Flutter (Dart)
- **Hospedagem**: Railway / Render / Heroku (em definição)

---

### 🏗️ Estrutura do Projeto
```
app-creche/
├── backend/
│   ├── main.py
│   ├── models.py
│   ├── auth.py
│   ├── routes/
│   ├── database/
│   └── requirements.txt
├── frontend/
│   └── flutter_project/
├── planning.md
├── task.md
└── README.md
```

## 🚧 Status do MVP
- CRUD de avisos sem autenticação
- Configuração de CORS no backend
- Bypass de login para fluxo rápido (Device Preview)
- Integração com Device Preview para testes de UI
- Ajustes de responsividade na UI (login e calendário)
- Remoção de botão duplicado na tela de avisos

---

### ⚙️ Instalação e Execução do Backend
```bash
# Clonar repositório
$ git clone https://github.com/seu-usuario/app-creche.git
$ cd app-creche/backend

# Criar ambiente virtual
$ python -m venv venv
$ source venv/bin/activate  # ou venv\Scripts\activate no Windows

# Instalar dependências
$ pip install -r requirements.txt

# Rodar o servidor
$ uvicorn main:app --reload
```

---

### 🤝 Contribuição
Pull requests são bem-vindos! Sinta-se à vontade para abrir issues com dúvidas ou sugestões.

---

### 📄 Licença
MIT. Livre para uso, modificação e distribuição.

---

### 👨‍👩‍👧 Público-Alvo
- CMEIs e escolas públicas
- Pais/responsáveis por crianças
- Profissionais da educação infantil
