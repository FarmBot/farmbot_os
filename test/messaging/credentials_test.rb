require 'test_helper'
require 'test/unit'
#require 'rake/testtask'
#require 'lib/database/dbaccess.rb'
require './lib/database/dbaccess.rb'

class TestCredentials < Minitest::Test
  def setup
    @db = DbAccess.new('test')
  end

  def teardown
  end


  def test_dbaccess_increment_parameters_versoin
    param_name = 'PARAM_VERSION'
    write_parameter(param_name, 1)
    @db.increment_parameters_version
    return_val = read_parameter(param_name)
    assert_equal return_val, 2
  end

  def test_something
#    assert(false,"this should be true")
    assert_response :success
  end

  def test_create_credentials_test_test
    assert_equal true, false
  end

end
