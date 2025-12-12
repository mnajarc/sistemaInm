// app/javascript/controllers/document_submissions_controller.js

document.addEventListener('DOMContentLoaded', function() {
  initializeDocumentModals();
  initializeNoteHandlers();
});

// Manejar modales de upload y reject
function initializeDocumentModals() {
  const uploadModal = document.getElementById('uploadModal');
  const rejectModal = document.getElementById('rejectModal');
  const notesModal = document.getElementById('notesModal');

  if (uploadModal) {
    uploadModal.addEventListener('show.bs.modal', function(event) {
      const documentId = event.relatedTarget.dataset.documentId;
      const form = document.getElementById('uploadForm');
      const businessTxId = document.querySelector('[data-business-transaction-id]')?.dataset.businessTransactionId;
      
      form.action = `/business_transactions/${businessTxId}/document_submissions/${documentId}/upload`;
      form.method = 'POST';
    });
  }

  if (rejectModal) {
    rejectModal.addEventListener('show.bs.modal', function(event) {
      const documentId = event.relatedTarget.dataset.documentId;
      const form = document.getElementById('rejectForm');
      const businessTxId = document.querySelector('[data-business-transaction-id]')?.dataset.businessTransactionId;
      
      form.action = `/business_transactions/${businessTxId}/document_submissions/${documentId}/reject`;
      form.method = 'POST';
    });
  }

  if (notesModal) {
    notesModal.addEventListener('show.bs.modal', function(event) {
      const submissionId = event.relatedTarget.dataset.submissionId;
      const businessTxId = document.querySelector('[data-business-transaction-id]')?.dataset.businessTransactionId;
      
      // Cargar notas dinámicamente
      fetch(`/business_transactions/${businessTxId}/document_submissions/${submissionId}`, {
        headers: { 'Accept': 'text/html' }
      })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const notesPanel = doc.querySelector('.notes-panel');
        document.getElementById('notesContainer').innerHTML = notesPanel.innerHTML;
        
        // Re-inicializar handlers
        initializeNoteHandlers();
      })
      .catch(error => console.error('Error cargando notas:', error));
    });
  }
}

// Manejar agregar y eliminar notas
function initializeNoteHandlers() {
  // Agregar nota
  document.querySelectorAll('.add-note-form-submit').forEach(form => {
    form.addEventListener('submit', async function(e) {
      e.preventDefault();
      
      const submissionId = this.dataset.submissionId;
      const content = document.getElementById(`noteContent-${submissionId}`).value;
      const businessTxId = document.querySelector('[data-business-transaction-id]')?.dataset.businessTransactionId;
      
      try {
        const response = await fetch(
          `/business_transactions/${businessTxId}/document_submissions/${submissionId}/add_note`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: `content=${encodeURIComponent(content)}`
          }
        );
        
        if (response.ok) {
          // Limpiar formulario
          this.reset();
          // Recargar notas
          location.reload(); // O usar AJAX para actualizar sin recargar
        } else {
          alert('Error al agregar la nota');
        }
      } catch (error) {
        console.error('Error:', error);
        alert('Error al agregar la nota');
      }
    });
  });

  // Eliminar nota
  document.querySelectorAll('[data-delete-note]').forEach(btn => {
    btn.addEventListener('click', async function(e) {
      e.preventDefault();
      
      if (!confirm('¿Eliminar esta nota? No se puede deshacer.')) return;
      
      const noteId = this.dataset.deleteNote;
      const businessTxId = document.querySelector('[data-business-transaction-id]')?.dataset.businessTransactionId;
      const submissionId = this.dataset.submissionId;
      
      try {
        const response = await fetch(
          `/business_transactions/${businessTxId}/document_submissions/${submissionId}/delete_note/${noteId}`,
          {
            method: 'DELETE',
            headers: {
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            }
          }
        );
        
        if (response.ok) {
          document.querySelector(`[data-note-id="${noteId}"]`).remove();
        } else {
          alert('Error al eliminar la nota');
        }
      } catch (error) {
        console.error('Error:', error);
        alert('Error al eliminar la nota');
      }
    });
  });
}
