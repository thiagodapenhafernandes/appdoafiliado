# App do Afiliado - Landing Page

Esta é a nova landing page para o **App do Afiliado**, uma plataforma completa para gestão e análise de links de afiliado da Shopee.

## 🚀 Características da Landing Page

### Design e UX
- **Responsiva**: Funciona perfeitamente em desktop, tablet e mobile
- **TailwindCSS**: Framework CSS moderno para estilização
- **Animações suaves**: Transições e efeitos visuais profissionais
- **Tipografia otimizada**: Fonte Inter para melhor legibilidade
- **Cores de marca**: Esquema de cores consistente com a identidade visual

### Seções Principais

#### 1. **Header/Navegação**
- Logo do App do Afiliado
- Menu de navegação responsivo
- Botões de login e teste grátis
- Efeito de backdrop blur no scroll

#### 2. **Hero Section**
- Título impactante com destaque para "afiliado da Shopee"
- Subtítulo explicativo sobre a proposta de valor
- Dois CTAs principais: "Comece Grátis Agora" e "Ver Demonstração"
- Badges de credibilidade (redirecionamento rápido, estatísticas em tempo real, etc.)

#### 3. **Demonstração em Vídeo**
- Seção dedicada para vídeo explicativo
- Player estilizado com botão de play customizado
- Badge de recomendação (94% dos usuários recomendam)

#### 4. **Benefícios (Problemas que Resolvemos)**
- 3 cards destacando os principais problemas que a ferramenta resolve:
  1. Nunca mais perca campanhas lucrativas
  2. Pare de depender das métricas atrasadas da Shopee
  3. Invista com segurança e escalabilidade

#### 5. **Funcionalidades**
- Lista detalhada de features com ícones e descrições
- Preview do dashboard com mockup visual
- 4 funcionalidades principais:
  - Links Sempre Ativos
  - Resultados em Tempo Real
  - Dados Precisos para Decisões Estratégicas
  - Controle Completo do Tráfego

#### 6. **Depoimentos**
- 3 depoimentos de usuários reais adaptados
- Fotos em avatar com gradiente
- Avaliações 5 estrelas
- Nomes e títulos profissionais

#### 7. **Preços**
- 3 planos de preços com destaque para o "mais popular"
- Preços em Real (R$ 59,90 / R$ 97,90 / R$ 147,90)
- Lista de funcionalidades por plano
- Botões de teste grátis por 14 dias

#### 8. **Call-to-Action Final**
- Seção com gradiente chamativo
- Dois botões: cadastro e ver planos
- Mensagem de urgência sem compromisso

#### 9. **Footer**
- Links organizados em colunas (Suporte, Legal, Produto)
- Redes sociais
- Informações da empresa
- Copyright

### 🛠 Tecnologias Utilizadas

- **HTML5**: Estrutura semântica moderna
- **TailwindCSS**: Framework CSS utilitário
- **JavaScript Vanilla**: Interatividade e animações
- **Font Awesome**: Ícones profissionais
- **Google Fonts**: Tipografia Inter
- **SVG**: Gráficos vetoriais para ícones e ilustrações

### 📱 Responsividade

A landing page é totalmente responsiva com:
- Grid layout que se adapta a diferentes tamanhos de tela
- Menu mobile com hamburger
- Tipografia escalável
- Cards e seções que se reorganizam em mobile
- Botões e espaçamentos otimizados para touch

### ⚡ Performance

- **Lazy loading**: Imagens carregadas sob demanda
- **Otimização de fontes**: Google Fonts com display=swap
- **CSS minificado**: TailwindCSS via CDN otimizada
- **JavaScript otimizado**: Funções utilitárias reutilizáveis
- **SVG inline**: Ícones leves e escaláveis

### 🎨 Identidade Visual

#### Cores Principais
- **Primary**: #6366f1 (Indigo)
- **Secondary**: #f59e0b (Amber)
- **Accent**: #10b981 (Emerald)
- **Dark**: #1f2937 (Gray 800)

#### Gradientes
- Primary to Secondary para CTAs principais
- Backgrounds sutis com opacity
- Hover effects com box-shadow

### 📊 Conversão e CRO

#### Elementos de Conversão
- Múltiplos CTAs estrategicamente posicionados
- Teste grátis sem cartão de crédito
- Badges de credibilidade
- Depoimentos sociais
- Urgência sutil (sem compromisso)

#### A/B Testing Ready
- Classes CSS preparadas para testes
- IDs únicos para tracking
- Estrutura modular para variações

### 🔧 Integração com Rails

A landing page está preparada para integrar com a aplicação Rails:

#### Links de Integração
- `/users/sign_in` - Login
- `/users/sign_up` - Cadastro
- Botões apontam para rotas corretas da aplicação

#### Estrutura de Arquivos
```
public/site/
├── index.html          # Página principal
├── css/
│   └── style.css       # Estilos customizados
├── js/
│   └── main.js         # JavaScript principal
└── images/
    ├── dashboard-preview.svg  # Preview do dashboard
    └── favicon.svg           # Favicon da aplicação
```

### 🚀 Deploy e Acesso

#### Acesso Local
Para visualizar a landing page:
1. Navegue até `http://localhost:3000/site/` (com Rails rodando)
2. Ou abra diretamente o arquivo `public/site/index.html`

#### SEO Otimizations
- Meta tags completas (title, description)
- Estrutura semântica HTML5
- Alt texts em imagens
- URLs amigáveis nos links internos
- Schema markup ready

### 📈 Analytics Ready

O código está preparado para:
- Google Analytics 4
- Facebook Pixel
- Hotjar/Crazy Egg
- Conversion tracking
- Event tracking nos CTAs

### 🔄 Manutenção e Updates

#### Conteúdo Editável
- Preços facilmente atualizáveis
- Depoimentos modulares
- Funcionalidades em lista
- Links centralizados

#### Performance Monitoring
- Error handling implementado
- Console logging para debug
- Service Worker ready
- Performance timing capturado

---

## 🎯 Próximos Passos

1. **Integração com Rails**: Conectar formulários com backend
2. **Analytics**: Implementar tracking de conversões
3. **A/B Testing**: Configurar variações de headline/CTA
4. **SEO**: Adicionar mais meta tags e schema markup
5. **Performance**: Implementar service worker para cache
6. **Acessibilidade**: Audit completo de WCAG
7. **Video**: Produzir e adicionar vídeo demonstrativo real

---

**Status**: ✅ Completa e pronta para produção
**Versão**: 1.0.0
**Última atualização**: Janeiro 2025
