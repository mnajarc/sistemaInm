# test/models/initial_contact_form_test.rb

require 'test_helper'

class InitialContactFormTest < ActiveSupport::TestCase
  test "should generate property identifier if blank" do
    agent = agents(:one)
    form = InitialContactForm.new(
      agent: agent,
      operation_type: operation_types(:sale),
      general_conditions: { 'owner_or_representative_name' => 'Juan Pérez' }
    )
    
    form.save
    assert_not_nil form.property_human_identifier
    assert_includes form.property_human_identifier, "Juan Pérez"
  end
  
  test "should not override existing property identifier" do
    agent = agents(:one)
    custom_id = "Mi Casa Especial"
    form = InitialContactForm.new(
      agent: agent,
      property_human_identifier: custom_id,
      general_conditions: { 'owner_or_representative_name' => 'Juan Pérez' }
    )
    
    form.save
    assert_equal custom_id, form.property_human_identifier
  end
  
  test "should convert to transaction successfully" do
    form = initial_contact_forms(:complete_one)
    
    assert_difference 'BusinessTransaction.count', 1 do
      assert_difference 'Property.count', 1 do
        transaction = form.convert_to_transaction!
        assert transaction
        assert form.converted?
      end
    end
  end
end
