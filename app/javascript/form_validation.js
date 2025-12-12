// app/javascript/form_validation.js

document.addEventListener('DOMContentLoaded', function() {
  const handleRequiredFields = () => {
    const requiredFields = document.querySelectorAll('[data-originally-required="true"]');
    
    requiredFields.forEach(field => {
      // Si está visible, debe ser required
      const isVisible = field.offsetParent !== null;
      field.required = isVisible;
      field.setAttribute('aria-required', isVisible);
    });
  };

  // Ejecuta al cargar
  handleRequiredFields();

  // Re-ejecuta cuando cambian los selects condicionales
  document.addEventListener('change', function(e) {
    const conditionalSelects = [
      'has_testamentary_select',
      'all_living_select',
      'all_married_select',
      'parents_married_select',
      'inheritance-from-select',
      'donor-relationship-select'
    ];
    
    if (conditionalSelects.includes(e.target.id)) {
      setTimeout(handleRequiredFields, 50);
    }
  });
});

