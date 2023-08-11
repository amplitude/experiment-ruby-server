module AmplitudeAnalytics
  describe 'Utils' do
    describe '.current_milliseconds' do
      it 'returns a positive integer' do
        cur_time = AmplitudeAnalytics.current_milliseconds
        expect(cur_time).to be_an(Integer)
        expect(cur_time).to be > 0
      end
    end

    describe '.truncate_object' do
      it 'truncates long strings in the object' do
        obj = { 'test_key' => 'a' * 2000 }
        truncated_obj = AmplitudeAnalytics.truncate(obj)
        expect(truncated_obj['test_key'].length).to eq(MAX_STRING_LENGTH)
      end

      it 'logs error when object exceeds max key limit' do
        obj = {}
        2000.times { |i| obj[i.to_s] = i }

        expect { AmplitudeAnalytics.truncate(obj) }.to output(/ERROR -- : Too many properties. 1024 maximum.\n/).to_stdout
      end

      it 'truncates strings and dictionaries in a list input' do
        large_dict = {}
        2000.times { |i| large_dict[i.to_s] = i }
        long_string = 'a' * 2000
        obj = [15, 6.6, long_string, large_dict, false]

        expect { AmplitudeAnalytics.truncate(obj) }.to output(/ERROR -- : Too many properties. 1024 maximum.\n/).to_stdout

        expect(obj[0]).to eq(15)
        expect(obj[1]).to eq(6.6)
        expect(obj[2]).to eq(long_string[0, MAX_STRING_LENGTH])
        expect(obj[3]).to be_empty
        expect(obj[4]).to eq(false)
      end
    end
  end
end
