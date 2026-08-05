class AddPhase10ReferencesToCampaignCommercialHandoffs < ActiveRecord::Migration[7.1]
  def change
    change_table :campaign_commercial_handoffs do |t|
      t.string :salesforce_proposal_id
      t.string :proposal_reference
      t.string :proposal_terms_digest
      t.string :contract_reference
      t.string :contract_terms_digest
      t.string :invoice_reference
      t.string :cash_collection_reference
      t.string :revenue_system
      t.datetime :last_revenue_signal_at
    end

    add_index :campaign_commercial_handoffs, :salesforce_proposal_id, unique: true
    add_index :campaign_commercial_handoffs, :contract_reference, unique: true
    add_index :campaign_commercial_handoffs, :invoice_reference, unique: true
    add_index :campaign_commercial_handoffs, :cash_collection_reference, unique: true
    add_index :campaign_commercial_handoffs, :last_revenue_signal_at
  end
end
