require File.dirname(__FILE__) + '/spec_helper'

describe "facebook strategy" do
  it "should confirm authentication for oauth user with a match" do
    email = "random@random.test"
    uuid = 40
    provider = :facebook

    add_user(email, provider => uuid)
    set_omniauth(:uuid => uuid, :provider => provider)

    app.any_instance.should_receive(:establish_session!).with(email, nil)
    get "/auth/facebook/callback"
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should =~ /\/login$/
  end

  describe "redirect oauth user without a match" do

    let(:redirect_url){ config["strategy"]["facebook"]["redirect_new"].gsub(/^[a-z]+:\/\//, "https://") }

    before :each do
      email = "unknown@random.test"
      uuid = 50
      provider = :facebook

      set_omniauth(:uuid => uuid, :provider => provider)

      app.any_instance.should_not_receive(:establish_session!)
      get "/auth/facebook/callback"
      last_response.should be_redirect
      follow_redirect!
    end

    it "should redirect to an url from config" do
      last_request.url.should =~ /^#{redirect_url}\?/
    end

    it "enforces https" do
      last_request.url.should =~ /^https:\/\//
    end

    describe "oauth data forwarding" do
      # TODO: Check with addressable?
      it "should send `uid` param" do
        last_request.url.should =~ /^#{redirect_url}\?.*uid=/
      end

      it "should send `provider` param" do
        last_request.url.should =~ /^#{redirect_url}\?.*provider=facebook/
      end

      it "should send `info` param" do
        last_request.url.should =~ /^#{redirect_url}\?.*info=/
      end

      it "should send `credentials` param" do
        last_request.url.should =~ /^#{redirect_url}\?.*credentials=/
      end

    end
  end

  describe "invalid onmiauth" do
    it "doesn't accept the route if it's not for facebook" do
      get '/auth/failure?strategy=not_facebook'
      last_response.should_not be_ok
    end

    describe "redirects to login page" do
      before :each do
        CASServer::Mock.any_instance.should_receive(:session).twice.and_return({:service => 'servicemane', :renew => 'true'})
        get '/auth/failure?strategy=facebook&message=something'
        last_response.should be_redirect
        follow_redirect!
      end
      
      it do
        last_request.url.should =~ /\/login/
      end

      it "preserves service data" do
        last_request.url.should =~ /\?.*service=servicemane/
      end

      it "preserves renew data" do
        last_request.url.should =~ /\?.*renew=true/
      end

      it "sends oauth error to login page" do
        last_request.url.should =~ /\?.*oauth_error=something/
      end

      it "sends oauth strategy name to login page" do
        last_request.url.should =~ /\?.*oauth_strategy=facebook/
      end
    end

  end
end
