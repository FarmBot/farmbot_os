require 'test_helper'
require './lib/database/dbaccess.rb'

class TestCredentials < Minitest::Test

  #TIM: You can use a `let` statement in a similar fashion to the `setup` method
  # It will allow you to access `db` inside of your tests, but only if it is
  # needed (it is lazy loaded). This will make your tests slightly faster. It
  # does not always work because sometimes you need to eager load. In those
  # cases, just use `def setup` or `let!`.
  attr_reader :db
  def setup
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  def test_dbaccess_increment_parameters_versoin
    param_name = 'PARAM_VERSION'
    db.write_parameter(param_name, 1)
    db.increment_parameters_version
    return_val = db.read_parameter(param_name)
    assert_equal return_val, 2
  end

  def test_something
    assert(true,"this should be true")
  end

  def test_create_credentials_test_test
    assert_equal true, true
  end

end
