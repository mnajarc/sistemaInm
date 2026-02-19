// app/javascript/controllers/client_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "results", "selectedDisplay"]
  static values = { 
    url: { type: String, default: "/clients/search" }
  }

  connect() {
    console.log("✅ Client search controller connected")
    this.debounceTimer = null
    
    // Cerrar resultados al hacer clic fuera
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.clickOutsideHandler)
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
    document.removeEventListener('click', this.clickOutsideHandler)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  search(event) {
    const query = event.target.value.trim()
    
    clearTimeout(this.debounceTimer)
    
    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Debounce: esperar 300ms después de que el usuario deje de escribir
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      console.log(`🔍 Buscando clientes: "${query}"`)
      
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const clients = await response.json()
      console.log(`✅ Encontrados ${clients.length} clientes`)
      this.displayResults(clients)
    } catch (error) {
      console.error("❌ Error buscando clientes:", error)
      this.showError()
    }
  }

  displayResults(clients) {
    if (clients.length === 0) {
      this.resultsTarget.innerHTML = '<div class="list-group-item text-muted">No se encontraron clientes</div>'
      this.resultsTarget.style.display = 'block'
      return
    }

    this.resultsTarget.innerHTML = clients.map(client => `
      <button type="button" 
              class="list-group-item list-group-item-action" 
              data-action="click->client-search#selectClient"
              data-client-id="${client.id}"
              data-client-name="${this.escapeHtml(client.display_name)}"
              data-client-email="${this.escapeHtml(client.email || '')}">
        <div class="d-flex justify-content-between align-items-center">
          <div>
            <strong>${this.escapeHtml(client.display_name)}</strong>
            ${client.email ? `<br><small class="text-muted">${this.escapeHtml(client.email)}</small>` : ''}
          </div>
          ${client.phone ? `<small class="text-muted">${this.escapeHtml(client.phone)}</small>` : ''}
        </div>
      </button>
    `).join('')

    this.resultsTarget.style.display = 'block'
  }

  selectClient(event) {
    event.preventDefault()
    const button = event.currentTarget
    const clientId = button.dataset.clientId
    const clientName = button.dataset.clientName

    console.log(`✅ Cliente seleccionado: ${clientName} (ID: ${clientId})`)

    // Establecer el ID oculto
    this.hiddenFieldTarget.value = clientId
    
    // Actualizar el input visible
    this.inputTarget.value = clientName
    
    // Mostrar badge de selección
    this.selectedDisplayTarget.innerHTML = `
      <span class="badge bg-success">${this.escapeHtml(clientName)}</span>
    `

    this.hideResults()
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.style.display = 'none'
      this.resultsTarget.innerHTML = ''
    }
  }

  showError() {
    this.resultsTarget.innerHTML = '<div class="list-group-item text-danger"><i class="fas fa-exclamation-triangle me-2"></i>Error al buscar clientes</div>'
    this.resultsTarget.style.display = 'block'
  }

  // Utilidad para escapar HTML y prevenir XSS
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
