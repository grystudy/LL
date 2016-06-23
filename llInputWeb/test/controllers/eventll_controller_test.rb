require 'test_helper'

class EventllControllerTest < ActionDispatch::IntegrationTest
  test "should get main" do
    get eventll_main_url
    assert_response :success
  end

end
