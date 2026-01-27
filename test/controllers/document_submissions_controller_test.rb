# test/controllers/document_submissions_controller_test.rb
test "agent can validate document" do
  sign_in(@agent)
  patch business_transaction_document_submission_validate_path(@bt, @doc), 
        params: { notes: "OK" }
  
  assert_response :redirect
  assert @doc.reload.document_status.name == 'validado'
end

# Ejecutar
rails test test/controllers/document_submissions_controller_test.rb
