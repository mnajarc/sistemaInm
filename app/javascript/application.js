// app/javascript/application.js

window.translations = window.translations || {};
window.I18n = window.I18n || { translations: {} };


import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import './form_validation';
import "./document_preview"

window.bootstrap = bootstrap

// Variable para trackear componentes
let navbarCollapse = null
let allDropdowns = []
let allCollapses = []

let isInitialized = false;

document.addEventListener("turbo:before-cache", () => {
  // Destruir todos los componentes antes de guardar en cache
  allDropdowns.forEach(dropdown => dropdown.dispose())
  allCollapses.forEach(collapse => collapse.dispose())
  allDropdowns = []
  allCollapses = []
  navbarCollapse = null
  isInitialized = false;
})

// 🟢 NUEVO - Solo UNA VEZ por página
document.addEventListener("turbo:render", () => {
  console.log("Inicializando Bootstrap components...")
  
  // Limpia componentes anteriores
  allDropdowns.forEach(dropdown => dropdown.dispose())
  allCollapses.forEach(collapse => collapse.dispose())
  allDropdowns = []
  allCollapses = []
  navbarCollapse = null
  
  // Reinitializa TODO de nuevo sin flag
  const navbarTogglerBtn = document.querySelector(".navbar-toggler")
  if (navbarTogglerBtn) {
    navbarCollapse = new bootstrap.Collapse(document.querySelector(".navbar-collapse"), { toggle: false })
  }

  const dropdownElements = document.querySelectorAll("[data-bs-toggle='dropdown']")
  dropdownElements.forEach(element => {
    allDropdowns.push(new bootstrap.Dropdown(element))
  })

  const collapseElements = document.querySelectorAll("[data-bs-toggle='collapse']")
  collapseElements.forEach(element => {
    allCollapses.push(new bootstrap.Collapse(element, { toggle: false }))
  })

  console.log("Bootstrap components initialized:", { dropdowns: allDropdowns.length, collapses: allCollapses.length })
})

// Y QUITA el turbo:before-cache
