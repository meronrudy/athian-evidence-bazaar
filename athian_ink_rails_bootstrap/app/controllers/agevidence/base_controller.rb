module Agevidence
  class BaseController < ApplicationController
    private

    def products
      ProductCatalog.all
    end

    def product_notice
      ProductCatalog.notice
    end
  end
end
