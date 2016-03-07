require 'active_record'

class User < ActiveRecord::Base
  
  def to_json(x)
    return { email: email, name: name, age: age }.to_json
  end
end