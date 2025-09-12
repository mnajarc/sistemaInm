  class BusinessTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy transfer_agent]

  def index
    @transactions = if current_user.client?
                      current_user.client.offered_transactions
                    elsif current_user.agent_or_above?
                      BusinessTransaction.by_current_agent(current_user)
                    else
                      BusinessTransaction.none
                    end
  end

  def show
    authorize @transaction
  end

  def new
    @transaction = BusinessTransaction.new
    @clients = Client.active
  end

  def create
    @transaction = BusinessTransaction.new(transaction_params)
    @transaction.listing_agent = current_user
    @transaction.current_agent = current_user
    authorize @transaction

    if @transaction.save
      redirect_to @transaction, notice: 'Transacción creada exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @transaction
  end

  def update
    authorize @transaction
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: 'Transacción actualizada'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @transaction
    @transaction.destroy
    redirect_to business_transactions_path, notice: 'Transacción eliminada'
  end

  # PATCH /business_transactions/:id/transfer_agent
  def transfer_agent
    authorize @transaction, :update?
    new_agent = User.find(params[:new_agent_id])
    @transaction.transfer_to_agent!(new_agent, params[:reason], current_user)
    redirect_to @transaction, notice: 'Agente transferido correctamente'
  end

  private

  def set_transaction
    @transaction = BusinessTransaction.find(params[:id])
  end

  def transaction_params
    params.require(:business_transaction).permit(
      :property_id, :operation_type_id, :business_status_id,
      :offering_client_id, :acquiring_client_id,
      :price, :commission_percentage, :start_date, :estimated_completion_date, :notes
    )
  end
end
