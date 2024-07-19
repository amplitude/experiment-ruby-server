require 'json'
module AmplitudeExperiment
  def self.evaluation_variants_json_to_variants(variants_json)
    variants = {}
    variants_json.each do |key, value|
      variants[key] = AmplitudeExperiment.evaluation_variant_json_to_variant(value)
    end
    variants
  end

  def self.evaluation_variant_json_to_variant(variant_json)
    value = variant_json['value']
    value = value.to_json if value && !value.is_a?(String)
    Variant.new(
      value: value,
      key: variant_json['key'],
      payload: variant_json['payload'],
      metadata: variant_json['metadata']
    )
  end
end

