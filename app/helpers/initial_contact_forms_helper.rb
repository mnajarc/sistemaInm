# app/helpers/initial_contact_forms_helper.rb

module InitialContactFormsHelper
    def status_badge_class(status)
      case status.to_sym
      when :draft
        'secondary'
      when :completed
        'warning'
      when :converted
        'success'
      when :archived
        'danger'
      else
        'light'
      end
    end
  end
  