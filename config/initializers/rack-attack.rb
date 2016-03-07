# In config/initializers/rack-attack.rb
class Rack::Attack
  
  # Always allow requests from localhost
  # (blacklist & throttles are skipped)
  whitelist('allow from localhost') do |req|
     #Requests are allowed if the return value is truthy
    '127.0.0.1' == req.ip
  end

  whitelist('allow unlimited requests from API users') do |req|
  	#Unlimited requests allowed if user has a valid API key
  	if req.params['authentication_token'].present?
      User.find_by_authentication_token(req.params['authentication_token']).has_role?(Role.researcher) ||
      User.find_by_authentication_token(req.params['authentication_token']).has_role?(Role.submitter)
    elsif req.env.key?("HTTP_AUTHENTICATION_TOKEN")
      User.find_by_authentication_token(req.env["HTTP_AUTHENTICATION_TOKEN"]).has_role?(Role.researcher) ||
      User.find_by_authentication_token(req.env["HTTP_AUTHENTICATION_TOKEN"]).has_role?(Role.submitter)
    end
  end

  throttle('api limit', :limit => 5, :period => 24.hours ) do |req|
    req.ip if req.env["CONTENT_TYPE"] == "application/json"
  end

  throttle('req/ip', :limit => 200, :period => 5.minutes) do |req|
  	req.ip
  end

  self.throttled_response = lambda do |env|
    [ 429,  # status
      { 'Content-Type' => 'text/html' },   # headers
      ['Oops, you were browsing a little faster than we can keep up with. Please wait a minute and try your request again. Please <a href="https://lumendatabase.org/pages/researchers#key">request a research account key</a> if you need to make more requests than our limit.']] # body
  end
end