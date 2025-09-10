# 🚀 Link Flow - Sistema de Afiliação e Análise de Comissões

## 🆕 **ATUALIZAÇÃO v2.1 - Setembro 2025**

### ✨ Principais Funcionalidades Implementadas
- **🔄 Analytics Dual**: Sistema híbrido CSV + API Shopee com dados unificados
- **📊 Dashboard Avançado**: Gráficos interativos, KPIs em tempo real, export PDF
- **🖱️ Analytics de Cliques**: Análise completa de tráfego do website
- **🛒 Integração Shopee**: API completa com auth centralizada e individual
- **⚙️ Painel Admin**: Gestão completa do sistema para usuários Elite
- **💰 Controle de ROI**: Gestão de gastos por SubID com cálculos automáticos
- **🔐 Sistema de Permissões**: Controle granular por plano de assinatura
- **📱 Interface Responsiva**: Design moderno e mobile-first
- **💳 Sistema de Assinaturas**: Integração completa com Stripe - pagamento imediato (sem trial)
- **🎯 Formulário Unificado**: Cadastro + assinatura em uma única tela

### 🎯 Status do Projeto
**✅ TOTALMENTE FUNCIONAL** - Todas as funcionalidades core implementadas e testadas

### 🚨 ÚLTIMAS ATUALIZAÇÕES (Setembro 2025)
- ✅ **Stripe Sync Fix**: Corrigidos problemas de validação "Nome já está em uso"
- ✅ **Trial Removal**: Removido período de teste - todos os planos pagos agora exigem pagamento imediato
- ✅ **Unified Payment Form**: Formulário único para cadastro de conta + assinatura
- ✅ **Payment Flow**: Implementada validação completa do Stripe Elements
- ✅ **Environment Config**: Todas as variáveis movidas para .env (Stripe, DB, Shopee)
- 🔄 **Em Progresso**: Finalização do fluxo de pagamento com validação de cartão

### 📊 STATUS RESUMIDO - CONSULTA RÁPIDA

| Funcionalidade | Status | Última Atualização |
|---------------|--------|-------------------|
| 🔐 Autenticação | ✅ Funcionando | Stável |
| 💳 Sistema de Pagamentos | 🔄 99% - Debug final | Setembro 2025 |
| 📊 Dashboard Analytics | ✅ Funcionando | Stável |
| 🛒 Integração Shopee | ✅ Funcionando | Stável |
| ⚙️ Painel Admin | ✅ Funcionando | Stável |
| 🚀 Deploy/Produção | ✅ Funcionando | v21 atual |
| 📱 Interface Responsiva | ✅ Funcionando | Stável |

**🔥 FOCO ATUAL**: Resolver último bug de validação de token Stripe no formulário de pagamento

---

## 🌐 Domínios do Sistema

**⚠️ IMPORTANTE: Sempre usar os domínios corretos conforme o ambiente:**

- **🔧 Desenvolvimento**: `https://dev.appdoafiliado.com.br`
  - URL de cadastro: `https://dev.appdoafiliado.com.br/users/sign_up`
  - Base da aplicação: `https://dev.appdoafiliado.com.br`

- **🚀 Produção**: `https://app.appdoafiliado.com.br`
  - URL de cadastro: `https://app.appdoafiliado.com.br/users/sign_up`  
  - Base da aplicação: `https://app.appdoafiliado.com.br`

- **📧 Email**: `@appdoafiliado.com.br` (para ambos os ambientes)

## ⚙️ CONFIGURAÇÃO DE VARIÁVEIS DE AMBIENTE (.env)

**🔥 CRÍTICO: Todas as configurações ficam no arquivo `.env` na raiz do projeto**

### Stripe (Pagamentos)
```properties
STRIPE_PUBLISHABLE_KEY=pk_test_sua_chave_publica_stripe
STRIPE_SECRET_KEY=sk_test_sua_chave_secreta_stripe
STRIPE_WEBHOOK_SECRET=whsec_sua_chave_webhook_stripe
```

### Banco de Dados
```properties
DATABASE_URL=postgresql://postgres@localhost:5432/link_flow_development
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=link_flow_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=
```

### Shopee API
```properties
SHOPEE_APP_ID=placeholder
SHOPEE_APP_SECRET=placeholder
SHOPEE_REDIRECT_URI=https://dev.appdoafiliado.com.br/auth/shopee/callback
SHOPEE_BASE_URL=https://partner.test-stable.shopeemobile.com
```

### Aplicação
```properties
APP_DOMAIN=dev.appdoafiliado.com.br
APP_URL=https://dev.appdoafiliado.com.br
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base_will_be_generated
```

**⚠️ IMPORTANTE**: 
- Sempre verificar se as variáveis estão carregadas antes de fazer alterações
- Usar `Rails.configuration.stripe[:publishable_key]` no código, não ENV direto
- Reiniciar servidor após mudanças no .env

## 📋 Visão Geral do Projeto

Este é um sistema completo de gestão de links de afiliação com foco em análise de comissões da Shopee, desenvolvido em Ruby 3.3.5 on Rails 7.2.2, PostgreSQL, JavaScript puro e Tailwind CSS.

### 🎯 Objetivos Principais
1. **Redirecionamento Inteligente de Links** - Sistema de links encurtados para afiliação
2. **Dashboard de Análise de Comissões** - Análise detalhada de performance da Shopee
3. **Integração com API da Shopee** - Automação de dados via Shopee Open Platform
4. **Análise de Produtos** - Insights sobre produtos mais rentáveis
5. **Gestão de Campanhas** - Controle de investimentos e ROI
6. **Sistema de Assinaturas** - 3 planos via Stripe com limitações por funcionalidade
7. **Autenticação Segura** - Login/cadastro com tracking de dispositivos

### 🧠 Princípios de Desenvolvimento
- **Código Simples**: Métodos pequenos, classes focadas, responsabilidades únicas
- **Orientação a Objetos**: SOLID principles, design patterns quando necessário
- **Interface Minimalista**: UI limpa, funcional, sem excessos visuais
- **Performance First**: Soluções eficientes desde o início

---

## 🏗️ Arquitetura do Sistema

### Stack Tecnológica
- **Backend**: Ruby 3.3.5 + Rails 7.2.2 (API-first approach)
- **Database**: PostgreSQL (estrutura simples, índices estratégicos)
- **Frontend**: JavaScript Vanilla + Tailwind CSS (sem frameworks pesados)
- **PDF**: Prawn (mais leve que Wicked PDF)
- **Charts**: Chart.js (configuração mínima)
- **File Upload**: Active Storage (configuração básica)
- **Payments**: Stripe API (integração direta, sem gems extras)
- **Auth**: Devise (configuração mínima) + Device Tracking simples
- **Environment**: Dotenv (uma única fonte de verdade)
- **Jobs**: Sidekiq (processamento assíncrono eficiente)

### Estrutura de Pastas Principais
```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── dashboard_controller.rb
│   ├── links_controller.rb
│   ├── commissions_controller.rb
│   ├── subscriptions_controller.rb
│   └── webhooks_controller.rb
├── models/
│   ├── user.rb
│   ├── link.rb
│   ├── commission.rb
│   ├── subscription.rb
│   ├── plan.rb
│   └── device.rb
├── services/
│   ├── links/
│   │   ├── creator.rb
│   │   └── redirect_tracker.rb
│   ├── commissions/
│   │   ├── csv_processor.rb
│   │   └── analytics_calculator.rb
│   ├── stripe/
│   │   ├── customer_manager.rb
│   │   └── webhook_handler.rb
│   └── shopee/
│       └── api_client.rb
├── jobs/
│   ├── commission_import_job.rb
│   └── subscription_sync_job.rb
└── views/
    ├── layouts/
    │   └── application.html.erb
    ├── shared/
    │   └── _navbar.html.erb
    ├── dashboard/
    └── links/
```

### 🎨 Princípios de Design da Interface
- **Layout Limpo**: Grid simples, espaçamento consistente
- **Cores Mínimas**: Paleta reduzida (3-4 cores máximo)
- **Tipografia Simples**: 2 fonts máximo
- **Componentes Reutilizáveis**: Buttons, cards, forms padronizados
- **Mobile First**: Design responsivo desde o início

---

## � PROBLEMAS RESOLVIDOS RECENTEMENTE

### Sistema de Pagamentos (Setembro 2025)

#### ❌ Problemas Identificados e Resolvidos:
1. **Stripe Sync Validation Error**: "Nome já está em uso" ao sincronizar planos
   - **Causa**: Validação duplicada no modelo Plan
   - **Solução**: Removidas validações conflitantes, implementado sync seguro

2. **Trial Period Confusion**: Usuários queriam pagamento imediato, não trial
   - **Causa**: Lógica complexa de trial vs pagamento imediato
   - **Solução**: Removido trial completamente, sempre pagamento imediato

3. **Formulário de Pagamento Fragmentado**: UX confusa com múltiplas etapas
   - **Causa**: Formulários separados para conta e pagamento
   - **Solução**: Formulário unificado em `subscriptions/new.html.erb`

4. **Template Corruption**: Arquivo de view corrompido com sintaxe inválida
   - **Causa**: Edições manuais incorretas
   - **Solução**: Recriação completa do template com estrutura correta

#### 🔄 Problema Atual em Resolução:
**Payment Flow Bug**: "Dados do cartão são obrigatórios para planos pagos"
- ✅ **CAUSA IDENTIFICADA**: IDs duplicados `card-element` no HTML causando conflito no JavaScript
- ✅ **SOLUÇÃO IMPLEMENTADA**: Criados IDs únicos (`card-element` e `card-element-logged`)
- ✅ **JavaScript Atualizado**: Lógica para detectar qual elemento usar dinamicamente
- ✅ **Webhook Stripe Liberado**: Removida autenticação obrigatória que causava 401 Unauthorized
- 🔄 **Status**: Testando correção completa - webhook e formulário corrigidos
- **Próximos Passos**: 
  1. ✅ Verificar chaves Stripe no .env (RESOLVIDO)
  2. ✅ Corrigir JavaScript para usar `Rails.configuration.stripe[:publishable_key]`
  3. ✅ Corrigir IDs duplicados no HTML (RESOLVIDO)
  4. ✅ Liberar webhook Stripe da autenticação (RESOLVIDO)
  5. 🔄 Testar fluxo completo de pagamento

