class EmailWorker
  include Sidekiq::Worker
  
  def perform(params, count)
    params.symbolize_keys!
    DeveloperMailer.contact_email(params).deliver
    puts "Emailed!"
  end
end