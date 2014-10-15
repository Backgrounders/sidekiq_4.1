class DeveloperMailer < ActionMailer::Base
  default from: "andrew@example.com"
  
  def contact_email(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    mail(to: 'andrewsinner@gmail.com', subject: 'Welcome to My Awesome Site')
  end
end
