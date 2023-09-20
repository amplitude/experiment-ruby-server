require 'spec_helper'

module AmplitudeExperiment
  describe AmplitudeCookie do
    before(:each) do
      @user_and_device_new_cookie = 'JTdCJTIydXNlcklkJTIyJTNBJTIydGVzdCU0MGFtcGxpdHVkZS5jb20lMjIlMkMlMjJkZXZpY2VJZCUyMiUzQSUyMmRldmljZUlkJTIyJTdE'
      @device_new_cookie = 'JTdCJTIyZGV2aWNlSWQlMjIlM0ElMjJkZXZpY2VJZCUyMiU3RA=='
    end

    describe '#cookie_name' do
      it 'test invalid api key throw error' do
        expect { AmplitudeCookie.cookie_name('') }.to raise_error(ArgumentError)
      end

      it 'test valid api key return cookie name' do
        expect(AmplitudeCookie.cookie_name('1234567')).to eq('amp_123456')
        expect(AmplitudeCookie.cookie_name('1234567890', new: true)).to eq('AMP_1234567890')
      end
    end

    describe '#parse' do
      it 'test parse cookie with device id only' do
        user = AmplitudeCookie.parse('deviceId...1f1gkeib1.1f1gkeib1.dv.1ir.20q')
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to be_nil
        user = AmplitudeCookie.parse(@device_new_cookie, new: true)
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to be_nil
      end

      it 'test parse cookie with device id and user id' do
        user = AmplitudeCookie.parse('deviceId.dGVzdEBhbXBsaXR1ZGUuY29t..1f1gkeib1.1f1gkeib1.dv.1ir.20q')
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to eq('test@amplitude.com')
        user = AmplitudeCookie.parse(@user_and_device_new_cookie, new: true)
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to eq('test@amplitude.com')
      end

      it 'test parse cookie with device id and utf user id' do
        user = AmplitudeCookie.parse('deviceId.Y8O3Pg==..1f1gkeib1.1f1gkeib1.dv.1ir.20q')
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to eq('c÷>')
      end

      it 'test parse cookie decode raise error' do
        allow(Base64).to receive(:decode64).and_raise('boom')
        user = AmplitudeCookie.parse('deviceId.Y8O3Pg==..1f1gkeib1.1f1gkeib1.dv.1ir.20q')
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to be_nil
        user = AmplitudeCookie.parse(@user_and_device_new_cookie, new: true)
        expect(user.device_id).to be_nil
        expect(user.user_id).to be_nil
      end
    end

    describe '#generate' do
      it 'test generate' do
        old = AmplitudeCookie.generate('deviceId')
        expect(old).to eq('deviceId..........')
        new = AmplitudeCookie.generate('deviceId', new: true)
        expect(new).to eq(@device_new_cookie)
      end
    end
  end
end
