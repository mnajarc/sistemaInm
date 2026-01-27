class DocumentSubmissionPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # ✅ VER DOCUMENTO: Owner (quien lo envió) + Agent + Admin
  def show?
    user.present? && (is_owner? || is_agent? || is_admin?)
  end

  # ✅ DESCARGAR: Mismo que show
  def preview?
    show?
  end

  def download?
    show?
  end

  # ✅ VALIDAR: Solo Admin/Agent (no solo revisor)
  # Agent = persona que revisa y acepta/rechaza
  # Admin = administrador del sistema
  def validate?
    user.present? && (is_agent_reviewer? || is_admin?)
  end

  # ✅ RECHAZAR: Solo Admin/Agent (igual que validar)
  # Pueden rechazar INCLUSO SI YA FUE ACEPTADO (para corregir errores)
  def reject?
    user.present? && (is_agent_reviewer? || is_admin?)
  end

  # ✅ MARCAR EXPIRADO: Solo Admin/Agent (en caso de error manual)
  # Normalmente lo hace el service automáticamente
  def mark_expired?
    user.present? && (is_agent_reviewer? || is_admin?)
  end

  # ✅ COMENTAR: TODOS (owner, agent, admin)
  # Es el canal de comunicación entre todos
  def add_note?
    user.present? && (is_owner? || is_agent_reviewer? || is_admin?)
  end

  # ✅ BORRAR COMENTARIOS: Solo Agent/Admin (quienes revisan)
  def delete_note?
    user.present? && (is_agent_reviewer? || is_admin?)
  end

  private

  # ¿Es el que ENVIÓ el documento?
  def is_owner?
    record.uploaded_by_id == user.id
  end

  # ¿Es AGENT o REVIEWER? (las 2 roles que REVISAN/VALIDAN)
  def is_agent_reviewer?
    return false if user.blank?
    
    begin
      # Intenta usar métodos booleanos si existen
      return true if user.respond_to?(:agent?) && user.agent?
      return true if user.respond_to?(:reviewer?) && user.reviewer?
    rescue NoMethodError
      # Ignorar si no existen estos métodos
    end

    # Fallback: revisar el atributo role
    begin
      user.role.in?(['agent', 'reviewer', 'asesor', 'agente'])
    rescue NoMethodError
      false
    end
  end

  # ¿Es ADMIN o SUPERADMIN?
  def is_admin?
    return false if user.blank?

    begin
      # Intenta usar métodos booleanos si existen
      return true if user.respond_to?(:admin?) && user.admin?
      return true if user.respond_to?(:superadmin?) && user.superadmin?
    rescue NoMethodError
      # Ignorar si no existen estos métodos
    end

    # Fallback: revisar el atributo role
    begin
      user.role.in?(['admin', 'superadmin'])
    rescue NoMethodError
      false
    end
  end
end
