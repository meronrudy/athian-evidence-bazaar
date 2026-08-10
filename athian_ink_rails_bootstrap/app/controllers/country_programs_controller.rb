class CountryProgramsController < ApplicationController
  before_action :authenticate_user!

  def index
    @country_programs = CountryProgram.active.includes(:country, :adapter)
    @filters = {
      country: params[:country],
      status: params[:status],
      search: params[:search]
    }
  end

  def show
    @country_program = CountryProgram.find(params[:id])
  end

  def evaluate
    @country_program = CountryProgram.find(params[:id])
    # Redirect to evaluation playground
    redirect_to evaluate_country_program_path(@country_program)
  end
end