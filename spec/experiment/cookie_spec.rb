require 'spec_helper'

module Experiment
  describe AmplitudeCookie do
    describe '#cookie_name' do
      it 'test invalid api key throw error' do
        expect { AmplitudeCookie.cookie_name('') }.to raise_error(ArgumentError)
      end

      it 'test valid api key return cookie name' do
        expect(AmplitudeCookie.cookie_name('1234567')).to eq('amp_123456')
      end
    end

    describe '#parse' do
      it 'test parse cookie with device id only' do
        user = AmplitudeCookie.parse('deviceId...1f1gkeib1.1f1gkeib1.dv.1ir.20q')
        expect(user.device_id).to eq('deviceId')
        expect(user.user_id).to be_nil
      end

      it 'test parse cookie with device id and user id' do
        user = AmplitudeCookie.parse('deviceId.dGVzdEBhbXBsaXR1ZGUuY29t..1f1gkeib1.1f1gkeib1.dv.1ir.20q')
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
      end
    end

    describe '#generate' do
      it 'test generate' do
        result = AmplitudeCookie.generate('deviceId')
        expect(result).to eq('deviceId..........')
      end
    end
  end
end
