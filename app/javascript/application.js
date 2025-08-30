// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

window.bootstrap = bootstrap

// Variable para trackear componentes
let navbarCollapse = null
let allDropdowns = []
let allCollapses = []

document.addEventListener("turbo:before-cache", () => {
  // Destruir todos los componentes antes de guardar en cache
  allDropdowns.forEach(dropdown => dropdown.dispose())
  allCollapses.forEach(collapse => collapse.dispose())
  allDropdowns = []
  allCollapses = []
  navbarCollapse = null
})

document.addEventListener("turbo:load", () => {
  console.log("Reinicializando Bootstrap components...")
  
  // Destruir componentes existentes primero
  allDropdowns.forEach(dropdown => dropdown.dispose())
  allCollapses.forEach(collapse => collapse.dispose())
  allDropdowns = []
  allCollapses = []

  // Recrear todos los dropdowns
  document.querySelectorAll('[data-bs-toggle="dropdown"]').forEach(el => {
    const dropdown = new bootstrap.Dropdown(el)
    allDropdowns.push(dropdown)
  })
  
  // Recrear todos los collapses
  document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(el => {
    const targetId = el.getAttribute('data-bs-target')
    const target = document.querySelector(targetId)
    if (target) {
      const collapse = new bootstrap.Collapse(target, { toggle: false })
      allCollapses.push(collapse)
      
      // Si es el navbar, guardarlo
      if (targetId === '#mainNavbar') {
        navbarCollapse = collapse
      }
    }
  })

  // Cerrar hamburguesa en navegación real
  document.querySelectorAll('.navbar-collapse .nav-link:not(.dropdown-toggle)').forEach(link => {
    if (!link.hasAttribute('data-bs-toggle')) {
      link.addEventListener('click', function(e) {
        const href = this.getAttribute('href')
        if (href && href !== '#' && !href.startsWith('#')) {
          const navbarCollapseEl = document.querySelector('.navbar-collapse.show')
          if (navbarCollapseEl && window.innerWidth < 992 && navbarCollapse) {
            navbarCollapse.hide()
          }
        }
      })
    }
  })
  
  console.log("Bootstrap components initialized:", {
    dropdowns: allDropdowns.length,
    collapses: allCollapses.length
  })
})