#### 📊 Debugging Info (Setembro 2025):
```ruby
# Logs mostram que usuário é criado mas pagamento falha:
# User Create successful, mas depois:
# "Dados do cartão são obrigatórios para planos pagos"
# Status 422 Unprocessable Content

# Investigação necessária:
# 1. JavaScript console errors
# 2. Network tab - token sendo enviado?
# 3. Stripe Elements montando corretamente?
```

### Arquitetura de Pagamentos Atual

#### Controller Flow (`SubscriptionsController`)
```ruby
def create
  # 1. Criar usuário se não logado
  if !user_signed_in? && params[:user].present?
    @user = create_user_from_params
    sign_in(@user) if @user.persisted?
  end
  
  # 2. Validar token do Stripe para planos pagos
  if @plan.price > 0 && params[:stripe_token].blank?
    flash[:alert] = 'Dados do cartão são obrigatórios para planos pagos.'
    render :new, status: :unprocessable_entity
  end
  
  # 3. Processar pagamento via StripeService
  stripe_result = StripeService.create_subscription_with_token(...)
end
```

#### JavaScript Integration
- **Stripe Elements**: Configurado para validação em tempo real
- **Token Creation**: `stripe.createToken(cardElement)` antes do submit
- **Validation**: Verificação de `cardValid` antes de submeter
- **Error Handling**: Exibição de erros do Stripe na interface

---

## �📊 Funcionalidades Core

### 1. Sistema de Autenticação e Assinaturas

#### Modelo `User`
```ruby
# Campos essenciais (Devise + customizações)
- email (string, unique, index) # Email do usuário
- encrypted_password (string) # Senha criptografada
- first_name (string) # Nome
- last_name (string) # Sobrenome
- subscription_id (references, index) # Assinatura ativa
- trial_ends_at (datetime) # Fim do período trial
- stripe_customer_id (string) # ID do cliente no Stripe
- role (string, default: 'user') # Papel do usuário (user, admin)
- created_at, updated_at

# Métodos simples e focados
def full_name
  "#{first_name} #{last_name}".strip
end

def on_trial?
  trial_ends_at&.future?
end

def active_subscription?
  subscription&.active?
end

def admin?
  role == 'admin'
end
```

#### Modelo `Subscription`
```ruby
# Campos essenciais
- user_id (references, index) # Usuário
- plan_id (references, index) # Plano escolhido
- stripe_subscription_id (string, unique) # ID no Stripe
- status (string, default: 'active') # active, canceled, past_due
- current_period_end (datetime) # Fim do período
- created_at, updated_at

# Métodos simples
def active?
  status == 'active' && current_period_end&.future?
end

def expired?
  !active?
end
```

#### Modelo `Plan`
```ruby
# Planos disponíveis
- name (string) # "Starter", "Pro", "Elite"
- description (text) # Descrição do plano
- price_cents (integer) # Preço em centavos
- currency (string, default: 'BRL') # Moeda
- stripe_price_id (string) # ID do preço no Stripe
- max_links (integer) # Limite de links
- features (json) # Funcionalidades incluídas
- popular (boolean, default: false) # Plano popular
- active (boolean, default: true) # Plano ativo
- created_at, updated_at
```

#### Modelo `Device`
```ruby
# Tracking de dispositivos
- user_id (references) # Usuário
- device_id (string, unique) # ID único do dispositivo
- device_type (string) # desktop, mobile, tablet
- browser (string) # Chrome, Firefox, Safari, etc.
- os (string) # Windows, macOS, iOS, Android
- ip_address (inet) # IP do device
- user_agent (text) # User agent completo
- last_seen_at (datetime) # Último acesso
- trusted (boolean, default: false) # Device confiável
- created_at, updated_at
```

#### Planos de Assinatura
```ruby
# Configuração dos 3 planos
PLANS = [
  {
    name: "Afiliado Starter",
    description: "Para iniciantes",
    price_cents: 5990, # R$ 59,90
    max_links: 15,
    features: [
      "15 links de redirecionamento",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas básicas",
      "Rastreamento básico",
      "Suporte via WhatsApp"
    ]
  },
  {
    name: "Afiliado Pro",
    description: "Mais popular",
    price_cents: 9790, # R$ 97,90
    max_links: 50,
    popular: true,
    features: [
      "50 links de redirecionamento",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas avançadas",
      "Rastreamento avançado",
      "Suporte via WhatsApp"
    ]
  },
  {
    name: "Afiliado Elite",
    description: "Para Experts",
    price_cents: 14790, # R$ 147,90
    max_links: -1, # Ilimitado
    features: [
      "Links ilimitados",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas avançadas",
      "Rastreamento avançado",
      "Suporte via WhatsApp",
      "Suporte estratégico"
    ]
  }
]
```

### 2. Sistema de Análise de Dados e Comissões

#### Sistema de Analytics Avançado
O sistema agora possui duas fontes principais de dados:

**A. Analytics Unificado (CSV + API)**
- **Controller**: `AnalyticsController` - Dashboard principal com dados unificados
- **Funcionalidades**:
  - Upload de CSV da Shopee com análise automática
  - Integração via API da Shopee (quando disponível)
  - Análise de comissões diretas vs indiretas
  - KPIs: Total de comissões, vendas, pedidos, ticket médio, taxa de conversão
  - Gráficos: Evolução diária, performance por canal, categoria e SubID
  - Export em PDF dos relatórios

**B. Analytics de Cliques (Website Clicks)**
- **Controller**: `ClicksAnalyticsController` - Análise de cliques nos links
- **Model**: `WebsiteClick` - Dados de cliques importados via CSV
- **Funcionalidades**:
  - Análise de cliques por referenciador (Instagram, Facebook, etc.)
  - Análise geográfica (por região)
  - Análise temporal (por hora do dia, dia da semana)
  - Identificação de picos de tráfego
  - Tracking de SubIDs com cliques

#### Modelo `Commission` (Dados CSV)
```ruby
# Campos baseados no CSV da Shopee
- user_id (references, index) # Proprietário da comissão
- order_id (string, index) # ID do pedido
- sub_id (string, index) # SubID da campanha
- channel (string, index) # Canal (Instagram, Facebook, etc.)
- commission_amount (decimal, precision: 10, scale: 2) # Valor da comissão
- sale_amount (decimal, precision: 10, scale: 2) # Valor da venda
- product_name (string) # Nome do produto
- order_date (date, index) # Data do pedido
- order_status (string) # Status do pedido
- commission_type (string) # Tipo de comissão (direct/indirect)
- category (string) # Categoria do produto
- commission_date (datetime) # Data da comissão
- source (string, default: 'csv') # Fonte dos dados
- affiliate_commission (decimal) # Valor da comissão do afiliado
- purchase_value (decimal) # Valor da compra
- created_at, updated_at

# Métodos para cálculos
def self.total_commissions
  sum(:affiliate_commission)
end

def self.total_sales
  sum(:purchase_value)
end

def self.by_channel(channel_name)
  where(channel: channel_name)
end

def self.by_date_range(start_date, end_date)
  where(order_date: start_date..end_date)
end

def self.from_csv
  where(source: 'csv')
end

def self.from_api
  where(source: 'shopee_api')
end
```

#### Modelo `AffiliateConversion` (Dados API Shopee)
```ruby
# Campos baseados na API da Shopee
- user_id (references, index) # Proprietário
- external_id (string, unique) # ID único da API
- order_id (string) # ID do pedido
- item_id (string) # ID do item
- category (string) # Categoria do produto
- channel (string) # Canal de origem
- sub_id (string) # SubID da campanha
- commission_cents (integer) # Comissão em centavos
- currency (string, default: 'BRL') # Moeda
- quantity (integer) # Quantidade
- click_time (datetime) # Tempo do clique
- conversion_time (datetime) # Tempo da conversão
- status (string) # Status da conversão
- source (string, default: 'shopee_api') # Fonte dos dados
- raw_data (json) # Dados brutos da API
- purchase_value (decimal) # Valor da compra
- commission_rate (decimal) # Taxa de comissão
- shopee_affiliate_integration_id (references) # Integração relacionada
- created_at, updated_at

# Métodos de conversão
def commission_amount
  commission_cents / 100.0 if commission_cents.present?
end

def from_api?
  source == 'shopee_api'
end

def completed?
  status == 'completed'
end
```

#### Modelo `WebsiteClick` (Analytics de Cliques)
```ruby
# Campos para análise de cliques
- click_id (string, unique) # ID único do clique
- click_time (datetime) # Horário do clique
- region (string) # Região geográfica
- sub_id (string) # SubID relacionado
- referrer (string) # Fonte do tráfego
- user_id (references) # Proprietário
- created_at, updated_at

# Métodos para análise
def self.total_clicks_all_time(user)
  where(user: user).count
end

def self.clicks_by_referrer_all_time(user)
  where(user: user).group(:referrer).count
end

def self.clicks_by_region_all_time(user)
  where(user: user).group(:region).count
end

def self.clicks_by_hour_all_time(user)
  where(user: user).group_by_hour(:click_time).count
end
```

#### Modelo `SubidAdSpend` (Investimentos em Anúncios)
```ruby
# Controle de gastos por SubID
- user_id (references) # Usuário
- subid (string) # SubID da campanha
- ad_spend (decimal) # Gasto em anúncios
- total_investment (decimal) # Investimento total
- period_start (date) # Início do período
- period_end (date) # Fim do período
- created_at, updated_at

# Métodos para cálculo de ROI
def self.ad_spend_for_subid(user, subid, date = Date.current)
  for_subid(subid)
    .where(user: user)
    .for_period(date, date)
    .sum(:ad_spend)
end
```

#### Modelo `Link`
```ruby
# Campos essenciais
- short_code (string, unique, index) # Código único (6 chars)
- original_url (text) # URL original de afiliação
- title (string) # Título do produto/campanha
- clicks_count (integer, default: 0) # Contador de cliques
- active (boolean, default: true, index) # Status do link
- user_id (references, index) # Proprietário do link
- created_at, updated_at

# Métodos focados
def short_url
  "#{ENV['APP_URL']}/go/#{short_code}"
end

def increment_clicks!
  increment!(:clicks_count)
end

def self.generate_short_code
  loop do
    code = SecureRandom.alphanumeric(6).upcase
    break code unless exists?(short_code: code)
  end
end
```

