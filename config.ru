require './app'
run Sinatra::Application

Mail.defaults do
  delivery_method :smtp, {
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :domain => 'localhost:9393',
    :user_name => 'postmaster@sandbox8797a6b096ab495b88abd8e0efadbc58.mailgun.org',
    :password =>  '9btfa-ts01c2',
    :authentication => 'plain',
    :enable_starttls_auto => true
  }
end