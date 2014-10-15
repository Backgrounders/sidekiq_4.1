# README
This is a simple rails app that demonstrates how to integrate ActionMailer with [Sidekiq](http://sidekiq.org/). Sidekiq is an awesome gem for doing background processing.
In our finished app we will have a contact page that lets user sends email address. We'll then be taken to a simple thank you page.
#### Contact page
<img src='https://dl.dropbox.com/s/1w78zm0jqn4bf84/Screenshot%202014-10-14%2017.19.10.png?dl=0'>
#### Redirect page
<img src='https://dl.dropbox.com/s/1ab6cracdugpoko/Screenshot%202014-10-14%2017.18.08.png?dl=0'>
#### Email
<img src='https://dl.dropbox.com/s/a729cxmod0xen2k/Screenshot%202014-10-14%2017.19.49.png?dl=0'>

## Getting Started
Start by creating your rails app:

```
$ rails new email_app
```

Lets create a basic static pages controller:

```
$ rails g controller StaticPages contact mail
```

Next in your `routes.rb` file lets add two basic routes:

```
root 'static_pages#home'
post 'static_pages#mail'
```

For the sake of the app we'll set our homepage to the contact page. The `post 'static_pages#mail'` route will be used to start the background email process.
Next lets create a contact form in `contact.html.erb` under `app/views/static_pages/`:

```erb
<h1>Contact</h1>

<%= form_tag '/mail' do %>
	<div>
		<%= label_tag :name %><br>
		<%= text_field_tag :name %>
	</div>
	
	<div>
		<%= label_tag :email %><br>
		<%= text_field_tag :email %>
	</div>
	
	<div>
		<%= label_tag :message %><br>
		<%= text_area_tag :message %>
	</div>
	
	<%= submit_tag %>
	
<% end %>
```

Great. We've got a contact page, a contact form inside our rails app. We want to take that information in the form and send it in an email to ourselves. We can do this using [ActionMailer](http://guides.rubyonrails.org/action_mailer_basics.html). To get started with ActionMailer we can use a built in generator to generate a mailer:

```
$ rails g mailer DeveloperMailer
``` 

You can name the mailer whatever you would like. It makes the most sense to name it after the emails you intend on sending with it. Thus, if you have a `User` model and you want to send out confirmation emails after they sign up, it makes sense to generate a UsersMailer class. In this example we'll be sending emails to ourselves, the developer. Mailers are stored under `app/mailers/`. Go to your newly created `developer_mailer.rb` and check it out, we've got a DeveloperMailer class. We'll stick some methods in here that we will use in our controller to actually send out emails:

```ruby
class DeveloperMailer < ActionMailer::Base
  default from: "andrew@example.com"
  
  def contact_email(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    mail(to: 'andrewsinner@gmail.com', subject: 'Welcome to My Awesome Site')
  end
end
```

Take a look at the first line:

```ruby
default from: "andrew@example.com"
```

This sets the default address where emails show they are sent from. Next we have an email method in the mailer:

```ruby
def contact_email(params)
  @name = params[:name]
  @email = params[:email]
  @message = params[:message]
  mail(to: 'andrewsinner@gmail.com', subject: 'Welcome to My Awesome Site')
end
```

This is the method that will construct the email that we want to send. We'll come back shortly to this, in the meantime open up your controller. And stick some code in there:

```ruby
class StaticPagesController < ApplicationController
  def contact
  end
  
  def mail
    DeveloperMailer.contact_email(params).deliver
  end
end
```

When we post our contact form to the mail action, the `DeveloperMailer` calls the `contact_email` method and passes in the params. If you go back to the DeveloperMailer method you can see we use the params hash to set some instance variables:

```ruby
class DeveloperMailer < ActionMailer::Base
  default from: "andrew@example.com"
  
  def contact_email(params)
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    mail(to: 'andrewsinner@gmail.com', subject: 'Welcome to My Awesome Site')
  end
end
```

We have three variables:
- @name
- @email
- @message

We can use these in the views for our mailer. ActionMailer can sent html and text emails using views. Lets create some views that will utilize these variables that will get sent as the email. Store your mailer views under `app/views/developer_mailer/`. Create two files in this folder:
- contact_email.html.erb
- contact_email.text.erb
Notice that the first part of the file name is the same as the method name we created in the DeveloperMailer class. Be sure to follow this convention.
In your `contact_email.html.erb` put this:

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1><%= @name %> has contacted you</h1>
    <p>You can contact them back at <%= @email %></p>
    <p>
      This is what they had to say: <%= @message %>
    </p>
  </body>
</html>
```

In your `text.html.erb` put this:


```erb
<%= @name %> has contacted you
You can contact them back at <%= @email %>
This is what they had to say: <%= @message %>
```

You may be asking why we create two different view files. The answer? Some email clients don't serve html. For these clients, Rails knows to send the text version of the email instead.
Now we've got a method to email, views for our emails, and the controller logic to actually send the email. Now we need to configure our app to actually send the email. You can do this by adding some lines to `config/environments/development.rb`. Go ahead and add these lines to the end of your `development.rb`:

```ruby
config.action_mailer.delivery_method = :smtp

config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            ENV['smtp_username'],
  password:             ENV['smtp_password'],
  authentication:       'plain',
  enable_starttls_auto: true  
}
```

Notice `:user_name` and `:password`. These should be the same credentials you use to log in to gmail. Example:

```ruby
user_name: 'your-email-address@gmail.com',
password: 'your-awesome-PaSSw3rd'
```

It makes to not keep these in plain text in this config file, so be sure to set to them as ENV variables that you can reference here instead.
After you've got this in here, restart your server and try out your contact page. You should get an email with the details you entered in the form.

## Background jobs
If you successfully sent an email, you may have noticed that it can take a long time to load. For cases such as this it makes sense to put the work of sending the email in a background process, because its not immediately necessary to the user. This is where (Sidekiq)[https://www.sidekiq.org] comes in. To get started you're going to need to install [Redis](http://redis.io/).

### Installing Redis

You can install Redis through homebrew

```
$ brew install redis
```

See the [Redis docs](http://redis.io/topics/quickstart) for installation without homebrew.
Next start up Redis from the command line:

```
$ redis-server
```

### Installing Sidekiq

Put Sidekiq into your gemfile:

```ruby
gem 'sidekiq'
```

Bundle install after:

```
$ bundle install
```

### Workers
Sidekiq users Worker classes. Create a workers directory `app/workers`. Add a `email_worker.rb` file and type this code in:

```ruby
class EmailWorker
  include Sidekiq::Worker
  
  def perform(params, count)
    params.symbolize_keys!
    DeveloperMailer.contact_email(params).deliver
    puts "Emailed!"
  end
end
```

We have to `include Sidekiq::Worker` at the top of the class. Our worker class must have the perform method that will take in two paramaters:
- params: the params hash from the controller
- count: the priority level of the job

Sidekiq serializes your parameters into JSON, so in order to get the params[:attribute] notation we must symbolize the keys. After that we put it in the task we want the job to do:

```ruby 
DeveloperMailer.contact_email(params).deliver
```

This is the method we currently have placed in the controller. After this we put in a puts statement that we can see in terminal. 
Go and update your controller code to use the actual delayed job:

```ruby
class StaticPagesController < ApplicationController
  def contact
  end
  
  def mail
    EmailWorker.perform_async(params, 5)
  end
end
```

All we have to do now is start up Sidekiq:
*Note: whenever you make changes to your wokers you must restart Sideqik using this command*

```
$ bundle exec sideqik
```

Now if we navigate to the home page and fill out the form, our email delivery will take place in the background leaving us with a fast response from the controller.

