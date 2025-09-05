# Sistema de Super Admin e Integração Stripe - Link Flow

## Visão Geral

O sistema Link Flow agora possui um sistema completo de administração com três níveis de acesso:

- **user**: Usuário padrão com acesso ao sistema básico
- **admin**: Administrador com acesso ao painel administrativo
- **super_admin**: Super administrador com acesso total, incluindo configurações Stripe

## Acesso ao Sistema Admin

### Credenciais do Super Admin
- **Email**: admin@linkflow.com
- **Senha**: admin123

### URLs de Acesso
- **Painel Admin**: `/admin/dashboard`
- **Gerenciar Usuários**: `/admin/users`
- **Gerenciar Planos**: `/admin/plans`
- **Configurar Stripe**: `/admin/stripe_config` (apenas super_admin)

## Configuração da Integração Stripe

### 1. Obter Chaves da API Stripe

1. Acesse [Stripe Dashboard](https://dashboard.stripe.com)
2. Crie uma conta ou faça login
3. Vá para **Developers > API keys**
4. Copie as chaves:
   - **Publishable key** (pk_test_...)
   - **Secret key** (sk_test_...)

### 2. Configurar Credenciais Rails

Execute o comando para editar as credenciais:
```bash
rails credentials:edit
```

Adicione as configurações Stripe:
```yaml
stripe:
  publishable_key: pk_test_sua_chave_publica_aqui
  secret_key: sk_test_sua_chave_secreta_aqui
  webhook_secret: whsec_sua_webhook_secret_aqui  # Opcional
```

### 3. Configurar Webhooks (Opcional)

1. No Stripe Dashboard, vá para **Developers > Webhooks**
2. Clique em **Add endpoint**
3. URL do endpoint: `https://seudominio.com/webhooks/stripe`
4. Selecione os eventos:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Copie o **Signing secret** (whsec_...)
6. Adicione às credenciais Rails

## Funcionalidades do Sistema Admin

### Painel Dashboard
- Estatísticas gerais do sistema
- Visão geral de usuários, planos e receita
- Assinaturas recentes
- Ações rápidas

### Gerenciamento de Usuários
- Lista todos os usuários do sistema
- Visualizar detalhes e assinaturas
- Alterar roles (user/admin/super_admin)
- Histórico de assinaturas

### Gerenciamento de Planos
- Criar novos planos de assinatura
- Editar planos existentes
- Sincronizar com Stripe automaticamente
- Visualizar estatísticas de cada plano

### Configuração Stripe (Super Admin)
- Status das configurações
- Sincronizar planos do Stripe
- Testar webhooks
- Lista de produtos Stripe

## Fluxo de Assinatura

1. **Usuário seleciona plano** → Frontend
2. **Sistema cria customer no Stripe** → StripeService
3. **Cria subscription no Stripe** → Retorna client_secret
4. **Frontend processa pagamento** → Stripe Elements
5. **Webhook confirma pagamento** → Ativa assinatura local

## Comandos Úteis

### Criar Super Admin
```bash
User.create!(
  email: 'admin@linkflow.com',
  password: 'admin123',
  first_name: 'Super',
  last_name: 'Admin',
  role: 'super_admin'
)
```

### Sincronizar Planos do Stripe
```bash
StripeService.sync_plans_from_stripe
```

### Criar Produto/Preço no Stripe
```ruby
plan = Plan.find(1)
StripeService.create_product_and_price(plan)
```

## Segurança

- Todas as rotas admin exigem autenticação
- Middlewares de autorização por role
- Proteção CSRF habilitada
- Verificação de assinatura webhook
- Logs de erro detalhados

## Estrutura de Arquivos

```
app/
├── controllers/
│   ├── admin/
│   │   ├── base_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── plans_controller.rb
│   │   ├── users_controller.rb
│   │   └── stripe_config_controller.rb
│   ├── concerns/
│   │   └── admin_authorization.rb
│   └── webhooks_controller.rb
├── services/
│   └── stripe_service.rb
├── helpers/
│   └── admin_helper.rb
└── views/
    ├── layouts/
    │   └── admin.html.erb
    └── admin/
        ├── dashboard/
        ├── plans/
        ├── users/
        └── stripe_config/
```

## Próximos Passos

1. **Configurar Stripe** com suas chaves
2. **Testar criação de planos** no painel admin
3. **Sincronizar com Stripe** existente (se houver)
4. **Configurar webhooks** para produção
5. **Personalizar features** dos planos conforme necessário

## Suporte

Para dúvidas ou problemas:
1. Verifique os logs Rails
2. Confirme configurações Stripe
3. Teste conexão com API Stripe
4. Valide webhooks em produção