#### Funcionalidades Simples
- Geração automática de códigos únicos (6 caracteres)
- Tracking básico de cliques
- URLs amigáveis: `https://seudominio.com/go/ABC123`
- Dashboard simples de performance

### 2. Dashboard de Análise de Comissões

#### Modelo `Commission`
```ruby
# Campos baseados no CSV da Shopee
- user_id (references, index) # Proprietário da comissão
- order_id (string, index) # ID do pedido
- sub_id (string, index) # SubID da campanha
- channel (string, index) # Canal (Instagram, Facebook, etc.)
- commission_amount (decimal, precision: 10, scale: 2) # Valor da comissão
- sale_amount (decimal, precision: 10, scale: 2) # Valor da venda
- product_name (string) # Nome do produto
- order_date (date, index) # Data do pedido
- created_at, updated_at

# Métodos simples para cálculos
def self.total_commissions
  sum(:commission_amount)
end

def self.total_sales
  sum(:sale_amount)
end

def self.by_channel(channel_name)
  where(channel: channel_name)
end

def self.by_date_range(start_date, end_date)
  where(order_date: start_date..end_date)
end
```

### 3. Sistema de Redirecionamento de Links

#### Modelo `Link`
```ruby
# Campos essenciais
- short_code (string, unique, index) # Código único (6 chars)
- original_url (text) # URL original de afiliação
- title (string) # Título do produto/campanha
- description (text) # Descrição do link
- clicks_count (integer, default: 0) # Contador de cliques
- active (boolean, default: true, index) # Status do link
- user_id (references, index) # Proprietário do link
- campaign_id (references) # Campanha relacionada
- created_at, updated_at

# Métodos focados
def short_url
  "#{ENV['APP_URL']}/go/#{short_code}"
end

def increment_clicks!
  increment!(:clicks_count)
end

def self.generate_short_code
  loop do
    code = SecureRandom.alphanumeric(6).upcase
    break code unless exists?(short_code: code)
  end
end
```

#### Funcionalidades Simples
- Geração automática de códigos únicos (6 caracteres)
- Tracking básico de cliques
- URLs amigáveis: `https://seudominio.com/go/ABC123`
- Dashboard simples de performance

### 4. Sistema de Integração com Shopee API

#### Modelo `ShopeeAffiliateIntegration`
```ruby
# Configuração da integração Shopee por usuário
- user_id (references, unique) # Usuário proprietário
- app_id (string) # App ID fornecido pela Shopee
- encrypted_secret (text) # Secret criptografado
- encrypted_secret_iv (string) # IV para descriptografia
- market (string, default: 'BR') # Mercado (BR, US, etc.)
- endpoint (string) # Endpoint da API
- last_sync_at (datetime) # Última sincronização
- active (boolean, default: true) # Status da integração
- last_error (text) # Último erro da API
- sync_count (integer, default: 0) # Contador de sincronizações
- use_centralized_auth (boolean) # Usar auth centralizada
- access_token (text) # Token de acesso (se centralizada)
- refresh_token (text) # Token de refresh
- token_expires_at (datetime) # Expiração do token
- created_at, updated_at

# Métodos de integração
def decrypt_secret
  # Descriptografia do secret
end

def test_connection
  # Testa conexão com a API
end

def sync_conversions
  # Sincroniza conversões
end
```

#### Modelo `ShopeeApiRequest` (Log de Requisições)
```ruby
# Log das requisições à API Shopee
- user_id (references) # Usuário
- request_type (string) # Tipo da requisição
- endpoint (string) # Endpoint chamado
- request_params (json) # Parâmetros enviados
- response_status (integer) # Status HTTP
- response_body (text) # Resposta da API
- processing_time (float) # Tempo de processamento
- created_at, updated_at

# Métodos para debugging
def success?
  response_status.between?(200, 299)
end

def error?
  !success?
end
```

#### Modelo `ShopeeMasterConfig` (Configuração Centralizada)
```ruby
# Configuração centralizada da Shopee (para mercados que suportam)
- market (string, unique) # Mercado (BR, US, etc.)
- app_id (string) # App ID centralizado
- encrypted_secret (text) # Secret criptografado
- auth_endpoint (string) # Endpoint de autenticação
- api_endpoint (string) # Endpoint da API
- active (boolean, default: true) # Status
- created_at, updated_at

# Métodos de configuração
def self.for_market(market)
  find_by(market: market, active: true)
end

def centralized_available?
  active? && app_id.present? && encrypted_secret.present?
end
```

### 5. Dashboard de Análise de Comissões  
#### KPIs Essenciais Implementados
1. **Total de Comissões** - Soma de comissões (CSV + API)
2. **Total de Vendas** - Soma de vendas (CSV + API)
3. **Número de Pedidos** - Contagem de pedidos
4. **Ticket Médio** - Valor médio por pedido
5. **Taxa de Conversão** - Calculada automaticamente
6. **Análise por Canal** - Performance por Instagram, Facebook, etc.
7. **Análise por SubID** - ROI por campanha específica
8. **Análise Temporal** - Evolução diária/mensal
9. **Top Produtos** - Produtos mais rentáveis
10. **Análise Geográfica** - Cliques por região

#### Service `CsvImportService`
```ruby
# Processamento unificado de CSVs
class CsvImportService
  def initialize(user, file, import_type)
    @user = user
    @file = file
    @import_type = import_type # 'commissions' ou 'clicks'
  end

  def process
    case @import_type
    when 'commissions'
      process_commissions_csv
    when 'clicks'
      process_clicks_csv
    end
  end

  private

  def process_commissions_csv
    # Processa CSV de comissões da Shopee
    # Campos: order_id, commission_amount, sale_amount, channel, etc.
  end

  def process_clicks_csv
    # Processa CSV de cliques do site
    # Campos: click_id, click_time, region, referrer, sub_id
  end
end
```

#### Service `AnalyticsPdfService`
```ruby
# Geração de relatórios em PDF
class AnalyticsPdfService
  def initialize(user, data)
    @user = user
    @data = data
  end

  def generate
    # Gera PDF com:
    # - Resumo executivo
    # - Gráficos principais
    # - Tabelas detalhadas
    # - Análise por período
  end
end
```

### 6. Sistema Administrativo

#### Painel Administrativo Completo
O sistema possui um painel administrativo robusto acessível via `/admin`:

**A. Dashboard Administrativo (`/admin/dashboard`)**
- Visão geral de usuários ativos
- Estatísticas de uso do sistema
- Monitoramento de integrações

**B. Gestão de Usuários (`/admin/users`)**
- Lista completa de usuários
- Alteração de papéis (user/admin)
- Visualização de assinaturas
- Histórico de atividades

**C. Gestão de Planos (`/admin/plans`)**
- CRUD completo de planos
- Sincronização com Stripe
- Ativação/desativação de planos
- Configuração de funcionalidades por plano

**D. Configurações do Sistema (`/admin/settings`)**
- Configurações globais
- Reset para defaults
- Variáveis de ambiente
- Logs do sistema

**E. Configuração Stripe (`/admin/stripe_config`)**
- Sincronização de planos com Stripe
- Teste de webhooks
- Atualização de configurações
- Monitoramento de pagamentos

**F. Configuração Shopee (`/admin/shopee_configs`)**
- Gestão de configurações centralizadas da Shopee
- Teste de conexões API
- Ativação/desativação por mercado
- Monitoramento de integrações

#### Modelo `Setting` (Configurações do Sistema)
```ruby
# Configurações globais do sistema
- key (string, unique) # Chave da configuração
- value (text) # Valor da configuração
- description (text) # Descrição da configuração
- setting_type (string) # Tipo (string, integer, boolean, json)
- created_at, updated_at

# Métodos para configuração
def self.get(key, default = nil)
  setting = find_by(key: key)
  setting ? setting.parsed_value : default
end

def self.set(key, value, description = nil)
  setting = find_or_initialize_by(key: key)
  setting.value = value.to_s
  setting.description = description if description
  setting.save!
end

def parsed_value
  case setting_type
  when 'boolean'
    value.to_s.downcase == 'true'
  when 'integer'
    value.to_i
  when 'json'
    JSON.parse(value) rescue {}
  else
    value
  end
end
```

### 7. Upload e Processamento de CSV

#### Sistema de Upload Unificado
O sistema agora suporta múltiplos tipos de CSV:

**A. CSV de Comissões da Shopee**
- Dados de pedidos, comissões e produtos
- Análise automática de performance
- Cálculo de ROI por SubID

**B. CSV de Cliques do Website**
- Dados de tráfego e cliques
- Análise de origens de tráfego
- Identificação de padrões de clique

#### Service `CsvImportService` (Unificado)
```ruby
# Classe focada em uma responsabilidade
class CsvImportService
  def initialize(user, file, import_type)
    @user = user
    @file = file
    @import_type = import_type
  end

  def process
    validate_file!
    case @import_type
    when 'commissions'
      import_commissions
    when 'clicks'
      import_clicks
    end
    calculate_analytics
  end

  private

  def validate_file!
    # Validações simples e diretas
  end

  def import_commissions
    # Import em batches para performance
    # Mapeamento automático de colunas
  end

  def import_clicks
    # Import de dados de cliques
    # Análise de padrões de tráfego
  end

  def calculate_analytics
    # Recálculo automático de métricas
  end
end
```

#### Validações dos CSVs

**Para CSV de Comissões:**
- Headers obrigatórios: order_id, commission_amount, sale_amount, channel
- Formato UTF-8
- Máximo 5.000 registros por arquivo
- Duplicatas ignoradas automaticamente

**Para CSV de Cliques:**
- Headers obrigatórios: click_id, click_time, region, referrer
- Formato UTF-8
- SubID opcional
- Máximo 10.000 registros por arquivo

#### Estruturas Esperadas dos CSVs

