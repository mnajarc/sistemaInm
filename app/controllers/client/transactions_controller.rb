  # app/controllers/client/transactions_controller.rb
  class Client::TransactionsController < Client::BaseController
    def index
      @my_transactions = current_user.client&.offered_transactions || []
    end
  end
