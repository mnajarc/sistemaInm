// app/javascript/controllers/document_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preview(event) {
    const docId = event.currentTarget.dataset.docId
    const url = `/business_transactions/${this.businessTransactionId}/document_submissions/${docId}`
    
    fetch(url, {
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.renderPreview(data)
    })
  }

  renderPreview(data) {
    const modalBody = document.getElementById('documentPreviewBody')
    const modalTitle = document.getElementById('documentPreviewTitle')
    
    modalTitle.textContent = data.document_type.display_name
    
    if (data.document_file_url) {
      modalBody.innerHTML = `
        <img src="${data.document_file_url}" class="img-fluid" alt="Preview">
      `
    } else {
      modalBody.innerHTML = '<p>No hay preview disponible</p>'
    }
  }

  get businessTransactionId() {
    return this.element.dataset.businessTransactionId
  }
}