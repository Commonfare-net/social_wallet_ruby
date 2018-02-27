$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yaml'
require 'social_wallet'
require 'pry'

begin
  YAML.load_file('test_env.yml').each { |k, v| ENV[k] = v }
rescue StandardError
  puts 'Cannot run tests. ' \
    'Please be sure there is a file called `test_env.yml`'
  exit
end
