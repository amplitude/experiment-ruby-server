# frozen_string_literal: true

module AmplitudeAnalytics
  # Selects a value from a nested object using an array of selector keys
  module Evaluation
    def self.select(selectable, selector)
      return nil if selector.nil? || selector.empty?

      selector.each do |selector_element|
        return nil if selector_element.nil? || selectable.nil?

        selectable = selectable[selector_element]
      end

      selectable.nil? ? nil : selectable
    end
  end
end
