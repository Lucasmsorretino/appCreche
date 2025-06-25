# 🎛️ Guia de Teste - Device Preview

## 🚀 **Como Testar no Device Preview**

### **Opção 1: Skip Login (Recomendado para Desenvolvimento)**

**✅ Mais Fácil - Sem necessidade de backend ativo**

1. **Execute o app:**
   ```bash
   flutter run -d chrome
   ```

2. **Na tela de login:**
   - Clique no botão **"Skip Login (Dev Only)"** (botão cinza no final)
   - Isso ativa o `MockAuthService` automaticamente
   - Você será redirecionado para a página principal

3. **Funcionalidades disponíveis:**
   - ✅ Visualizar avisos (dados de teste)
   - ✅ Criar novos avisos
   - ✅ Editar avisos existentes
   - ✅ Excluir avisos
   - ✅ Navegação entre páginas
   - ✅ Todas as funcionalidades de admin

---

### **Opção 2: Login com Usuário de Teste (Requer Backend)**

**⚠️ Requer backend FastAPI rodando**

#### **Passo 1: Iniciar o Backend**
```bash
# No diretório backend/
cd ../backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### **Passo 2: Criar Usuário de Teste**
```bash
# No diretório backend/
python create_test_user.py
```

#### **Passo 3: Credenciais do Usuário de Teste**
```
👤 Username: lucas
🔒 Password: senha123
📧 Email: lucas@test.com
🎭 Tipo: TEACHER (funcionário)
```

#### **Passo 4: Fazer Login**
1. Execute o app: `flutter run -d chrome`
2. Na tela de login, insira:
   - **Email/Username:** `lucas`
   - **Password:** `senha123`
3. Clique em **"Entrar"**

---

## 📱 **Device Preview - Funcionalidades**

### **Dispositivos Disponíveis**
O Device Preview permite testar em:
- 📱 **iPhone** (vários tamanhos)
- 📱 **Android** (vários tamanhos)
- 📟 **iPad**
- 💻 **Desktop**

### **Como Usar o Device Preview**
1. **Selecionar Dispositivo:**
   - Use o painel lateral do Device Preview
   - Escolha entre iPhone, Android, iPad, etc.

2. **Rotacionar Tela:**
   - Clique no ícone de rotação
   - Teste landscape e portrait

3. **Zoom e Navegação:**
   - Use mouse para navegar
   - Scroll funciona normalmente

---

## 🎯 **Testes Recomendados**

### **1. Teste de Interface Responsiva**
```
📱 iPhone SE (375x667) - Tela pequena
📱 iPhone 14 (390x844) - Tela média  
📱 iPad (820x1180) - Tela grande
💻 Desktop (1920x1080) - Tela muito grande
```

### **2. Teste de Funcionalidades**
- ✅ **Login:** Usar "Skip Login (Dev Only)"
- ✅ **Avisos:** Visualizar, criar, editar, excluir
- ✅ **Navegação:** Entre páginas (Home, Avisos, Calendário, etc.)
- ✅ **Responsividade:** Layouts em diferentes tamanhos
- ✅ **Performance:** Scroll suave, animações

### **3. Teste de Dados**
- ✅ **Dados Locais:** 3 avisos de teste carregados automaticamente
- ✅ **CRUD:** Todas operações no banco local funcionando
- ✅ **Sincronização:** Funciona offline (backend opcional)

---

## 🛠️ **Comandos Úteis**

### **Executar com Device Preview**
```bash
# Chrome (recomendado para desenvolvimento)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Web (Edge)
flutter run -d edge
```

### **Hot Reload**
```bash
# Durante execução, pressione:
r  # Hot reload (recarregar código)
R  # Hot restart (reiniciar app)
q  # Quit (sair)
```

### **Debug**
```bash
# Abrir DevTools no navegador
# URL aparece no terminal após executar
http://127.0.0.1:9101?uri=...
```

---

## 🎮 **Fluxo de Teste Rápido**

### **Para Desenvolvedores (5 minutos)**
1. `flutter run -d chrome`
2. Clique **"Skip Login (Dev Only)"**
3. Teste no Device Preview:
   - Visualizar avisos
   - Criar um novo aviso
   - Testar em diferentes dispositivos
   - Verificar responsividade

### **Para Teste Completo (10 minutos)**
1. Iniciar backend: `cd ../backend && python -m uvicorn main:app --reload`
2. Criar usuário: `python create_test_user.py`
3. `flutter run -d chrome`
4. Login com `lucas` / `senha123`
5. Testar sincronização online/offline
6. Validar todas as funcionalidades

---

## 🐛 **Troubleshooting**

### **Se Device Preview não aparecer:**
```dart
// Verificar se está habilitado no main.dart
DevicePreview(
  enabled: !kReleaseMode, // Deve estar true em debug
  builder: (context) => CmeiApp(),
)
```

### **Se "Skip Login" não funcionar:**
- Verificar se `MockAuthService` está inicializado
- Logs devem mostrar: `"MockAuthService inicializado para desenvolvimento"`

### **Se avisos não carregarem:**
- Verificar logs: `"Avisos carregados: 3"`
- Dados são inseridos automaticamente no banco local

---

## ✅ **Resumo**

**Forma mais fácil de testar:**
1. `flutter run -d chrome`
2. **"Skip Login (Dev Only)"**
3. Testar no Device Preview com diferentes dispositivos

**Credenciais se precisar de login real:**
- **Username:** `lucas`
- **Password:** `senha123`

O Device Preview + Skip Login é a combinação perfeita para desenvolvimento e testes de UI! 🎉
