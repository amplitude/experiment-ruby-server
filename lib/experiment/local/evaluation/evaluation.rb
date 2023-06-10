# rubocop:disable all
require 'ffi'
require 'json'

# The evaluation wrapper
module EvaluationInterop
  extend FFI::Library
  host_os = RbConfig::CONFIG['host_os']
  cpu = RbConfig::CONFIG['host_cpu']
  evaluation_dir = File.dirname(__FILE__)
  ffi_lib ["#{evaluation_dir}/lib/macosX64/libevaluation_interop.dylib"] if host_os =~ /darwin|mac os/ && cpu =~ /x86_64/
  ffi_lib ["#{evaluation_dir}/lib/macosArm64/libevaluation_interop.dylib"] if host_os =~ /darwin|mac os/ && cpu =~ /arm64/
  ffi_lib ["#{evaluation_dir}/lib/linuxX64/libevaluation_interop.so"] if host_os =~ /linux/ && cpu =~ /x86_64/
  ffi_lib ["#{evaluation_dir}/lib/linuxArm64/libevaluation_interop.so"] if host_os =~ /linux/ && cpu =~ /arm64|aarch64/

  class Root < FFI::Struct
    layout :evaluate, callback([:string, :string], :pointer)
  end

  class Kotlin < FFI::Struct
    layout :root, Root
  end

  class Libevaluation_interop_ExportedSymbols < FFI::Struct
    layout :DisposeStablePointer, callback([:pointer], :void),
           :DisposeString, callback([:string], :void),
           :IsInstance, callback([:pointer, :string], :pointer),
           :createNullableByte, callback([:string], :pointer),
           :getNonNullValueOfByte, callback([:pointer], :pointer),
           :createNullableShort, callback([:pointer], :pointer),
           :getNonNullValueOfShort, callback([:pointer], :pointer),
           :createNullableInt, callback([:pointer], :pointer),
           :getNonNullValueOfInt, callback([:pointer], :pointer),
           :createNullableLong, callback([:pointer], :pointer),
           :getNonNullValueOfLong, callback([:pointer], :pointer),
           :createNullableFloat, callback([:pointer], :pointer),
           :getNonNullValueOfFloat, callback([:pointer], :pointer),
           :createNullableDouble, callback([:pointer], :pointer),
           :getNonNullValueOfDouble, callback([:pointer], :pointer),
           :createNullableChar, callback([:pointer], :pointer),
           :getNonNullValueOfChar, callback([:pointer], :pointer),
           :createNullableBoolean, callback([:pointer], :pointer),
           :getNonNullValueOfBoolean, callback([:pointer], :pointer),
           :createNullableUnit, callback([], :pointer),
           :createNullableUByte, callback([:pointer], :pointer),
           :getNonNullValueOfUByte, callback([:pointer], :pointer),
           :createNullableUShort, callback([:pointer], :pointer),
           :getNonNullValueOfUShort, callback([:pointer], :pointer),
           :createNullableUInt, callback([:pointer], :pointer),
           :getNonNullValueOfUInt, callback([:pointer], :pointer),
           :createNullableULong, callback([:pointer], :pointer),
           :getNonNullValueOfULong, callback([:pointer], :pointer),

           :kotlin, Kotlin
  end

  attach_function :libevaluation_interop_symbols, [], Libevaluation_interop_ExportedSymbols.by_ref
end

def evaluation(rule_json, user_json)
  lib = EvaluationInterop.libevaluation_interop_symbols()
  fn = lib[:kotlin][:root][:evaluate]
  result_json = fn.call(rule_json, user_json).read_string
  result = JSON.parse(result_json)
  if result["error"] != nil
    raise "#{result["error"]}"
  elsif result["result"] == nil
    raise "Evaluation result is nil."
  end
  result["result"]
end
# rubocop:disable all