**CSV de Comissões Shopee:**
```csv
order_id,sub_id,channel,commission_amount,sale_amount,order_status,commission_type,product_name,category,order_date,commission_date
202509041001,gerenciadorautoexcellante,instagram,2.89,28.90,completed,direct,Produto Exemplo,electronics,2025-09-04 10:30:00,2025-09-04 12:00:00
202509041002,estantenovovidovi,facebook,3.45,34.50,completed,indirect,Outro Produto,fashion,2025-09-04 11:15:00,2025-09-04 13:30:00
```

**CSV de Cliques do Website:**
```csv
click_id,click_time,region,sub_id,referrer
CLK001,2025-09-04 10:30:00,SP,gerenciadorautoexcellante,instagram.com
CLK002,2025-09-04 11:15:00,RJ,estantenovovidovi,facebook.com
CLK003,2025-09-04 12:00:00,MG,----,google.com
```

### 8. Integração Avançada com Shopee API

#### Arquitetura de Integração
O sistema possui uma arquitetura robusta para integração com a API da Shopee:

**A. Configuração Flexível**
- Suporte a credenciais individuais por usuário
- Configuração centralizada para mercados específicos
- Fallback automático entre métodos de autenticação

**B. Services Especializados**
- `ShopeeAffiliate::AuthService` - Gerenciamento de autenticação
- `ShopeeAffiliate::Client` - Cliente HTTP para requisições
- `ShopeeAffiliate::CentralizedClient` - Cliente para auth centralizada
- `ShopeeAffiliate::SyncService` - Sincronização de dados
- `ShopeeAffiliate::ConversionParser` - Parser de conversões

#### Fluxo de Sincronização
```ruby
# 1. Autenticação
auth_service = ShopeeAffiliate::AuthService.new(integration)
auth_service.authenticate!

# 2. Sync de conversões
sync_service = ShopeeAffiliate::SyncService.new(integration)
sync_service.sync_recent_conversions

# 3. Parse e armazenamento
parser = ShopeeAffiliate::ConversionParser.new(raw_data)
parser.parse_and_store(user)
```

### 9. Gráficos e Visualizações Avançadas

#### Chart.js - Implementação Avançada
O sistema possui gráficos interativos e informativos:

**1. Analytics Principal (`/analytics`)**
- **Evolução Diária de Comissões** (Line Chart)
- **Performance por Canal** (Bar Chart horizontal)
- **Performance por Categoria** (Doughnut Chart)
- **Top Produtos** (Bar Chart)
- **Análise por SubID** (Tabela dinâmica)

**2. Analytics de Cliques (`/clicks_analytics`)**
- **Cliques por Referenciador** (Bar Chart)
- **Cliques por Região** (Map Chart)
- **Cliques por Hora** (Line Chart)
- **Cliques por Dia** (Calendar Heatmap)

**3. Funcionalidades dos Gráficos:**
- Hover com detalhes
- Legenda interativa
- Responsivo (mobile-first)
- Cores consistentes
- Animações suaves
- Export de imagem (PNG/SVG)

#### Estrutura de Dados para Gráficos
```javascript
// Exemplo de estrutura para Chart.js
const chartData = {
  labels: ['Instagram', 'Facebook', 'Google', 'Direct'],
  datasets: [{
    label: 'Comissões (R$)',
    data: [1250.50, 890.30, 650.20, 420.10],
    backgroundColor: ['#E1306C', '#1877F2', '#4285F4', '#6B7280'],
    borderColor: ['#C13584', '#166FE5', '#3367D6', '#4B5563'],
    borderWidth: 2
  }]
};
```

### 10. Recursos Premium por Plano

#### Controle de Acesso Implementado
O sistema possui verificação rigorosa de funcionalidades por plano:

```ruby
# app/controllers/concerns/plan_restrictions.rb
module PlanRestrictions
  extend ActiveSupport::Concern

  private

  def check_analytics_access
    unless current_user.plan_allows?('advanced_analytics')
      redirect_to plans_path, alert: 'Upgrade necessário para acessar analytics avançados'
    end
  end

  def check_pdf_export_access
    unless current_user.plan_allows?('pdf_export')
      redirect_to plans_path, alert: 'Upgrade necessário para exportar relatórios'
    end
  end

  def check_advanced_tracking_access
    unless current_user.plan_allows?('advanced_tracking')
      redirect_to plans_path, alert: 'Upgrade necessário para tracking avançado'
    end
  end

  def check_api_access
    unless current_user.plan_allows?('api_access')
      redirect_to plans_path, alert: 'Upgrade necessário para acesso à API'
    end
  end
end
```

#### Funcionalidades Detalhadas por Plano

**🥉 Afiliado Starter (R$ 59,90/mês)**
- ✅ 15 links de redirecionamento
- ✅ Upload de CSV básico (comissões)
- ✅ Dashboard principal com KPIs essenciais
- ✅ Gráficos básicos (evolução diária, por canal)
- ✅ Tabela de comissões simples
- ✅ Suporte via WhatsApp
- ❌ Analytics de cliques
- ❌ Export PDF
- ❌ API Shopee
- ❌ Análise avançada de ROI

**🥈 Afiliado Pro (R$ 97,90/mês) - Mais Popular**
- ✅ 50 links de redirecionamento
- ✅ Todas as funcionalidades do Starter
- ✅ Analytics de cliques completo
- ✅ Upload de múltiplos CSVs (comissões + cliques)
- ✅ Gráficos avançados (todos os tipos)
- ✅ Export PDF de relatórios
- ✅ Análise de ROI por SubID
- ✅ Controle de gastos em anúncios
- ✅ Integração básica com API Shopee
- ✅ Alertas por email
- ❌ Suporte estratégico

**🥇 Afiliado Elite (R$ 147,90/mês)**
- ✅ Links ilimitados
- ✅ Todas as funcionalidades do Pro
- ✅ Integração completa API Shopee (auto-sync)
- ✅ Dashboard administrativo (se admin)
- ✅ Configurações avançadas
- ✅ Relatórios personalizados
- ✅ Suporte prioritário
- ✅ Consultoria estratégica
- ✅ Beta access para novas features
- ✅ White-label options (futuro)

---

## �️ Estrutura de Rotas Implementadas

### Rotas Principais da Aplicação

```ruby
# Autenticação (Devise)
devise_for :users, controllers: {
  registrations: 'users/registrations'
}

# Dashboard Principal
root 'home#index'                    # Landing page
get 'dashboard', to: 'dashboard#index' # Dashboard do usuário

# Analytics (Funcionalidades Core)
get 'analytics', to: 'analytics#index'           # Dashboard principal
get 'analytics/performance'                      # Performance detalhada
get 'analytics/conversion'                       # Análise de conversão
get 'analytics/import_csv'                       # Upload de CSV
post 'analytics/import_csv'                      # Processar CSV
get 'analytics/export_pdf'                       # Export PDF (Pro+)
patch 'analytics/update_ad_spend'                # Atualizar gastos

# Analytics de Cliques (Pro+)
get 'clicks_analytics', to: 'clicks_analytics#index'

# Gestão de Links
resources :links, except: [:create, :edit, :update, :destroy] do
  collection do
    post :create      # Criar link
    post :preview     # Preview do link
  end
  member do
    get :edit         # Editar link
    patch :update     # Atualizar link
    delete :destroy   # Excluir link
  end
end

# Redirecionamento de Links
get '/go/:short_code', to: 'redirect#show', as: :redirect_link

# Planos e Assinaturas (Stripe)
resources :plans, only: [:index, :show]
resources :subscriptions, only: [:new, :create, :show] do
  member do
    get 'payment'     # Página de pagamento
  end
end

# Integração Shopee (Pro+)
resource :shopee_integration, only: [:show, :new, :create, :edit, :update, :destroy] do
  member do
    post 'test_connection'  # Testar conexão
    post 'sync_now'         # Sincronizar agora
    post 'backfill'         # Sync histórico
    patch 'toggle_status'   # Ativar/desativar
  end
end

# Painel Administrativo (Elite)
namespace :admin do
  resources :dashboard, only: [:index]
  resources :plans do
    member do
      patch :sync_with_stripe  # Sincronizar com Stripe
    end
  end
  resources :users do
    member do
      patch :change_role       # Alterar papel do usuário
    end
  end
  resources :settings do
    collection do
      post :reset_defaults     # Reset configurações
    end
  end
  resources :stripe_config, only: [:index] do
    collection do
      post :sync_plans         # Sincronizar planos
      post :test_webhook       # Testar webhook
      patch :update_config     # Atualizar config
    end
  end
  resources :shopee_configs do
    member do
      post :test_connection    # Testar API
      patch :toggle_status     # Ativar/desativar
    end
  end
end

# Webhooks
post '/webhooks/stripe', to: 'webhooks#stripe'
```

### Estrutura de Controllers Implementados

```
app/controllers/
├── application_controller.rb        # Base controller
├── home_controller.rb              # Landing page
├── dashboard_controller.rb          # Dashboard principal
├── analytics_controller.rb          # Analytics principal (739 linhas)
├── clicks_analytics_controller.rb   # Analytics de cliques (157 linhas)
├── links_controller.rb              # Gestão de links
├── redirect_controller.rb           # Redirecionamento
├── plans_controller.rb              # Planos
├── subscriptions_controller.rb      # Assinaturas
├── shopee_integrations_controller.rb # Integração Shopee (214 linhas)
├── webhooks_controller.rb           # Webhooks Stripe
├── admin/                           # Painel administrativo
│   ├── base_controller.rb
│   ├── dashboard_controller.rb
│   ├── plans_controller.rb
│   ├── users_controller.rb
│   ├── settings_controller.rb
│   ├── stripe_config_controller.rb
│   └── shopee_configs_controller.rb
└── users/
    └── registrations_controller.rb  # Customização Devise
```

---

### Abordagem de Desenvolvimento
**Eu vou programar tudo do zero, seguindo estas etapas práticas:**

### Sprint 1 (Dias 1-3): Base Sólida ⚡
**Objetivo: Aplicação Rails funcionando com autenticação básica**

#### Dia 1: Setup Inicial
```bash
# 1. Criar projeto Rails
rails new link_flow --database=postgresql --css=tailwind --skip-test

# 2. Configurar gems essenciais
# - devise (auth)
# - dotenv-rails (env vars)
# - sidekiq (jobs)
```

