// Extraindo apenas o JavaScript para validação
class StripeRegistration {
  constructor() {
    this.stripe = null;
    this.elements = null;
    this.cardElement = null;
    this.isReady = false;
    this.form = null;
    this.submitButton = null;
    
    console.log('🚀 Construtor StripeRegistration chamado');
    
    setTimeout(() => {
      this.init();
    }, 100);
  }
  
  init() {
    console.log('🔄 Método init() chamado');
    
    if (document.readyState === 'loading') {
      console.log('📄 DOM ainda carregando, aguardando...');
      document.addEventListener('DOMContentLoaded', () => this.setup());
    } else {
      console.log('📄 DOM já carregado, iniciando setup...');
      this.setup();
    }
  }

  setup() {
    console.log('📄 Setup iniciado - DOM ready');
    
    this.form = document.getElementById('registration-form');
    this.submitButton = document.getElementById('submit-button');
    
    console.log('🔍 Form encontrado:', !!this.form);
    console.log('🔍 Submit button encontrado:', !!this.submitButton);
    
    if (!this.form || !this.submitButton) {
      console.error('❌ Elementos essenciais não encontrados');
      console.log('- Form element:', this.form);
      console.log('- Submit button:', this.submitButton);
      return;
    }
    
    this.waitForStripe();
  }
  
  waitForStripe() {
    console.log('⏳ Aguardando Stripe carregar...');
    
    let attempts = 0;
    const maxAttempts = 50;
    
    const checkStripe = () => {
      attempts++;
      console.log('🔍 Tentativa ' + attempts + ': typeof Stripe =', typeof Stripe);
      
      if (typeof Stripe !== 'undefined') {
        console.log('✅ Stripe.js finalmente carregado!');
        this.initializeStripe();
        this.setupEventListeners();
        this.setupPlanSelection();
      } else if (attempts < maxAttempts) {
        console.log('⏳ Stripe ainda não carregou, tentativa ' + attempts + '/' + maxAttempts + '...');
        setTimeout(checkStripe, 100);
      } else {
        console.error('❌ Timeout aguardando Stripe carregar após 5 segundos');
        this.handleStripeUnavailable();
      }
    };
    
    checkStripe();
  }

  initializeStripe() {
    const stripeKey = 'pk_test_123'; // Dummy key for testing
    
    console.log('🔑 Chave Stripe:', stripeKey ? stripeKey.substring(0, 12) + '...' : 'não encontrada');
    
    if (!stripeKey || stripeKey === '' || stripeKey.includes('undefined')) {
      console.error('❌ Chave do Stripe não configurada');
      this.showError('Configuração de pagamento inválida');
      return;
    }

    try {
      console.log('🎯 Inicializando Stripe com chave...');
      this.stripe = Stripe(stripeKey);
      this.elements = this.stripe.elements();
      
      console.log('✅ Stripe inicializado com sucesso');
      
      this.cardElement = this.elements.create('card', {
        style: {
          base: {
            fontSize: '16px',
            color: '#374151',
            fontFamily: 'system-ui, sans-serif',
            '::placeholder': {
              color: '#9CA3AF',
            },
          },
          invalid: {
            color: '#EF4444',
            iconColor: '#EF4444'
          },
        },
        hidePostalCode: true
      });
      
      console.log('🎨 Elemento do cartão criado');
      
      const cardContainer = document.getElementById('card-element');
      if (!cardContainer) {
        console.error('❌ Container do cartão não encontrado');
        return;
      }
      
      this.cardElement.mount('#card-element');
      console.log('✅ Elemento do cartão montado');
      
      this.cardElement.on('ready', () => {
        console.log('✅ Cartão pronto para uso');
        this.isReady = true;
        this.updateStatus(true);
        this.enableSubmitButton();
      });
      
      this.cardElement.on('change', (event) => {
        const errorElement = document.getElementById('card-errors');
        if (errorElement) {
          errorElement.textContent = event.error ? event.error.message : '';
        }
        console.log('🎫 Status do cartão:', event.complete ? 'valido' : 'incompleto');
      });
      
      this.cardElement.on('focus', () => {
        const errorElement = document.getElementById('card-errors');
        if (errorElement) {
          errorElement.textContent = '';
        }
      });
      
    } catch (error) {
      console.error('❌ Erro ao inicializar Stripe:', error);
      this.showError('Erro na inicialização do sistema de pagamento');
    }
  }
  
  enableSubmitButton() {
    if (this.submitButton) {
      this.submitButton.disabled = false;
      this.submitButton.style.opacity = '1';
      this.submitButton.style.cursor = 'pointer';
      this.submitButton.value = 'Iniciar teste grátis de 14 dias';
      console.log('✅ Botão de submit habilitado');
    } else {
      console.error('❌ Botão de submit não encontrado para habilitar');
    }
  }
}

console.log('JavaScript válido!');
