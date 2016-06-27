require 'test_helper'

class LldetailControllerTest < ActionDispatch::IntegrationTest
  test "should get main" do
    get lldetail_main_url
    assert_response :success
  end

end
