module AmplitudeExperiment::Evaluation
  describe SemanticVersion do
    def assert_invalid_version(version)
      expect(SemanticVersion.parse(version)).to be_nil
    end

    def assert_valid_version(version)
      expect(SemanticVersion.parse(version)).not_to be_nil
    end

    def assert_version_comparison(v1, op, v2)
      sv1 = SemanticVersion.parse(v1)
      sv2 = SemanticVersion.parse(v2)
      expect(sv1).not_to be_nil
      expect(sv2).not_to be_nil
      return if sv1.nil? || sv2.nil?

      case op
      when 'is'
        expect(sv1 <=> sv2).to eq(0)
      when 'is not'
        expect(sv1 <=> sv2).not_to eq(0)
      when 'version less'
        expect(sv1 <=> sv2).to be < 0
      when 'version greater'
        expect(sv1 <=> sv2).to be > 0
      end
    end

    describe 'invalid versions' do
      it 'rejects invalid version formats' do
        # just major
        assert_invalid_version('10')

        # trailing dots
        assert_invalid_version('10.')
        assert_invalid_version('10..')
        assert_invalid_version('10.2.')
        assert_invalid_version('10.2.33.')

        # dots in the middle
        assert_invalid_version('10..2.33')
        assert_invalid_version('102...33')

        # invalid characters
        assert_invalid_version('a.2.3')
        assert_invalid_version('23!')
        assert_invalid_version('23.#5')
        assert_invalid_version('')
        assert_invalid_version(nil)

        # more numbers
        assert_invalid_version('2.3.4.567')
        assert_invalid_version('2.3.4.5.6.7')

        # prerelease if provided should always have major, minor, patch
        assert_invalid_version('10.2.alpha')
        assert_invalid_version('10.alpha')
        assert_invalid_version('alpha-1.2.3')

        # prerelease should be separated by a hyphen after patch
        assert_invalid_version('10.2.3alpha')
        assert_invalid_version('10.2.3alpha-1.2.3')

        # negative numbers
        assert_invalid_version('-10.1')
        assert_invalid_version('10.-1')
      end
    end

    describe 'valid versions' do
      it 'accepts valid version formats' do
        assert_valid_version('100.2')
        assert_valid_version('0.102.39')
        assert_valid_version('0.0.0')

        # versions with leading 0s would be converted to int
        assert_valid_version('01.02')
        assert_valid_version('001.001100.000900')

        # prerelease tags
        assert_valid_version('10.20.30-alpha')
        assert_valid_version('10.20.30-1.x.y')
        assert_valid_version('10.20.30-aslkjd')
        assert_valid_version('10.20.30-b894')
        assert_valid_version('10.20.30-b8c9')
      end
    end

    describe 'version comparison' do
      it 'handles equality comparisons' do
        assert_version_comparison('66.12.23', 'is', '66.12.23')
        # patch if not specified equals 0
        assert_version_comparison('5.6', 'is', '5.6.0')
        # leading 0s are not stored when parsed
        assert_version_comparison('06.007.0008', 'is', '6.7.8')
        # with pre-release
        assert_version_comparison('1.23.4-b-1.x.y', 'is', '1.23.4-b-1.x.y')
      end

      it 'handles inequality comparisons' do
        assert_version_comparison('1.23.4-alpha-1.2', 'is not', '1.23.4-alpha-1')
        # trailing 0s aren't stripped
        assert_version_comparison('1.2.300', 'is not', '1.2.3')
        assert_version_comparison('1.20.3', 'is not', '1.2.3')
      end

      it 'handles less than comparisons' do
        # patch of .1 makes it greater
        assert_version_comparison('50.2', 'version less', '50.2.1')
        # minor 9 < minor 20
        assert_version_comparison('20.9', 'version less', '20.20')
        # same version with pre-release should be lesser
        assert_version_comparison('20.9.4-alpha1', 'version less', '20.9.4')
        # compare prerelease as strings
        assert_version_comparison('20.9.4-a-1.2.3', 'version less', '20.9.4-a-1.3')
        # since prerelease is compared as strings a1.23 < a1.5 because 2 < 5
        assert_version_comparison('20.9.4-a1.23', 'version less', '20.9.4-a1.5')
      end

      it 'handles greater than comparisons' do
        assert_version_comparison('12.30.2', 'version greater', '12.4.1')
        # 100 > 1
        assert_version_comparison('7.100', 'version greater', '7.1')
        # 10 > 9
        assert_version_comparison('7.10', 'version greater', '7.9')
        # converts to 7.10.20 > 7.9.1
        assert_version_comparison('07.010.0020', 'version greater', '7.009.1')
        # patch comparison comes first
        assert_version_comparison('20.5.6-b1.2.x', 'version greater', '20.5.5')
      end
    end
  end
end