**Entregas do Dia 1:**
- ✅ Projeto Rails configurado
- ✅ PostgreSQL conectado
- ✅ Tailwind funcionando
- ✅ Dotenv configurado
- ✅ .env.example criado

#### Dia 2: Autenticação + Models Base
```ruby
# Models que vou criar:
# - User (devise)
# - Plan (planos de assinatura)
# - Subscription (assinaturas)
# - Link (links encurtados)
```

**Entregas do Dia 2:**
- ✅ Devise configurado e funcionando
- ✅ Models User, Plan, Subscription, Link criados
- ✅ Migrations rodadas
- ✅ Seeds básicos dos planos
- ✅ Views de login/cadastro customizadas (simples)

#### Dia 3: Sistema de Links Básico
```ruby
# Controllers que vou criar:
# - LinksController (CRUD)
# - RedirectController (redirecionamento)
# - DashboardController (página inicial)
```

**Entregas do Dia 3:**
- ✅ CRUD de links funcionando
- ✅ Redirecionamento /go/:code funcionando
- ✅ Dashboard básico (sem gráficos ainda)
- ✅ Tracking simples de cliques
- ✅ Interface minimalista com Tailwind

### Sprint 2 (Dias 4-6): Sistema de Assinaturas 💳
**Objetivo: Stripe integrado com 3 planos funcionando**

#### Dia 4: Stripe Setup
```ruby
# Services que vou criar:
# - Stripe::CustomerManager
# - Stripe::SubscriptionManager
```

**Entregas do Dia 4:**
- ✅ Stripe configurado (test mode)
- ✅ Checkout básico funcionando
- ✅ Webhooks endpoint criado
- ✅ Página de planos simples

#### Dia 5: Lógica de Assinaturas
```ruby
# Funcionalidades:
# - Trial de 14 dias automático
# - Limitações por plano
# - Status de assinatura
```

**Entregas do Dia 5:**
- ✅ Trial period funcionando
- ✅ Limitações de links por plano
- ✅ Status da assinatura no dashboard
- ✅ Upgrade/downgrade básico

#### Dia 6: Polimento + Testes
**Entregas do Dia 6:**
- ✅ Webhooks do Stripe funcionando
- ✅ Emails de confirmação (básicos)
- ✅ Error handling
- ✅ Testes manuais completos

### Sprint 3 (Dias 7-9): Dashboard de Comissões 📊
**Objetivo: Upload CSV + Dashboard com gráficos básicos**

#### Dia 7: Model Commission + CSV Upload
```ruby
# Model que vou criar:
# - Commission (dados da Shopee)
# Service que vou criar:
# - Commissions::CsvProcessor
```

**Entregas do Dia 7:**
- ✅ Model Commission criado
- ✅ Upload de CSV funcionando
- ✅ Processamento básico em background
- ✅ Validações essenciais

#### Dia 8: Dashboard com KPIs
```ruby
# Controllers:
# - CommissionsController
# Helper methods para cálculos
```

**Entregas do Dia 8:**
- ✅ Cards com KPIs principais
- ✅ Lista de comissões (tabela simples)
- ✅ Filtros básicos (por período)
- ✅ Responsive design

#### Dia 9: Gráficos Básicos
```javascript
// Chart.js integration:
// - Comissões por canal
// - Evolução mensal
```

**Entregas do Dia 9:**
- ✅ Chart.js integrado
- ✅ 2 gráficos básicos funcionando
- ✅ Dados em tempo real
- ✅ Design limpo e funcional

### Sprint 4 (Dias 10-12): Finalização + Deploy 🚀
**Objetivo: Aplicação pronta para produção**

#### Dia 10: Shopee API (Básico)
```ruby
# Service que vou criar:
# - Shopee::ApiClient (básico)
```

**Entregas do Dia 10:**
- ✅ Shopee OAuth configurado
- ✅ Busca básica de produtos
- ✅ Geração de links de afiliação

#### Dia 11: Performance + Segurança
**Entregas do Dia 11:**
- ✅ Database indexes adicionados
- ✅ N+1 queries eliminadas
- ✅ Rate limiting básico
- ✅ Security headers configurados

#### Dia 12: Deploy + Produção
**Entregas do Dia 12:**
- ✅ Deploy na Heroku/Railway
- ✅ Database de produção
- ✅ Stripe em modo live
- ✅ Domain configurado
- ✅ SSL funcionando

### Metodologia de Trabalho

#### Como Vou Desenvolver:
1. **TDD Simples**: Testo as funcionalidades principais manualmente
2. **Git Flow Básico**: Feature branches + main
3. **Deploy Contínuo**: Deploy automático a cada merge
4. **Feedback Rápido**: Você testa a cada sprint

#### Estrutura de Commits:
```bash
# Padrão que vou seguir:
git commit -m "feat: add user authentication with devise"
git commit -m "fix: resolve stripe webhook validation"
git commit -m "refactor: simplify commission calculation logic"
```

#### Stack de Deploy:
- **Hosting**: Railway ou Heroku (simples e rápido)
- **Database**: PostgreSQL (managed)
- **Redis**: Para Sidekiq (managed)
- **Domain**: Cloudflare (DNS + CDN)

### O Que Você Precisa Fornecer:
1. **Stripe Keys** (test + live)
2. **Domain desejado** 
3. **Shopee API credentials** (quando tiver)
4. **Feedback** a cada sprint

### Cronograma Total: 12 dias úteis (3 semanas)
- **Semana 1**: Sprints 1-2 (Base + Assinaturas)
- **Semana 2**: Sprint 3 (Dashboard + Comissões)  
- **Semana 3**: Sprint 4 (API + Deploy)

**Resultado Final**: Aplicação completa, funcional e no ar! 🎯

**🚀 PRONTO PARA COMEÇAR? Qual sprint iniciamos agora?**

---

## � Integração com Stripe

### Service `StripeService`
```ruby
# Métodos principais:
- create_customer(user) # Criar cliente no Stripe
- create_subscription(user, plan) # Criar assinatura
- cancel_subscription(subscription_id) # Cancelar assinatura
- update_subscription(subscription_id, new_plan) # Alterar plano
- handle_webhook(event) # Processar webhooks
- get_payment_methods(customer_id) # Métodos de pagamento
- create_checkout_session(user, plan) # Sessão de checkout
```

### Webhooks Stripe
```ruby
# Eventos principais a serem tratados:
- customer.subscription.created # Assinatura criada
- customer.subscription.updated # Assinatura atualizada
- customer.subscription.deleted # Assinatura cancelada
- invoice.payment_succeeded # Pagamento bem-sucedido
- invoice.payment_failed # Falha no pagamento
- customer.subscription.trial_will_end # Trial acabando
```

### Configuração Stripe
```ruby
# config/stripe.rb (initializer)
require 'dotenv/load'

Stripe.api_key = ENV['STRIPE_SECRET_KEY']

Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY'],
  webhook_secret: ENV['STRIPE_WEBHOOK_SECRET']
}
```

---

## �🔗 Integração com Shopee Open Platform

### API Endpoints Utilizados
1. **Product Search API** - Buscar produtos e comissões
2. **Order API** - Dados de pedidos em tempo real
3. **Commission API** - Comissões e performance
4. **Product Link API** - Gerar links de afiliação

### Service `ShopeeApiService`
```ruby
# Métodos principais:
- authenticate # Autenticação OAuth
- get_products(category, keywords) # Buscar produtos
- get_commissions(date_range) # Buscar comissões
- create_affiliate_link(product_id) # Criar link de afiliação
- get_product_details(product_id) # Detalhes do produto
```

### Configuração
```ruby
# config/shopee.rb (initializer)
require 'dotenv/load'

Rails.configuration.shopee = {
  app_id: ENV['SHOPEE_APP_ID'],
  app_secret: ENV['SHOPEE_APP_SECRET'],
  redirect_uri: ENV['SHOPEE_REDIRECT_URI'],
  base_url: ENV['SHOPEE_BASE_URL'] || 'https://partner.shopeemobile.com'
}
```

---

## 📱 Interface do Usuário

### Layout Principal
- **Header**: Logo, menu principal, notificações, perfil
- **Sidebar**: Dashboard, Links, Análise, Produtos, Configurações
- **Main**: Conteúdo dinâmico
- **Footer**: Links úteis, versão

### Páginas Principais

#### 1. Landing Page (`/`)
- Hero section com proposta de valor
- Demonstração em vídeo (3 minutos)
- Seção de recursos e benefícios
- Depoimentos de usuários
- Seção de planos e preços
- CTA para teste grátis

#### 2. Autenticação
- **Cadastro** (`/auth/sign_up`): Formulário com nome, email, senha, telefone
- **Login** (`/auth/sign_in`): Email/senha + "Lembrar dispositivo"
- **Escolha de Plano** (`/plans`): 3 opções + trial de 14 dias
- **Checkout** (`/checkout`): Integração com Stripe
- **Confirmação** (`/welcome`): Onboarding pós-cadastro

#### 3. Dashboard (`/dashboard`)
```
┌─────────────────────────────────────────────────┐
│ Upload de Relatório CSV                         │
│ [Drag & Drop Area] [Selecionar Arquivo]        │
└─────────────────────────────────────────────────┘

┌─────────┬─────────┬─────────┬─────────┐
│ Total   │ Shopee  │ Extras  │ Vendas  │
│ R$742,60│ R$654,99│ R$75,28 │   294   │
└─────────┴─────────┴─────────┴─────────┘

┌─────────┬─────────┬─────────┬─────────┐
│ Invest. │ Margem  │   ROI   │   CPA   │
│ R$0,00  │ R$742,60│  0,0%   │ R$0,00  │
└─────────┴─────────┴─────────┴─────────┘

┌─────────────────────────────────────────────────┐
│ Pedidos & Comissões por Canal [Chart]          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ Análise por SubID [Tabela]                      │
└─────────────────────────────────────────────────┘
```

#### 4. Gestão de Links (`/links`)
- Lista de todos os links criados
- Estatísticas de cliques
- Formulário de criação/edição
- Bulk actions (ativar/desativar)
- **Limitação por plano** (15/50/ilimitado)

