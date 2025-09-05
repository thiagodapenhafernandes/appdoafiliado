module AdminHelper
  def admin_navigation_link(text, path, options = {})
    classes = "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"
    
    if current_page?(path)
      classes = "border-indigo-500 text-indigo-600 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"
    end
    
    link_to text, path, options.merge(class: classes)
  end

  def role_badge(user)
    case user.role
    when 'super_admin'
      content_tag :span, "Super Admin", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800"
    when 'admin'
      content_tag :span, "Admin", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
    else
      content_tag :span, "Usuário", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    end
  end

  def subscription_status_badge(subscription)
    case subscription.status
    when 'active'
      content_tag :span, "Ativo", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    when 'trialing'
      content_tag :span, "Trial", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    when 'canceled'
      content_tag :span, "Cancelado", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
    else
      content_tag :span, subscription.status.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    end
  end

  def stripe_sync_status(plan)
    if plan.stripe_price_id.present?
      content_tag :span, "Sincronizado", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    else
      content_tag :span, "Não Sincronizado", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    end
  end
end
