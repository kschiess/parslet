
require 'parslet'

require 'parslet/rig/rspec'
require 'parslet/atoms/visitor'

RSpec.configure do |config|
  config.mock_with :flexmock
end