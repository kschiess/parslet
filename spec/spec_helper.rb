
require 'parslet'

require 'parslet/rig/rspec'
require 'parslet/atoms/visitor'
require 'parslet/export'

RSpec.configure do |config|
  config.mock_with :flexmock
end