#### 5. Análise de Produtos (`/products`)
- Top produtos por comissão
- Análise de categoria
- Histórico de performance
- Sugestões de produtos

#### 6. Campanhas (`/campaigns`)
- Criação de campanhas
- Agrupamento de links
- Tracking de ROI
- Comparativo de performance

#### 7. Configurações (`/settings`)
- **Perfil**: Dados pessoais, senha
- **Assinatura**: Plano atual, alterar plano, histórico de pagamentos
- **Dispositivos**: Lista de devices, remover acesso
- **Notificações**: Preferências de email/SMS
- **API**: Tokens de acesso (planos Pro/Elite)

---

## 🛠️ Desenvolvimento - Fases

### Fase 1: Estrutura Base + Auth (Semana 1-2)
1. **Setup do Projeto**
   ```bash
   rails new link_flow --database=postgresql --css=tailwind
   cd link_flow
   bundle add devise stripe-rails dotenv-rails
   bundle install
   rails generate devise:install
   rails generate devise User
   rails generate model Subscription user:references plan:references
   rails generate model Plan name:string price_cents:integer
   rails generate model Device user:references device_id:string
   ```

2. **Configurações Iniciais**
   - Configurar PostgreSQL via dotenv
   - Setup do Tailwind CSS + componentes
   - Configurar Devise com customizações
   - Configurar Stripe + webhooks via dotenv
   - Configurar Active Storage
   - Criar seeds dos planos
   - Setup dotenv para todos os ambientes

3. **Sistema de Autenticação**
   - Views customizadas do Devise
   - Device tracking service
   - Middleware de verificação de device
   - Emails transacionais
   - Onboarding flow

### Fase 2: Assinaturas + Landing Page (Semana 3-4)
1. **Sistema de Assinaturas**
   - Integração completa com Stripe
   - Checkout flow
   - Webhooks handler
   - Gestão de planos
   - Trial period (14 dias)

2. **Landing Page**
   - Design responsivo inspirado no site original
   - Seção de preços dinâmica
   - Formulários de cadastro/login
   - SEO otimizado
   - Analytics tracking

3. **Dashboard Básico**
   - Layout principal com sidebar
   - Upload area inicial
   - Cards de KPIs básicos
   - Sistema de notificações

### Fase 3: Links + Dashboard Completo (Semana 5-6)
1. **Sistema de Redirecionamento**
   - CRUD de links com limitações por plano
   - Geração de códigos únicos
   - Tracking de cliques
   - Performance dashboard
   - Bulk operations

2. **Processamento de CSV**
   - Service de processamento com validações
   - Background jobs (Sidekiq)
   - Progress tracking
   - Relatórios de importação
   - Tratamento de erros

3. **Gráficos e Visualizações**
   - Integração Chart.js
   - Gráficos dinâmicos
   - Tabelas com ordenação/filtros
   - Export de dados
   - Responsividade mobile

### Fase 4: Integração Shopee + Avançado (Semana 7-8)
1. **API Shopee**
   - OAuth flow completo
   - Sync automático de dados
   - Rate limiting e cache
   - Error handling robusto
   - Notificações de sync

2. **Funcionalidades Premium**
   - Análise avançada de produtos
   - Sugestões de IA
   - API própria (Pro/Elite)
   - Exportação PDF
   - Webhooks para terceiros

3. **Otimizações Finais**
   - Performance tuning
   - Security audit
   - Testes automatizados
   - Monitoring setup
   - Deploy production

---

## 🎯 Limitações e Funcionalidades por Plano

### Controle de Acesso
```ruby
# Implementação de limitações
class LinkPolicy < ApplicationPolicy
  def create?
    return false unless user.active_subscription?
    
    case user.current_plan.name
    when "Afiliado Starter"
      user.links.count < 15
    when "Afiliado Pro"
      user.links.count < 50
    when "Afiliado Elite"
      true # Ilimitado
    else
      false
    end
  end
  
  def advanced_analytics?
    ["Afiliado Pro", "Afiliado Elite"].include?(user.current_plan.name)
  end
  
  def api_access?
    ["Afiliado Pro", "Afiliado Elite"].include?(user.current_plan.name)
  end
  
  def strategic_support?
    user.current_plan.name == "Afiliado Elite"
  end
end
```

### Funcionalidades por Plano

#### 🥉 Afiliado Starter (R$ 59,90/mês)
- ✅ 15 links de redirecionamento
- ✅ Upload e análise de CSV da Shopee
- ✅ Dashboard básico com KPIs essenciais
- ✅ Estatísticas básicas de cliques
- ✅ Suporte via WhatsApp
- ❌ Gráficos avançados
- ❌ API access
- ❌ Bulk operations
- ❌ Exportação PDF

#### 🥈 Afiliado Pro (R$ 97,90/mês) - **Mais Popular**
- ✅ 50 links de redirecionamento
- ✅ Todas as funcionalidades do Starter
- ✅ Estatísticas avançadas (segmentação por canal, período)
- ✅ Gráficos interativos (Chart.js)
- ✅ Análise comparativa de campanhas
- ✅ Exportação de relatórios (PDF/Excel)
- ✅ API access para integrações
- ✅ Bulk operations (criar/editar links em massa)
- ✅ Alertas automáticos (email/SMS)
- ❌ Suporte estratégico

#### 🥇 Afiliado Elite (R$ 147,90/mês)
- ✅ Links ilimitados
- ✅ Todas as funcionalidades do Pro
- ✅ Suporte estratégico personalizado
- ✅ Análise preditiva com IA
- ✅ Webhooks customizados
- ✅ White-label options
- ✅ Priority support (resposta em 2h)
- ✅ Consultoria mensal (1h)
- ✅ Beta access para novas features

### Trial Period (14 dias)
- Acesso completo ao plano Pro
- Não solicita cartão de crédito
- Ao final, usuário escolhe plano ou downgrade para free tier limitado
- Email sequence de onboarding e retenção

---

## 🔧 Configurações Técnicas

### Database Schema
```sql
-- Users Table (Devise + customizações)
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  encrypted_password VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  current_subscription_id BIGINT,
  trial_ends_at TIMESTAMP,
  email_verified_at TIMESTAMP,
  reset_password_token VARCHAR(255),
  reset_password_sent_at TIMESTAMP,
  remember_created_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Plans Table
CREATE TABLE plans (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price_cents INTEGER NOT NULL,
  currency VARCHAR(3) DEFAULT 'BRL',
  stripe_price_id VARCHAR(255),
  max_links INTEGER,
  features JSONB,
  popular BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Subscriptions Table
CREATE TABLE subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  plan_id BIGINT REFERENCES plans(id),
  stripe_subscription_id VARCHAR(255),
  stripe_customer_id VARCHAR(255),
  status VARCHAR(50),
  current_period_start TIMESTAMP,
  current_period_end TIMESTAMP,
  trial_ends_at TIMESTAMP,
  canceled_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Devices Table
CREATE TABLE devices (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  device_id VARCHAR(255) UNIQUE NOT NULL,
  device_type VARCHAR(50),
  browser VARCHAR(100),
  os VARCHAR(100),
  ip_address INET,
  user_agent TEXT,
  last_seen_at TIMESTAMP,
  trusted BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Links Table
CREATE TABLE links (
  id BIGSERIAL PRIMARY KEY,
  short_code VARCHAR(10) UNIQUE NOT NULL,
  original_url TEXT NOT NULL,
  title VARCHAR(255),
  description TEXT,
  clicks_count INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  user_id BIGINT REFERENCES users(id),
  campaign_id BIGINT REFERENCES campaigns(id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Commissions Table
CREATE TABLE commissions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  order_id VARCHAR(100) NOT NULL,
  sub_id VARCHAR(100),
  channel VARCHAR(100),
  commission_amount DECIMAL(10,2),
  sale_amount DECIMAL(10,2),
  order_status VARCHAR(50),
  commission_type VARCHAR(50),
  product_name VARCHAR(500),
  category VARCHAR(100),
  order_date TIMESTAMP,
  commission_date TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(user_id, order_id)
);

-- Clicks Table
CREATE TABLE clicks (
  id BIGSERIAL PRIMARY KEY,
  link_id BIGINT REFERENCES links(id),
  ip_address INET,
  user_agent TEXT,
  referer TEXT,
  country VARCHAR(2),
  city VARCHAR(100),
  clicked_at TIMESTAMP NOT NULL
);

-- Campaigns Table
CREATE TABLE campaigns (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  investment_amount DECIMAL(10,2) DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Environment Variables

#### Estrutura de Arquivos .env
```bash
# Estrutura recomendada
.env                    # Arquivo base (não commitado)
.env.example           # Template para outros devs (commitado)
.env.development       # Específico para desenvolvimento
.env.test              # Específico para testes
.env.production        # Específico para produção (não commitado)
```

#### .env.example (Template)
```bash
# ======================
# DATABASE CONFIGURATION
# ======================
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=link_flow_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/link_flow_development

# Test Database
TEST_DATABASE_NAME=link_flow_test
TEST_DATABASE_URL=postgresql://postgres:your_password@localhost:5432/link_flow_test

# ======================
# STRIPE CONFIGURATION
# ======================
# Development/Test Keys
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Production Keys (usar apenas em produção)
# STRIPE_PUBLISHABLE_KEY=pk_live_...
# STRIPE_SECRET_KEY=sk_live_...
# STRIPE_WEBHOOK_SECRET=whsec_...

# ======================
# SHOPEE API
# ======================
SHOPEE_APP_ID=your_app_id
SHOPEE_APP_SECRET=your_app_secret
SHOPEE_REDIRECT_URI=https://dev.unitymob.com.br/auth/shopee/callback
SHOPEE_BASE_URL=https://partner.test-stable.shopeemobile.com

# ======================
# REDIS CONFIGURATION
# ======================
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# ======================
# EMAIL CONFIGURATION
# ======================
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=your_smtp_user
SMTP_PASSWORD=your_smtp_password
FROM_EMAIL=noreply@unitymob.com.br
SUPPORT_EMAIL=support@unitymob.com.br

# ======================
# STORAGE (AWS S3)
# ======================
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=link-flow-development
AWS_BUCKET_UPLOADS=link-flow-uploads-development

