class LinksController < ApplicationController
  before_action :set_link, only: [:show, :edit, :update, :destroy]

  def index
    @links = current_user.links.order(created_at: :desc)
    @links_count = @links.count
    @total_clicks = @links.sum(:clicks_count)
    @active_links = @links.where(active: true).count
    @request = request
  end

  def show
    @short_url = @link.short_url(request)
  end

  def new
    @link = current_user.links.build
    @request = request
    
    unless current_user.can_create_links?
      redirect_to links_path, alert: 'Você atingiu o limite de links do seu plano.'
    end
  end

  def create
    @link = current_user.links.build(link_params)
    @request = request

    unless current_user.can_create_links?
      redirect_to links_path, alert: 'Você atingiu o limite de links do seu plano.'
      return
    end

    if @link.save
      redirect_to @link, notice: 'Link criado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @short_url = @link.short_url(request)
  end

  def update
    if @link.update(link_params)
      redirect_to @link, notice: 'Link atualizado com sucesso!'
    else
      @short_url = @link.short_url(request)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @link.destroy
    redirect_to links_path, notice: 'Link deletado com sucesso!'
  end
  
  def preview
    @link = current_user.links.build(link_params.except(:custom_slug))
    @link.custom_slug = link_params[:custom_slug] if link_params[:custom_slug].present?
    
    respond_to do |format|
      format.json do
        if @link.valid?
          render json: {
            short_url: @link.short_url(request),
            expires_at: @link.expires_at&.strftime("%d/%m/%Y"),
            tag_list: @link.tag_list
          }
        else
          render json: { errors: @link.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_link
    @link = current_user.links.find(params[:id])
  end

  def link_params
    permitted_params = [:original_url, :name, :title, :description, :custom_slug, :tags, :expires_at, :active]
    
    # Permitir advanced_tracking apenas para planos Pro e Elite
    if current_user.can_access_advanced_tracking?
      permitted_params << :advanced_tracking
    end
    
    params.require(:link).permit(permitted_params)
  end
end
