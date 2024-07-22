module AmplitudeExperiment
  RSpec.describe 'TopologicalSort' do
    def sort(flags, flag_keys = nil)
      flag_keys_strings = flag_keys ? flag_keys.map(&:to_s) : []
      flags_dict = flags.each_with_object({}) do |flag, hash|
        hash[flag["key"]] = flag
      end
      AmplitudeExperiment.topological_sort(flags_dict, flag_keys_strings, true)
    end

    def flag(key, dependencies)
      { "key" => key.to_s, "dependencies" => dependencies.map(&:to_s) }
    end

    it 'handles empty flags' do
      flags = []
      # no flag keys
      result = sort(flags)
      expect(result).to eq([])
      # with flag keys
      result = sort(flags, [1])
      expect(result).to eq([])
    end

    it 'handles single flag with no dependencies' do
      flags = [flag(1, [])]
      # no flag keys
      result = sort(flags)
      expect(result).to eq(flags)
      # with flag keys
      result = sort(flags, [1])
      expect(result).to eq(flags)
      # with flag keys, no match
      result = sort(flags, [999])
      expect(result).to eq([])
    end

    it 'handles single flag with dependencies' do
      flags = [flag(1, [2])]
      # no flag keys
      result = sort(flags)
      expect(result).to eq(flags)
      # with flag keys
      result = sort(flags, [1])
      expect(result).to eq(flags)
      # with flag keys, no match
      result = sort(flags, [999])
      expect(result).to eq([])
    end

    it 'handles multiple flags with no dependencies' do
      flags = [flag(1, []), flag(2, [])]
      # no flag keys
      result = sort(flags)
      expect(result).to eq(flags)
      # with flag keys
      result = sort(flags, [1, 2])
      expect(result).to eq(flags)
      # with flag keys, no match
      result = sort(flags, [99, 999])
      expect(result).to eq([])
    end

    it 'handles multiple flags with dependencies' do
      flags = [flag(1, [2]), flag(2, [3]), flag(3, [])]
      # no flag keys
      result = sort(flags)
      expect(result).to eq([flag(3, []), flag(2, [3]), flag(1, [2])])
      # with flag keys
      result = sort(flags, [1, 2])
      expect(result).to eq([flag(3, []), flag(2, [3]), flag(1, [2])])
      # with flag keys, no match
      result = sort(flags, [99, 999])
      expect(result).to eq([])
    end

    it 'handles single flag cycle' do
      flags = [flag(1, [1])]
      # no flag keys
      expect {
        sort(flags)
      }.to raise_error(CycleError) { |e| expect(e.path).to eq(['1'].to_set) }
      # with flag keys
      expect {
        sort(flags, [1])
      }.to raise_error(CycleError) { |e| expect(e.path).to eq(['1'].to_set) }
      # with flag keys, no match
      expect {
        result = sort(flags, [999])
        expect(result).to eq([])
      }.not_to raise_error
    end

    it 'handles two flag cycle' do
      flags = [flag(1, [2]), flag(2, [1])]
      # no flag keys
      expect {
        sort(flags)
      }.to raise_error(CycleError) { |e| expect(e.path).to eq(%w[1 2].to_set) }
      # with flag keys
      expect {
        sort(flags, [1, 2])
      }.to raise_error(CycleError) { |e| expect(e.path).to eq(%w[1 2].to_set) }
      # with flag keys, no match
      expect {
        result = sort(flags, [999])
        expect(result).to eq([])
      }.not_to raise_error
    end

    it 'handles multiple flags with complex cycle' do
      flags = [
        flag(3, [1, 2]),
        flag(1, []),
        flag(4, [21, 3]),
        flag(2, []),
        flag(5, [3]),
        flag(6, []),
        flag(7, []),
        flag(8, [9]),
        flag(9, []),
        flag(20, [4]),
        flag(21, [20])
      ]
      expect {
        sort(flags, [3, 1, 4, 2, 5, 6, 7, 8, 9, 20, 21])
      }.to raise_error(CycleError) { |e| expect(e.path).to eq(['4', '21', '20'].to_set) }
    end

    it 'handles multiple flags with complex dependencies without cycle starting at leaf' do
      flags = [
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(7, [8]),
        flag(6, [7, 4]),
        flag(8, []),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      result = sort(flags, [1, 2, 3, 4, 5, 7, 6, 8, 9, 10, 20, 21, 30])
      expected = [
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(6, [7, 4]),
        flag(7, [8]),
        flag(8, []),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      expect(result.sort_by { |f| f['key'] }).to eq(expected.sort_by { |f| f['key'] })
    end

    it 'handles multiple flags with complex dependencies without cycle starting at middle' do
      flags = [
        flag(6, [7, 4]),
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(7, [8]),
        flag(8, []),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      result = sort(flags, [6, 1, 2, 3, 4, 5, 7, 8, 9, 10, 20, 21, 30])
      expected = [
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(6, [7, 4]),
        flag(7, [8]),
        flag(8, []),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      expect(result.sort_by { |f| f['key'] }).to eq(expected.sort_by { |f| f['key'] })
    end

    it 'handles multiple flags with complex dependencies without cycle starting at root' do
      flags = [
        flag(8, []),
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(6, [7, 4]),
        flag(7, [8]),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      result = sort(flags, [8, 1, 2, 3, 4, 5, 6, 7, 9, 10, 20, 21, 30])
      expected = [
        flag(1, [6, 3]),
        flag(2, [8, 5, 3, 1]),
        flag(3, [6, 5]),
        flag(4, [8, 7]),
        flag(5, [10, 7]),
        flag(6, [7, 4]),
        flag(7, [8]),
        flag(8, []),
        flag(9, [10, 7, 5]),
        flag(10, [7]),
        flag(20, []),
        flag(21, [20]),
        flag(30, [])
      ]
      expect(result.sort_by { |f| f['key'] }).to eq(expected.sort_by { |f| f['key'] })
    end
  end
end

