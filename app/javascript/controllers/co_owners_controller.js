import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "container",
    "item",
    "template",
    "totalPercentage",
    "remainingPercentage",
    "totalCount"
  ]

  connect() {
    console.log("✅ Co-owners controller conectado")
    this.updateSummary()
  }

  // Se llama desde el select de tipo de copropiedad (si quieres añadir lógica luego)
  updateCoOwnershipType(event) {
    console.log("📌 Tipo de copropiedad cambiado:", event.target.value)
  }

  addCoOwner(event) {
    if (event) event.preventDefault()

    if (!this.hasTemplateTarget) {
      console.warn("⚠️ No hay template para co-owners")
      return
    }

    // ✅ GENERAR TIMESTAMP ÚNICO (no usar NEW_RECORD)
    const timestamp = new Date().getTime()
    
    // ✅ REEMPLAZAR NEW_RECORD con timestamp en el HTML del template
    const templateHTML = this.templateTarget.innerHTML
    const newHTML = templateHTML.replace(/NEW_RECORD/g, timestamp)
    
    // ✅ CREAR ELEMENTO TEMPORAL Y EXTRAER PRIMER HIJO
    const temp = document.createElement('div')
    temp.innerHTML = newHTML
    const newElement = temp.firstElementChild
    
    // ✅ AGREGAR AL CONTAINER
    if (newElement) {
      this.containerTarget.appendChild(newElement)
      this.updateSummary()
      console.log(`✅ Copropietario agregado con índice ${timestamp}`)
    } else {
      console.error("❌ No se pudo crear el elemento desde el template")
    }
  }


  addCoOwnerAnterior(event) {
    if (event) event.preventDefault()

    if (!this.hasTemplateTarget) {
      console.warn("⚠️ No hay template para co-owners")
      return
    }

    const content = this.templateTarget.content
    const clone   = document.importNode(content, true)

    this.containerTarget.appendChild(clone)
    this.updateSummary()
  }

  removeCoOwner(event) {
    event.preventDefault()

    const button = event.target.closest("button")
    if (!button) return

    const item = button.closest(".co-owner-item")
    if (!item) return

    // No dejar la lista vacía
    if (this.itemTargets.length > 1) {
      item.remove()
      this.updateSummary()
    }
  }

  updatePercentages() {
    this.updateSummary()
  }

  updateSummary() {
    let total = 0

    this.itemTargets.forEach(item => {
      const input = item.querySelector('input[name*="[percentage]"]')
      if (input && input.value) {
        const value = parseFloat(input.value)
        if (!Number.isNaN(value)) total += value
      }
    })

    if (this.hasTotalPercentageTarget) {
      this.totalPercentageTarget.textContent = `${total.toFixed(2)}%`
    }

    if (this.hasRemainingPercentageTarget) {
      const remaining = 100 - total
      this.remainingPercentageTarget.textContent = `${remaining.toFixed(2)}%`
    }

    if (this.hasTotalCountTarget) {
      this.totalCountTarget.textContent = this.itemTargets.length
    }
  }

  autoSetup(event) {
    event.preventDefault()

    const select = document.querySelector('select[name*="co_ownership_type_id"]')
    if (!select || !select.value) {
      alert("⚠️ Seleccione un tipo de copropiedad")
      return
    }

    const firstItem = this.itemTargets[0]
    if (!firstItem) return

    const pct  = firstItem.querySelector('input[name*="[percentage]"]')
    const role = firstItem.querySelector('select[name*="[role]"]')

    if (pct)  pct.value  = "100"
    if (role) role.value = "propietario"

    this.updateSummary()
  }

  updateClientName(event) {
    const select    = event.target
    const item      = select.closest(".co-owner-item")
    const nameInput = item && item.querySelector('input[name*="[person_name]"]')

    if (select.value && nameInput) {
      nameInput.value = select.options[select.selectedIndex].text
    }
  }
}
