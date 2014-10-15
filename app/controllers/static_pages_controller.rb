class StaticPagesController < ApplicationController
  def contact
  end
  
  def mail
    EmailWorker.perform_async(params, 5)
  end
end
