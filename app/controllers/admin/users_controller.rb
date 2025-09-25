class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :change_role, :sync_stripe]

  def index
    @users = User.includes(:subscriptions)
                 .order(created_at: :desc)
                 .limit(50)
  end

  def show
    @user_subscriptions = @user.subscriptions.includes(:plan).order(created_at: :desc)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'Usuário atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def change_role
    if @user.update(role: params[:role])
      redirect_to admin_user_path(@user), notice: 'Papel do usuário alterado com sucesso!'
    else
      redirect_to admin_user_path(@user), alert: 'Erro ao alterar papel do usuário.'
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: 'Você não pode excluir sua própria conta.'
    else
      @user.destroy
      redirect_to admin_users_path, notice: 'Usuário excluído com sucesso!'
    end
  end

  def sync_stripe
    result = StripeService.sync_user_subscriptions(@user)

    if result[:success]
      redirect_to admin_user_path(@user), notice: result[:message]
    else
      redirect_to admin_user_path(@user), alert: "Erro na sincronização: #{result[:error]}"
    end
  end

  def sync_all_stripe
    result = StripeService.sync_all_users_subscriptions

    if result[:success]
      redirect_to admin_users_path, notice: result[:message]
    else
      redirect_to admin_users_path, alert: "Erro na sincronização: #{result[:errors].join(', ')}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :role)
  end
end