# ======================
# SECURITY
# ======================
SECRET_KEY_BASE=your_long_secret_key_base_here
DEVISE_SECRET_KEY=your_devise_secret_key_here

# ======================
# APPLICATION SETTINGS
# ======================
APP_DOMAIN=dev.unitymob.com.br
APP_URL=https://dev.unitymob.com.br
RAILS_ENV=development
RACK_ENV=development

# ======================
# MONITORING & LOGGING
# ======================
SENTRY_DSN=your_sentry_dsn_here
NEW_RELIC_LICENSE_KEY=your_new_relic_key

# ======================
# EXTERNAL APIs
# ======================
GOOGLE_ANALYTICS_ID=GA-XXXXXXXXX
FACEBOOK_PIXEL_ID=your_pixel_id
```

#### .env.production (Exemplo)
```bash
# ======================
# DATABASE CONFIGURATION
# ======================
DATABASE_URL=postgresql://user:password@db-host:5432/link_flow_production

# ======================
# STRIPE CONFIGURATION
# ======================
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# ======================
# SHOPEE API
# ======================
SHOPEE_APP_ID=your_production_app_id
SHOPEE_APP_SECRET=your_production_app_secret
SHOPEE_REDIRECT_URI=https://app.unitymob.com.br/auth/shopee/callback
SHOPEE_BASE_URL=https://partner.shopeemobile.com

# ======================
# REDIS CONFIGURATION
# ======================
REDIS_URL=redis://redis-host:6379/0

# ======================
# EMAIL CONFIGURATION
# ======================
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=your_production_smtp_user
SMTP_PASSWORD=your_production_smtp_password
FROM_EMAIL=noreply@unitymob.com.br
SUPPORT_EMAIL=support@unitymob.com.br

# ======================
# STORAGE (AWS S3)
# ======================
AWS_ACCESS_KEY_ID=your_production_access_key
AWS_SECRET_ACCESS_KEY=your_production_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=link-flow-production
AWS_BUCKET_UPLOADS=link-flow-uploads-production

# ======================
# SECURITY
# ======================
SECRET_KEY_BASE=your_production_secret_key_base
DEVISE_SECRET_KEY=your_production_devise_secret

# ======================
# APPLICATION SETTINGS
# ======================
# APPLICATION SETTINGS
# ======================
APP_DOMAIN=app.unitymob.com.br
APP_URL=https://app.unitymob.com.br
RAILS_ENV=production
RACK_ENV=production

# ======================
# MONITORING & LOGGING
# ======================
SENTRY_DSN=your_production_sentry_dsn
NEW_RELIC_LICENSE_KEY=your_production_new_relic_key
```

#### Configuração do Database com Dotenv
```ruby
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  host: <%= ENV['DATABASE_HOST'] || 'localhost' %>
  port: <%= ENV['DATABASE_PORT'] || 5432 %>
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: <%= ENV['DATABASE_NAME'] || 'link_flow_development' %>
  url: <%= ENV['DATABASE_URL'] %>

test:
  <<: *default
  database: <%= ENV['TEST_DATABASE_NAME'] || 'link_flow_test' %>
  url: <%= ENV['TEST_DATABASE_URL'] %>

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 20 } %>
```

#### Setup do Dotenv
```ruby
# Gemfile
gem 'dotenv-rails', groups: [:development, :test]

# config/application.rb (adicionar no início)
require 'dotenv/load' if Rails.env.development? || Rails.env.test?

# .gitignore (adicionar)
.env
.env.local
.env.production
.env.*.local
```

#### Melhores Práticas com Dotenv

1. **Estrutura de Arquivos**
   ```bash
   # Sempre commitado - template para outros devs
   .env.example
   
   # Nunca commitado - valores reais
   .env
   .env.development
   .env.test
   .env.production
   ```

2. **Validação de Variáveis Obrigatórias**
   ```ruby
   # config/initializers/dotenv.rb
   required_vars = %w[
     DATABASE_URL
     SECRET_KEY_BASE
     STRIPE_SECRET_KEY
     SHOPEE_APP_ID
   ]
   
   required_vars.each do |var|
     raise "Missing required environment variable: #{var}" if ENV[var].blank?
   end
   ```

3. **Diferentes Ambientes**
   ```ruby
   # config/environments/development.rb
   Dotenv.load('.env.development', '.env')
   
   # config/environments/test.rb
   Dotenv.load('.env.test', '.env')
   
   # config/environments/production.rb
   # Usar apenas variáveis do sistema ou secrets manager
   ```

4. **Scripts de Setup**
   ```bash
   # bin/setup (adicionar)
   #!/usr/bin/env bash
   set -euo pipefail
   
   # Copiar template se não existir
   if [ ! -f .env ]; then
     cp .env.example .env
     echo "✅ Arquivo .env criado. Configure as variáveis necessárias."
   fi
   
   # Validar variáveis obrigatórias
   bundle exec rails runner "Rails.application.load_tasks; Rake::Task['dotenv:check'].invoke"
   ```

### Performance Considerations
- **Database**: Índices em campos de busca frequente
- **Cache**: Redis para cache de queries pesadas
- **CDN**: CloudFront para assets estáticos
- **Background Jobs**: Sidekiq para processamento assíncrono
- **Monitoring**: Sentry para error tracking

---

## 📋 Checklist de Implementação

### Backend
- [ ] Models (User, Subscription, Plan, Device, Link, Commission, Click, Campaign)
- [ ] Controllers com actions RESTful
- [ ] Services (StripeService, ShopeeAPI, CommissionProcessor, DeviceTracker)
- [ ] Background Jobs (CSV processing, API sync, email notifications)
- [ ] Devise customização (views, controllers, mailers)
- [ ] Validations e error handling
- [ ] Authorization (Pundit ou CanCanCan)
- [ ] Tests (RSpec + Factory Bot)

### Frontend
- [ ] Landing page responsiva (Tailwind)
- [ ] Sistema de autenticação (cadastro, login, recuperação)
- [ ] Checkout flow (Stripe Elements)
- [ ] Dashboard com upload component (drag & drop)
- [ ] Charts interativos (Chart.js)
- [ ] Tables dinâmicas com filtros
- [ ] Forms com validação client-side
- [ ] Feedback visual (loading, success, error, progress)
- [ ] PWA features (service worker, offline)

### Pagamentos & Assinaturas
- [ ] Stripe integration completa
- [ ] Webhooks handler seguro
- [ ] Trial period automático (14 dias)
- [ ] Upgrade/downgrade de planos
- [ ] Cancelamento de assinatura
- [ ] Recuperação de pagamentos falidos
- [ ] Invoices e receipts por email

### Segurança & Device Tracking
- [ ] Device fingerprinting
- [ ] Login multi-device
- [ ] Detecção de devices suspeitos
- [ ] 2FA opcional (SMS/Email)
- [ ] Rate limiting
- [ ] CSRF protection
- [ ] SQL injection protection

### Integração
- [ ] Shopee OAuth flow completo
- [ ] API endpoints wrappers
- [ ] Sync automático de dados
- [ ] Webhooks (se disponível)
- [ ] Error handling e retries
- [ ] Cache estratégico (Redis)

### Deploy & DevOps
- [ ] Docker setup (multi-stage)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Dotenv configuration para todos os ambientes
- [ ] Environment configs (.env.example, .env.production)
- [ ] Database migrations automáticas
- [ ] SSL/TLS certificado
- [ ] CDN setup (CloudFront)
- [ ] Monitoring (Sentry, New Relic)
- [ ] Backup automático do DB
- [ ] Log management (Papertrail)
- [ ] Secrets management (AWS Secrets Manager ou similar)

---

## 🚦 Como Usar Este Documento

Este documento serve como **fonte única da verdade** para o desenvolvimento do Link Flow. 

### Para Desenvolvedores
1. Consulte sempre este documento antes de implementar novas features
2. Atualize as instruções quando houver mudanças na arquitetura
3. Use os exemplos de código como referência
4. Siga a estrutura de fases para desenvolvimento

### Para IAs/Agentes
1. Use este documento como contexto principal
2. Mantenha consistência com a arquitetura definida
3. Implemente features seguindo os padrões estabelecidos
4. Consulte a seção específica antes de fazer alterações

### Atualizações
- **Versão**: 2.0
- **Última atualização**: 5 de setembro de 2025
- **Principais mudanças**:
  - ✅ Sistema de analytics unificado (CSV + API) implementado
  - ✅ Analytics de cliques do website implementado
  - ✅ Integração completa com Shopee API implementada
  - ✅ Painel administrativo completo implementado
  - ✅ Sistema de configurações globais implementado
  - ✅ Controle de gastos por SubID implementado
  - ✅ Export de relatórios em PDF implementado
  - ✅ Gráficos avançados e interativos implementados
  - ✅ Múltiplos tipos de CSV suportados
  - ✅ Sistema de logs de API implementado
  - ✅ Configuração centralizada da Shopee implementada
- **Próxima revisão**: Após implementação de novas features

---

---

## 🆕 Funcionalidades Avançadas Implementadas

### 1. Sistema de Analytics Dual (CSV + API)
**Status**: ✅ Implementado e Funcional

O sistema possui uma arquitetura híbrida que combina dados de duas fontes:

**Fonte 1: Upload de CSV**
- Dados históricos de comissões da Shopee
- Dados de cliques do website
- Processamento manual com validação automática

**Fonte 2: API da Shopee**
- Sincronização automática de conversões
- Dados em tempo real
- Fallback para configuração centralizada

**Unificação de Dados**
```ruby
# Método unificado no User model
def all_commissions_unified
  # Combina dados de Commission (CSV) e AffiliateConversion (API)
  # Normaliza campos para análise unificada
