require File.dirname(__FILE__) + '/spec_helper'

describe "facebook matcher behaviour" do
  it "should provide `/auth/facebook/callback` get path" do
    email = "random@random.test"
    uuid = 40
    provider = :facebook

    add_user(email, provider => uuid)
    set_omniauth(:uuid => 40, :provider => provider)
    
    app.any_instance.should_receive(:confirm_authentication!).with(email, nil)
    get "/auth/facebook/callback"
    File.open("/home/slotos/Desktop/lol.html",'w'){|f| f.write last_response.body}
  end
end
