# app/helpers/document_submissions_helper.rb
module DocumentSubmissionsHelper
  def legibility_badge_color(score)
    return 'secondary' if score.nil?
    
    case score
    when 0...40 then 'danger'
    when 40...70 then 'warning'
    when 70...90 then 'success'
    else 'primary'
    end
  end

  def expiry_alert_class(submission)
    return 'secondary' unless submission.expiry_date.present?
    
    if submission.expired?
      'danger'
    elsif submission.expiring_soon?
      'warning'
    else
      'info'
    end
  end

  def document_icon(document_type)
    case document_type.category
    when 'identidad' then 'bi-person-badge'
    when 'propiedad' then 'bi-house-door'
    when 'financieros' then 'bi-currency-dollar'
    when 'legales' then 'bi-file-earmark-ruled'
    when 'pld' then 'bi-shield-check'
    else 'bi-file-earmark'
    end
  end
end