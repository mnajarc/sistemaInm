# app/controllers/admin/agent_transfers_controller.rb
class Admin::AgentTransfersController < Admin::BaseController
  def create
    @transaction = BusinessTransaction.find(params[:business_transaction_id])
    new_agent = User.find(params[:new_agent_id])
    
    @transaction.transfer_to_agent!(
      new_agent, 
      params[:reason], 
      current_user
    )
    
    redirect_to @transaction, notice: "Transacción transferida a #{new_agent.email}"
  end
end
