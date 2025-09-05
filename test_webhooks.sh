#!/bin/bash

# 🔗 Stripe Webhook - Comandos de Teste Local
# Link Flow Project

echo "🚀 Configurando ambiente de teste para Webhooks Stripe..."

# Verificar se Stripe CLI está instalado
if ! command -v stripe &> /dev/null; then
    echo "❌ Stripe CLI não encontrado. Instalando..."
    brew install stripe/stripe-cli/stripe
fi

echo "✅ Stripe CLI encontrado!"

# Login no Stripe (se necessário)
echo "🔐 Fazendo login no Stripe..."
echo "Execute: stripe login"
echo "Siga as instruções no navegador para autenticar"

# Comando para escutar webhooks localmente
echo ""
echo "🎯 Para testar webhooks localmente, execute:"
echo "stripe listen --forward-to localhost:3000/webhooks/stripe"
echo ""

# Comandos de teste para eventos específicos
echo "📋 Comandos para simular eventos (execute em outro terminal):"
echo ""

echo "1️⃣  Nova Assinatura:"
echo "stripe trigger customer.subscription.created"
echo ""

echo "2️⃣  Assinatura Atualizada:"
echo "stripe trigger customer.subscription.updated" 
echo ""

echo "3️⃣  Assinatura Cancelada:"
echo "stripe trigger customer.subscription.deleted"
echo ""

echo "4️⃣  Pagamento Bem-sucedido:"
echo "stripe trigger invoice.payment_succeeded"
echo ""

echo "5️⃣  Falha no Pagamento:"
echo "stripe trigger invoice.payment_failed"
echo ""

echo "6️⃣  Trial Terminando:"
echo "stripe trigger customer.subscription.trial_will_end"
echo ""

echo "💡 Dicas importantes:"
echo "• Mantenha o Rails server rodando (rails server)"
echo "• Verifique os logs em: tail -f log/development.log"
echo "• O endpoint local é: http://localhost:3000/webhooks/stripe"
echo ""

echo "🧪 Para testar via interface admin:"
echo "• Acesse: http://localhost:3000/admin/stripe_config"
echo "• Clique em 'Testar Webhook'"
echo "• Verifique os logs da aplicação"
echo ""

echo "📊 Para monitorar eventos:"
echo "• Dashboard Stripe: https://dashboard.stripe.com/webhooks"
echo "• Logs Rails: tail -f log/development.log | grep -i webhook"
