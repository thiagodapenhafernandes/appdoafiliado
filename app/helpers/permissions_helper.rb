module PermissionsHelper
  def plan_access_overlay(required_plan, current_content = nil, &block)
    user_plan = current_user&.current_plan&.name || "Afiliado Starter"
    
    # Definir hierarquia dos planos
    plan_hierarchy = {
      "Afiliado Starter" => 1,
      "Afiliado Pro" => 2, 
      "Afiliado Elite" => 3
    }
    
    required_level = case required_plan.downcase
    when 'pro'
      2
    when 'elite', 'premium'
      3
    else
      1
    end
    
    user_level = plan_hierarchy[user_plan] || 1
    
    # Se usuário tem acesso, renderizar normalmente
    if user_level >= required_level
      if block_given?
        capture(&block)
      else
        current_content
      end
    else
      # Renderizar com overlay de upgrade
      content_tag :div, class: "relative" do
        content_tag(:div, class: "filter blur-sm pointer-events-none") do
          if block_given?
            capture(&block)
          else
            current_content
          end
        end +
        content_tag(:div, class: "absolute inset-0 flex items-center justify-center bg-white/80 backdrop-blur-sm") do
          content_tag(:div, class: "text-center p-6 bg-white rounded-lg shadow-lg border border-gray-200 max-w-sm") do
            content_tag(:div, class: "mb-4") do
              content_tag(:div, "🔒", class: "text-4xl mb-2") +
              content_tag(:h3, "Acesso para perfil #{required_plan.capitalize}", class: "text-lg font-semibold text-gray-800 mb-2") +
              content_tag(:p, "Esta funcionalidade está disponível apenas para usuários do plano #{required_plan.capitalize} ou superior.", class: "text-sm text-gray-600")
            end +
            link_to("Fazer Upgrade", plans_path, class: "inline-flex items-center px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 text-white text-sm font-medium rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all duration-200 transform hover:scale-105")
          end
        end
      end
    end
  end
  
  def has_plan_access?(required_plan)
    user_plan = current_user&.current_plan&.name || "Afiliado Starter"
    
    plan_hierarchy = {
      "Afiliado Starter" => 1,
      "Afiliado Pro" => 2, 
      "Afiliado Elite" => 3
    }
    
    required_level = case required_plan.downcase
    when 'pro'
      2
    when 'elite', 'premium'
      3
    else
      1
    end
    
    user_level = plan_hierarchy[user_plan] || 1
    user_level >= required_level
  end
end
