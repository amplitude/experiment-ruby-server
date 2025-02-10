# frozen_string_literal: true

RSpec.describe TopologicalSort do
  def create_flag(key, dependencies = nil)
    Evaluation::Flag.from_hash({
                                 'key' => key.to_s,
                                 'variants' => {},
                                 'segments' => [],
                                 'dependencies' => dependencies&.map(&:to_s)
                               })
  end

  describe '.sort' do
    it 'handles empty flag list' do
      expect(TopologicalSort.sort({})).to eq([])
      expect(TopologicalSort.sort({}, ['1'])).to eq([])
    end

    it 'handles single flag without dependencies' do
      flags = { '1' => create_flag(1) }
      expect(TopologicalSort.sort(flags)).to eq([create_flag(1)])
      expect(TopologicalSort.sort(flags, ['1'])).to eq([create_flag(1)])
      expect(TopologicalSort.sort(flags, ['999'])).to eq([])
    end

    it 'handles single flag with dependencies' do
      flags = { '1' => create_flag(1, [2]) }
      expect(TopologicalSort.sort(flags)).to eq([create_flag(1, [2])])
      expect(TopologicalSort.sort(flags, ['1'])).to eq([create_flag(1, [2])])
      expect(TopologicalSort.sort(flags, ['999'])).to eq([])
    end

    it 'handles multiple flags without dependencies' do
      flags = {
        '1' => create_flag(1),
        '2' => create_flag(2)
      }
      expect(TopologicalSort.sort(flags)).to eq([create_flag(1), create_flag(2)])
      expect(TopologicalSort.sort(flags, %w[1 2])).to eq([create_flag(1), create_flag(2)])
      expect(TopologicalSort.sort(flags, %w[99 999])).to eq([])
    end

    it 'handles multiple flags with dependencies' do
      flags = {
        '1' => create_flag(1, [2]),
        '2' => create_flag(2, [3]),
        '3' => create_flag(3)
      }
      expected = [create_flag(3), create_flag(2, [3]), create_flag(1, [2])]
      expect(TopologicalSort.sort(flags)).to eq(expected)
      expect(TopologicalSort.sort(flags, %w[1 2])).to eq(expected)
      expect(TopologicalSort.sort(flags, %w[99 999])).to eq([])
    end

    it 'detects single flag cycle' do
      flags = { '1' => create_flag(1, [1]) }
      expect { TopologicalSort.sort(flags) }.to raise_error(CycleError) { |e| expect(e.path).to eq ['1'] }
      expect { TopologicalSort.sort(flags, ['1']) }.to raise_error(CycleError) { |e| expect(e.path).to eq ['1'] }
      expect { TopologicalSort.sort(flags, ['999']) }.not_to raise_error
    end

    it 'detects cycles between two flags' do
      flags = {
        '1' => create_flag(1, [2]),
        '2' => create_flag(2, [1])
      }
      expect { TopologicalSort.sort(flags) }.to raise_error(CycleError) { |e| expect(e.path).to eq %w[1 2] }
      expect { TopologicalSort.sort(flags, ['2']) }.to raise_error(CycleError) { |e| expect(e.path).to eq %w[2 1] }
      expect { TopologicalSort.sort(flags, ['999']) }.not_to raise_error
    end

    it 'handles complex dependencies without cycles' do
      flags = {
        '8' => create_flag(8),
        '7' => create_flag(7, [8]),
        '4' => create_flag(4, [8, 7]),
        '6' => create_flag(6, [7, 4]),
        '3' => create_flag(3, [6]),
        '1' => create_flag(1, [3]),
        '2' => create_flag(2, [1])
      }

      expected = [
        create_flag(8),
        create_flag(7, [8]),
        create_flag(4, [8, 7]),
        create_flag(6, [7, 4]),
        create_flag(3, [6]),
        create_flag(1, [3]),
        create_flag(2, [1])
      ]

      expect(TopologicalSort.sort(flags)).to eq(expected)
    end
  end
end
