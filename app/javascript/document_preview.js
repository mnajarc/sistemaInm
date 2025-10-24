// app/javascript/document_preview.js
document.addEventListener('DOMContentLoaded', function() {
  // Escuchar clicks en botones de preview
  document.addEventListener('click', function(e) {
    const previewBtn = e.target.closest('.preview-document-btn');
    if (!previewBtn) return;
    
    e.preventDefault();
    
    const url = previewBtn.getAttribute('data-preview-url');
    const modal = new bootstrap.Modal(document.getElementById('documentPreviewModal'));
    const modalBody = document.getElementById('documentPreviewBody');
    
    // Mostrar loading
    modalBody.innerHTML = `
      <div class="text-center p-5">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Cargando...</span>
        </div>
        <p class="mt-3 text-muted">Cargando documento...</p>
      </div>
    `;
    
    // Abrir modal
    modal.show();
    
    // Cargar contenido
    fetch(url, {
      headers: {
        'Accept': 'text/html'
      }
    })
      .then(response => {
        if (!response.ok) throw new Error('Error al cargar');
        return response.text();
      })
      .then(html => {
        modalBody.innerHTML = html;
      })
      .catch(error => {
        modalBody.innerHTML = `
          <div class="alert alert-danger m-3">
            <i class="bi bi-exclamation-triangle"></i>
            Error al cargar el documento: ${error.message}
          </div>
        `;
      });
  });
});
