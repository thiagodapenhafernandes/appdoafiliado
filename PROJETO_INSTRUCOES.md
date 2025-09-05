# 🚀 Link Flow - Sistema de Afiliação e Análise de Comissões

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

## 📊 Funcionalidades Core

### 1. Sistema de Autenticação e Assinaturas

#### Modelo `User`
```ruby
# Campos essenciais (Devise + mínimas customizações)
- email (string, unique, index) # Email do usuário
- encrypted_password (string) # Senha criptografada
- first_name (string) # Nome
- last_name (string) # Sobrenome
- subscription_id (references, index) # Assinatura ativa
- trial_ends_at (datetime) # Fim do período trial
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

### 2. Sistema de Redirecionamento de Links

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

#### KPIs Essenciais (simplificados)
1. **Total de Comissões** - Commission.total_commissions
2. **Total de Vendas** - Commission.total_sales  
3. **Número de Pedidos** - Commission.count
4. **Ticket Médio** - total_sales / count

### 3. Upload e Processamento de CSV

#### Service `Commissions::CsvProcessor`
```ruby
# Classe focada em uma responsabilidade
class Commissions::CsvProcessor
  def initialize(user, file)
    @user = user
    @file = file
  end

  def process
    validate_file!
    import_commissions
    calculate_totals
  end

  private

  def validate_file!
    # Validações simples e diretas
  end

  def import_commissions
    # Import em batches para performance
  end

  def calculate_totals
    # Cálculo dos totais após import
  end
end
```

#### Validações Simples do CSV
- Headers obrigatórios: order_id, commission_amount, sale_amount, channel
- Formato UTF-8
- Máximo 5.000 registros por arquivo
- Duplicatas ignoradas automaticamente

#### Estrutura Esperada do CSV Shopee
```csv
order_id,sub_id,channel,commission_amount,sale_amount,order_status,commission_type,product_name,category,order_date,commission_date
202509041001,gerenciadorautoexcellante,instagram,2.89,28.90,completed,direct,Produto Exemplo,electronics,2025-09-04 10:30:00,2025-09-04 12:00:00
202509041002,estantenovovidovi,facebook,3.45,34.50,completed,indirect,Outro Produto,fashion,2025-09-04 11:15:00,2025-09-04 13:30:00
```

### 4. Gráficos Simples e Funcionais

#### Chart.js - Configuração Mínima
1. **Comissões por Canal** (Bar Chart simples)
   - Eixo X: Canais
   - Eixo Y: Valor de comissões
   - 3-4 cores máximo

2. **Evolução Mensal** (Line Chart básico)  
   - Eixo X: Meses
   - Eixo Y: Total de comissões
   - Uma linha simples

#### Interface Minimalista
- Cards simples com números grandes
- Tabela básica com ordenação
- Gráficos clean sem excessos visuais

---

## 🚀 PLANO DE DESENVOLVIMENTO PRÁTICO

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
FROM_EMAIL=noreply@linkflow.com.br
SUPPORT_EMAIL=support@linkflow.com.br

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
SHOPEE_REDIRECT_URI=https://linkflow.com.br/auth/shopee/callback
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
FROM_EMAIL=noreply@linkflow.com.br
SUPPORT_EMAIL=support@linkflow.com.br

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
APP_DOMAIN=linkflow.com.br
APP_URL=https://linkflow.com.br
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
- **Versão**: 1.0
- **Última atualização**: 4 de setembro de 2025
- **Próxima revisão**: Após conclusão da Fase 1

---

## 📞 Recursos Adicionais

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
