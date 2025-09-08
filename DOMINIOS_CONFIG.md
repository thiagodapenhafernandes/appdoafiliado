# 🌐 Configuração de Domínios - Link Flow

## ⚠️ DOMÍNIOS IMPORTANTES

### 🔧 Desenvolvimento
- **Base**: `https://dev.unitymob.com.br`
- **Cadastro**: `https://dev.unitymob.com.br/users/sign_up`
- **Login**: `https://dev.unitymob.com.br/users/sign_in`
- **Dashboard**: `https://dev.unitymob.com.br/dashboard`

### 🚀 Produção
- **Base**: `https://app.unitymob.com.br`
- **Cadastro**: `https://app.unitymob.com.br/users/sign_up`
- **Login**: `https://app.unitymob.com.br/users/sign_in`
- **Dashboard**: `https://app.unitymob.com.br/dashboard`

### 📧 Email
- **From**: `noreply@unitymob.com.br`
- **Suporte**: `support@unitymob.com.br`
- **Admin**: `admin@unitymob.com.br`

## 🔧 Configurações por Ambiente

### Development (.env)
```bash
APP_DOMAIN=dev.unitymob.com.br
APP_URL=https://dev.unitymob.com.br
SHOPEE_REDIRECT_URI=https://dev.unitymob.com.br/auth/shopee/callback
FROM_EMAIL=noreply@unitymob.com.br
SUPPORT_EMAIL=support@unitymob.com.br
```

### Production (.env.production)
```bash
APP_DOMAIN=app.unitymob.com.br
APP_URL=https://app.unitymob.com.br
SHOPEE_REDIRECT_URI=https://app.unitymob.com.br/auth/shopee/callback
FROM_EMAIL=noreply@unitymob.com.br
SUPPORT_EMAIL=support@unitymob.com.br
```

### Local Development (se necessário)
```bash
APP_DOMAIN=localhost:3000
APP_URL=http://localhost:3000
SHOPEE_REDIRECT_URI=http://localhost:3000/auth/shopee/callback
FROM_EMAIL=noreply@unitymob.com.br
SUPPORT_EMAIL=support@unitymob.com.br
```

## 📝 Arquivos Atualizados

### Configurações Rails
- ✅ `config/environments/development.rb`
- ✅ `config/environments/production.rb`
- ✅ `config/initializers/devise.rb`

### Environment Files
- ✅ `.env.example`
- ✅ `.env`

### Documentação
- ✅ `PROJETO_INSTRUCOES.md`
- ✅ `ADMIN_STRIPE_SETUP.md`

### Seeds & Data
- ✅ `db/seeds.rb`

## 🔄 Como Alternar Ambientes

### Para usar desenvolvimento remoto:
```bash
# No .env
APP_DOMAIN=dev.unitymob.com.br
APP_URL=https://dev.unitymob.com.br
```

### Para usar localhost:
```bash
# No .env
APP_DOMAIN=localhost:3000
APP_URL=http://localhost:3000
```

### Para produção:
```bash
# No .env.production ou variáveis do sistema
APP_DOMAIN=app.unitymob.com.br
APP_URL=https://app.unitymob.com.br
```

## 🎯 Links Importantes para Testes

### Development
- [Cadastro Dev](https://dev.unitymob.com.br/users/sign_up)
- [Login Dev](https://dev.unitymob.com.br/users/sign_in)
- [Dashboard Dev](https://dev.unitymob.com.br/dashboard)

### Production (quando disponível)
- [Cadastro Prod](https://app.unitymob.com.br/users/sign_up)
- [Login Prod](https://app.unitymob.com.br/users/sign_in)
- [Dashboard Prod](https://app.unitymob.com.br/dashboard)

---

**💡 Dica**: Sempre verificar se as variáveis de ambiente estão corretas ao fazer deploy ou mudanças de ambiente.
