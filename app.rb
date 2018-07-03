require 'securerandom'
require 'sinatra'
require 'recurly'
require 'dotenv'
require 'logger'

$LOG = Logger.new(STDOUT)

Dotenv.load

Recurly.subdomain = ENV['RECURLY_SUBDOMAIN']
Recurly.api_key = ENV['RECURLY_PRIVATE_KEY']

set :port, ENV['PORT']
set :public_folder, 'public'

enable :static

post '/subscriptions/new' do


purchase = Recurly::Purchase.new({
  currency: 'USD',
  collection_method: :automatic,
  account: {
    account_code: SecureRandom.uuid,
    billing_info: { token_id: params['recurly-token'] },
  },
  subscriptions: [
    {
      plan_code: "gold",
    }
  ]
})
"subscription has been created"
begin
  collection = Recurly::Purchase.invoice!(purchase)
  puts collection.inspect
rescue Recurly::Resource::Invalid => e
  puts e.inspect
  # Invalid data
rescue Recurly::Transaction::Error => e
  puts e.inspect
  # Transaction error
  # e.transaction
  # e.transaction_error_code
end


end

post '/accounts/new' do
  begin
    Recurly::Account.create!({
      account_code: SecureRandom.uuid,
      billing_info: { token_id: params['recurly-token'] }
    })

    "Account created"
  rescue Recurly::Resource::Invalid, Recurly::API::ResponseError => e
    $LOG.error "#{e.message}"
  end
end

put '/accounts/:account_code' do
  begin
    account = Recurly::Account.find params[:account_code]
    account.billing_info.token_id = params['recurly-token']
    account.billing_info.save!

    "Account updated"
  rescue Recurly::Resource::Invalid, Recurly::API::ResponseError => e
    $LOG.error "#{e.message}"
  end
end

get '/config.js' do
  content_type :js
  "window.recurlyPublicKey = '#{ENV['RECURLY_PUBLIC_KEY']}'"
end

get '/fs' do
  Dir["./public/*"].join "\n"
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

get '/success.html' do
  send_file File.join(settings.public_folder, 'success.html')
end

