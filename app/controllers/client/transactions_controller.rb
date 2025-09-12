class Client::TransactionsController < Client::BaseController
  def index
    @my_transactions = if current_client
                         current_client.all_transactions
                                      .includes(:property, :operation_type, :business_status)
                                      .order(created_at: :desc)
                       else
                         BusinessTransaction.none
                       end
  end

  def show
    @transaction = if current_client
                     current_client.all_transactions.find(params[:id])
                   else
                     BusinessTransaction.find(params[:id])
                   end
    
    # Verificar que el cliente puede ver esta transacción
    unless @transaction.offering_client == current_client || 
           @transaction.acquiring_client == current_client
      redirect_to client_transactions_path, alert: 'Transacción no encontrada'
    end
  end
end
