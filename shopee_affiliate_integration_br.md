# 📘 Instruções para Implementar Integração Shopee Affiliate (Open API, Mercado BR)

## Contexto
- Esta integração é para o **programa de afiliados da Shopee (não sellers)**.  
- Endpoint oficial do Brasil (GraphQL):  
https://open-api.affiliate.shopee.com.br/graphql

markdown
Copiar código
- Cada afiliado recebe **AppID** e **Secret** no portal de afiliados (“Open API”).  
- O fluxo é **pull**: a aplicação deve consultar periodicamente relatórios de conversão/comissão por janelas de tempo.  
- A documentação é limitada, mas os provedores confirmam o uso de `AppID + Secret` + assinatura **SHA256**.  

---

## Decisões de Arquitetura
1. **Credenciais por tenant (Account)**  
 - Guardar `app_id`, `secret` (criptografado), `market = "BR"` e `endpoint`.  

2. **Cliente GraphQL**  
 - Construir uma camada de cliente em Ruby/Faraday.  
 - Implementar assinatura padrão:  
   - `signature = SHA256(appid + timestamp + payload + secret)`  
 - Permitir fallback para `HMAC-SHA256` caso necessário.  
 - Headers típicos:  
   ```
   X-APP-ID, X-TIMESTAMP, X-SIGNATURE, Content-Type: application/json
   ```

3. **Ingestão incremental**  
 - Consultar `conversions` por período (última sincronização até agora).  
 - Suportar paginação.  
 - Usar `external_id` como chave única para garantir idempotência.  

4. **Persistência em banco**  
 - Criar tabela `affiliate_conversions` com campos:  
   - `external_id`, `order_id`, `item_id`, `category`, `channel`, `sub_id`  
   - `commission_cents`, `currency`, `quantity`, `click_time`, `conversion_time`, `status`, `raw` (JSON).  
 - Índices em `external_id`, `sub_id`, `conversion_time`.  

5. **Jobs & Backfill**  
 - Usar **Sidekiq** para sincronização periódica.  
 - Criar Rake task `rake shopee_affiliate:backfill DAYS=30` para sincronização retroativa.  

6. **Fallback CSV**  
 - Manter upload manual de CSV caso o afiliado não tenha API habilitada no mercado BR.  
 - Normalizar no mesmo fluxo de `affiliate_conversions`.  

## 🔄 **Estratégia de Coexistência CSV + API**

### **Dados Unificados**
- **Tabela principal**: `commissions` (dados existentes + novos da API)
- **Campo `source`**: `'csv'` (dados manuais) ou `'shopee_api'` (automáticos)
- **Campo `external_id`**: identificador único da API (null para CSV)

### **Fluxo Híbrido**
1. **CSV Manual** (existente): continua funcionando normalmente
2. **API Automática** (nova): sincronização em background
3. **Dashboard Unificado**: mostra ambos os tipos com filtros
4. **Sem duplicação**: `external_id` garante unicidade dos dados da API

### **Migração Gradual**
- ✅ Usuários podem continuar usando CSV
- ✅ Usuários podem ativar API quando disponível  
- ✅ Transição suave sem quebrar funcionalidades existentes
- ✅ Relatórios mostram origem dos dados (CSV vs API)

---
1. Usuário fornece **AppID/Secret**.  
2. Serviço Rails monta a assinatura e faz requisições GraphQL.  
3. Conversões são puxadas (pull), paginadas e salvas em `affiliate_conversions`.  
4. Dashboards calculam KPIs (total de comissões, ROI, SubIDs, canais, categorias).  
5. Caso API não esteja disponível → usar fallback CSV.  

---

## Checklist de Implementação

### 🏗️ **FASE 1: Fundação (5-7 dias)** - ✅ CONCLUÍDA
- [x] Análise de viabilidade técnica concluída
- [x] Adicionar gems necessárias (faraday, attr_encrypted)
- [x] Criar migration `shopee_affiliate_integrations`
- [x] Criar migration `affiliate_conversions`
- [x] Adicionar campos external_id e source em commissions
- [x] Criar models base (ShopeeAffiliateIntegration, AffiliateConversion)
- [x] Implementar `ShopeeAffiliate::AuthService` (SHA256 signature)
- [x] Criar `ShopeeAffiliate::Client` (GraphQL client base)

### 🔌 **FASE 2: Cliente GraphQL (4-5 dias)** - ✅ CONCLUÍDA
- [x] Implementar `ShopeeAffiliate::AuthService` (SHA256 signature)
- [x] Criar `ShopeeAffiliate::Client` (GraphQL client)
- [x] Desenvolver `ShopeeAffiliate::ConversionParser`
- [x] Implementar `ShopeeAffiliate::SyncService`
- [x] Criar Jobs Sidekiq (SyncConversionsJob, BackfillJob, TestConnectionJob)
- [x] Implementar rake tasks para operações manuais
- [x] Integrar analytics controller com dados unificados

### 🔄 **FASE 3: Sincronização (3-4 dias)** - ✅ CONCLUÍDA
- [x] Criar `ShopeeAffiliate::SyncService`
- [x] Implementar `ShopeeAffiliate::SyncConversionsJob` (Sidekiq)
- [x] Desenvolver rake task de backfill
- [x] Implementar lógica incremental com paginação
- [x] Sistema de retry e error handling
- [x] Métricas unificadas (CSV + API) no dashboard

### 🎨 **FASE 4: Interface e Integração (3-4 dias)** - 🔄 EM ANDAMENTO
- [ ] Criar tela de configuração `/settings/shopee_integration`
- [ ] Implementar formulário de credenciais (app_id/secret)
- [x] Integrar dados API com dashboard existente
- [x] Criar filtros por source (CSV vs API)
- [x] Dashboards unificados
- [ ] Indicadores visuais de status da integração
- [ ] Botões de teste de conexão e sincronização manual

### 🧪 **FASE 5: Testes e Refinamentos (2-3 dias)**
- [ ] Testes unitários para todos os services
- [ ] Testes de integração com API mock
- [ ] Validação com dados reais do portal BR
- [ ] Documentação técnica completa
- [ ] Deploy e monitoramento

---

## 📊 **Status da Implementação**
- **Iniciado em**: 5 de setembro de 2025
- **Fase atual**: Interface e Integração (Dashboard + Settings)
- **Progresso**: 75% concluído
- **Próximo milestone**: Interface de configuração de credenciais
- **Estimativa conclusão**: 8-10 setembro de 2025

## 🚀 **Comandos Disponíveis (Rake Tasks)**
```bash
# Backfill de dados para um usuário específico
rake shopee_affiliate:backfill[USER_ID,DAYS]

# Sincronizar todos os usuários ativos
rake shopee_affiliate:sync_all[DAYS]

# Testar conexão de um usuário
rake shopee_affiliate:test_connection[USER_ID]

# Ver status de todas as integrações
rake shopee_affiliate:status

# Agendar jobs de sincronização (para cron)
rake shopee_affiliate:schedule_sync
``` 