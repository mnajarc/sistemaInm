class Admin::DashboardController < Admin::BaseController
  # Saltamos verify_policy_scoped solo para el dashboard porque
  # mostramos datos agregados (counts) y no una lista específica controlada por Pundit
  before_action :verify_policy_scoped, only: :index
  
  def index
    # 1. Estadísticas Generales para los KPIs
    @stats = {
      total_users: User.count,
      total_transactions: BusinessTransaction.count,
      total_properties: Property.count,
      total_document_types: DocumentType.count,
      pending_documents: DocumentSubmission.pending.count,
      active_transactions: BusinessTransaction.active.count
    }

    # 2. Listas para "Lo más reciente"
    # Usamos includes para evitar N+1 queries
    @recent_transactions = BusinessTransaction
                          .order(created_at: :desc)
                          .limit(5)
                          .includes(:business_status, :operation_type, :property)

    @pending_documents = DocumentSubmission.pending
                                         .limit(5)
                                         .includes(:document_type, :business_transaction)

    # 3. Menú Dinámico (Iconos de acceso directo)
    # Reutilizamos tu lógica de MenuItem para mostrar solo lo que el usuario puede ver
    @accessible_menu_items = MenuItem.accessible_for_user(current_user)
                                   .parent_items
                                   .order(:sort_order)
  end

  private

  def verify_policy_scoped
    # Método vacío intencional para bypassear el after_action de BaseController
    # solo en esta acción de dashboard
  end
end
