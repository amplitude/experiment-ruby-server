# frozen_string_literal: true

module AmplitudeExperiment
  module Evaluation
    class SemanticVersion
      include Comparable

      attr_reader :major, :minor, :patch, :pre_release

      MAJOR_MINOR_REGEX = '(\d+)\.(\d+)'
      PATCH_REGEX = '(\d+)'
      PRERELEASE_REGEX = '(-(([-\w]+\.?)*))?'
      VERSION_PATTERN = /^#{MAJOR_MINOR_REGEX}(\.#{PATCH_REGEX}#{PRERELEASE_REGEX})?$/.freeze

      def initialize(major, minor, patch, pre_release = nil)
        @major = major
        @minor = minor
        @patch = patch
        @pre_release = pre_release
      end

      def self.parse(version)
        return nil if version.nil?

        match = VERSION_PATTERN.match(version)
        return nil unless match

        major = match[1].to_i
        minor = match[2].to_i
        patch = match[4]&.to_i || 0
        pre_release = match[5]

        new(major, minor, patch, pre_release)
      end

      def <=>(other)
        return nil unless other.is_a?(SemanticVersion)

        result = major <=> other.major
        return result unless result.zero?

        result = minor <=> other.minor
        return result unless result.zero?

        result = patch <=> other.patch
        return result unless result.zero?

        return 1 if !pre_release && other.pre_release
        return -1 if pre_release && !other.pre_release
        return 0 if !pre_release && !other.pre_release

        pre_release <=> other.pre_release
      end
    end
  end
end
