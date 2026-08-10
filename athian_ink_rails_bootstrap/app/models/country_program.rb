class CountryProgram < ApplicationRecord
  validates :name, presence: true
  validates :country_code, presence: true
  validates :description, presence: true

  scope :active, -> { where(active: true) }
  scope :by_country, ->(country_code) { where(country_code: country_code) }

  def self.search(params = {})
    programs = active
    programs = programs.where(country_code: params[:country]) if params[:country]
    programs = programs.where("name LIKE ? OR description LIKE ?", 
                              "%#{params[:search]}%", "%#{params[:search]}%") if params[:search]
    programs
  end

  def adapter_count
    adapters.count
  end

  def status
    active? ? "Active" : "Inactive"
  end

  def active?
    active
  end
end