end
```

### 2. Dashboard de Analytics Avançado
**Status**: ✅ Implementado - 739 linhas de código

**Funcionalidades Principais:**
- KPIs unificados (CSV + API)
- Análise de comissões diretas vs indiretas
- Performance por canal, categoria e SubID
- Gráficos interativos com Chart.js
- Controle de períodos automático
- Export PDF para planos Pro+

**Métricas Calculadas:**
- Total de comissões (soma de ambas as fontes)
- Taxa de conversão
- Ticket médio
- ROI por SubID (com controle de gastos)
- Performance temporal (diária/mensal)

### 3. Analytics de Cliques do Website
**Status**: ✅ Implementado - 157 linhas de código

**Funcionalidades:**
- Análise de tráfego por referenciador
- Mapeamento geográfico de cliques
- Análise temporal (hora do dia, padrões)
- Identificação de picos de tráfego
- Correlação SubID x Cliques

**Insights Gerados:**
- Melhor horário para postagens
- Principais fontes de tráfego
- Regiões com maior engajamento
- Eficácia de campanhas por SubID

### 4. Integração Completa com Shopee API
**Status**: ✅ Implementado - Arquitetura Robusta

**Componentes Implementados:**
- `ShopeeAffiliateIntegration` - Configuração por usuário
- `ShopeeMasterConfig` - Configuração centralizada
- `ShopeeAffiliate::AuthService` - Autenticação OAuth
- `ShopeeAffiliate::SyncService` - Sincronização automática
- `ShopeeAffiliate::Client` - Cliente HTTP personalizado
- `ShopeeApiRequest` - Log de todas as requisições

**Fluxo de Integração:**
1. Configuração de credenciais (individual ou centralizada)
2. Teste de conexão automático
3. Sincronização incremental de conversões
4. Parse e normalização de dados
5. Unificação com dados de CSV

### 5. Sistema Administrativo Completo
**Status**: ✅ Implementado - Painel Admin Robusto

**Funcionalidades Admin:**
- Dashboard com métricas globais
- Gestão completa de usuários
- Controle de planos e sincronização Stripe
- Configurações globais do sistema
- Monitoramento de integrações Shopee
- Logs de API e debugging

**Configurações Globais:**
- Sistema de `Setting` key-value
- Reset para configurações padrão
- Tipos de dados tipados (string, boolean, json)
- Interface administrativa amigável

### 6. Controle Granular de Gastos
**Status**: ✅ Implementado - ROI Preciso

**Funcionalidades:**
- Cadastro de gastos por SubID
- Períodos de investimento configuráveis
- Cálculo automático de ROI
- Análise de margem de lucro
- Comparativo de campanhas

**Cálculos Avançados:**
```ruby
# ROI por SubID
roi = ((comissões - gastos) / gastos) * 100

# Margem de lucro
margem = comissões - gastos

# CPA (Custo por Aquisição)
cpa = gastos / número_de_pedidos
```

### 7. Export Avançado de Relatórios
**Status**: ✅ Implementado - PDF Profissional

**Conteúdo dos Relatórios:**
- Resumo executivo com KPIs principais
- Gráficos exportados como imagens
- Tabelas detalhadas por período
- Análise de tendências
- Recomendações baseadas em dados

**Configurações do PDF:**
- Layout profissional
- Branding personalizado
- Múltiplos formatos de data
- Filtros por período/canal

### 8. Sistema de Logs e Debugging
**Status**: ✅ Implementado - Monitoramento Completo

**Logs Implementados:**
- Todas as requisições à API Shopee
- Tempos de resposta e status codes
- Erros de integração com contexto
- Histórico de sincronizações
- Upload e processamento de CSVs

**Debugging Features:**
- Interface admin para visualizar logs
- Teste de conexão com feedback detalhado
- Retry automático para falhas temporárias
- Alertas para problemas persistentes

### 9. Arquitetura Flexível de Dados
**Status**: ✅ Implementado - Design Escalável

**Flexibilidade Implementada:**
- Suporte a múltiplos mercados Shopee
- Configuração por usuário ou centralizada
- Normalização automática de dados
- Campos extensíveis (JSON para dados brutos)
- Índices otimizados para performance

**Escalabilidade:**
- Background jobs para processamento pesado
- Paginação em listagens
- Cache estratégico
- Queries otimizadas

### 10. Interface Responsiva e Moderna
**Status**: ✅ Implementado - UX Otimizada

**Funcionalidades de Interface:**
- Design mobile-first
- Gráficos responsivos
- Upload drag-and-drop
- Feedback visual para ações
- Loading states
- Error handling amigável

**Tecnologias Utilizadas:**
- Tailwind CSS para estilização
- Chart.js para gráficos
- JavaScript vanilla para interações
- Turbo para navegação rápida

---

## � EXECUÇÃO DO PROJETO

### Desenvolvimento Local
```bash
# 1. Instalar dependências
bundle install

# 2. Configurar banco de dados
rails db:create db:migrate db:seed

# 3. Verificar variáveis de ambiente
# Arquivo .env deve estar configurado (ver seção ⚙️ CONFIGURAÇÃO)

# 4. Executar servidor
bundle exec rails server -p 3000

# 5. Acessar aplicação
# http://localhost:3000 (local)
# https://dev.appdoafiliado.com.br (com túnel SSH)
```

### Deployment para Produção

#### 🚀 Processo de Deploy via Mina
```bash
# 1. Fazer commit das alterações
git add .
git commit -m "Descrição das alterações"
git push origin master

# 2. Deploy via Mina (configurado)
mina deploy

# 3. Gerenciar serviços Puma
mina full_stop        # Para completamente a aplicação
mina start           # Inicia o Puma
mina restart         # Reinicia o Puma
mina restart_stack   # Reinicia Puma + Nginx
mina status          # Verifica status
mina logs            # Visualiza logs
mina puma_logs       # Logs específicos do Puma
mina system_status   # Status completo do sistema

# Versões recentes no servidor:
# v13-v21: Evoluções do sistema de pagamentos
# v22: Versão atual com correções analytics e sistema de permissões
```

#### ⚙️ Configuração Puma (Produção)
**IMPORTANTE**: O projeto já está configurado com `puma/daemon` para produção

```ruby
# config/puma.rb - Configuração atual
require 'puma/daemon' if ENV.fetch("RAILS_ENV") { "development" } == "production"

# Em produção:
- Workers: 3 (configurável via WEB_CONCURRENCY)
- Bind: tcp://127.0.0.1:9292
- Daemon: true (roda em background)
- PID file: tmp/pids/appdoafiliado.com.br.pid
- State file: tmp/pids/appdoafiliado.com.br.state
```

#### 🌐 URLs do Sistema
- **Produção**: https://app.appdoafiliado.com.br
- **Site**: https://appdoafiliado.com.br
- **Servidor**: 167.99.5.194 (usuário: appdoafiliado.com.br)

#### 🔧 Comandos SSH Diretos (se necessário)
```bash
# Conectar via SSH
ssh appdoafiliado.com.br@167.99.5.194

# Navegar para aplicação
cd /home/appdoafiliado.com.br/deploy/current

# Verificar processos Puma
ps aux | grep puma

# Iniciar Puma manualmente (se necessário)
source ~/.rvm/scripts/rvm
rvm use ruby-3.3.5@app.appdoafiliado
bundle exec puma -C config/puma.rb
```

### Troubleshooting Comum
```bash
# Verificar configuração Stripe
rails runner "puts Rails.configuration.stripe[:publishable_key]"

# Reiniciar após mudanças no .env
bundle exec rails server -p 3000

# Verificar status do banco
rails db:migrate:status

# Limpar cache se necessário
rails tmp:clear
```

### Logs Importantes
- **Payment Errors**: Verificar logs do controller para status 422
- **Stripe Integration**: Logs do StripeService mostram tokens e erros
- **Database**: Verificar migrações e seeds executados

---

## �🔮 Próximas Funcionalidades Planejadas

### Roadmap de Desenvolvimento

#### Sprint Próximo (Setembro 2025)
**🎯 Foco: Otimização e Melhorias**

1. **Otimização de Performance**
   - Cache Redis para queries pesadas
   - Indices adicionais no banco
   - Lazy loading para gráficos
   - Paginação melhorada

2. **Melhorias na API Shopee**
   - Retry automático com backoff
   - Rate limiting inteligente
   - Webhook support (se disponível)
   - Múltiplos mercados simultâneos

3. **Analytics Preditivos**
   - Previsão de tendências
   - Alertas automáticos
   - Detecção de anomalias
   - Sugestões de otimização

#### Trimestre Q4 2025
**🎯 Foco: Funcionalidades Premium**

1. **API Própria para Integração**
   - REST API documentada
   - Authentication via API keys
   - Webhooks para terceiros
   - SDK em JavaScript/Python

2. **Automação Avançada**
   - Sync automático agendado
   - Alertas por email/SMS
   - Relatórios automáticos
   - Backup automático de dados

3. **White-label Solutions**
   - Customização de branding
   - Domínio personalizado
   - Interface customizável
   - Multi-tenancy

#### Q1 2026
**🎯 Foco: Inteligência Artificial**

1. **IA para Otimização**
   - Sugestões de produtos
   - Otimização de campanhas
   - Análise preditiva de ROI
   - Chatbot para suporte

2. **Integrações Adicionais**
   - Amazon Associates
   - AliExpress
   - Mercado Livre
   - Hotmart/Monetizze

3. **Mobile App**
   - App nativo iOS/Android
   - Notificações push
   - Dashboard mobile
   - Quick actions

### Melhorias Técnicas Planejadas

#### Segurança
- [ ] 2FA obrigatório para admins
- [ ] Audit logs completos
- [ ] Rate limiting por IP
- [ ] Encryption at rest

#### Performance
- [ ] Database sharding
- [ ] CDN para assets
- [ ] Background job optimization
- [ ] Query optimization

#### Monitoramento
- [ ] APM completo (New Relic/DataDog)
- [ ] Health checks avançados
- [ ] Alertas de performance
- [ ] Dashboard de métricas técnicas

#### Testes
- [ ] Cobertura de testes 90%+
- [ ] Testes de integração
- [ ] Testes de carga
- [ ] Testes de segurança

---

## 📚 Recursos Adicionais

### Documentação de Referência
- [Rails 7.2 Guides](https://guides.rubyonrails.org/)
- [Shopee Open Platform](https://open.shopee.com/developer-guide/4)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Chart.js](https://www.chartjs.org/docs/)

### Inspirações de UI
- [Dashboard original](https://afiliadoredirect.com.br/)
- Design system consistente
- UX patterns para dashboards

Este documento será atualizado conforme o projeto evolui. Mantenha-o sempre como referência principal! 🎯
