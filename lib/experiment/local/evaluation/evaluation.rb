require 'ffi'

module EvaluationInterop
  extend FFI::Library
  host_os = RbConfig::CONFIG['host_os']
  cpu = RbConfig::CONFIG['host_cpu']
  evaluation_dir = "#{Dir.pwd}/lib/experiment/local/evaluation/lib"
  if host_os =~ /darwin|mac os/ && cpu =~ /x86_64/
    ffi_lib ["#{evaluation_dir}/macosX64/releaseShared/libevaluation_interop.dylib"]
  end
  if host_os =~ /darwin|mac os/ && cpu =~ /aarch64/
    ffi_lib ["#{evaluation_dir}/macosArm64/releaseShared/libevaluation_interop.dylib"]
  end
  if host_os =~ /linux/ && cpu =~ /x86_64/
    ffi_lib ["#{evaluation_dir}/linuxX64/releaseShared/libevaluation_interop.so"]
  end
  if host_os =~ /linux/ && cpu =~ /aarch64s/
    ffi_lib ["#{evaluation_dir}/linuxArm64/releaseShared/libevaluation_interop.so"]
  end

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
           :createNullableShort, callback([:pointer], :pointer),
           :createNullableInt, callback([:pointer], :pointer),
           :createNullableLong, callback([:pointer], :pointer),
           :createNullableFloat, callback([:pointer], :pointer),
           :createNullableDouble, callback([:pointer], :pointer),
           :createNullableChar, callback([:pointer], :pointer),
           :createNullableBoolean, callback([:pointer], :pointer),
           :createNullableUnit, callback([], :pointer),
           :kotlin, Kotlin
  end

  attach_function :libevaluation_interop_symbols, [], Libevaluation_interop_ExportedSymbols.by_ref

end

def evaluation(rule_json, user_json)
  lib = EvaluationInterop.libevaluation_interop_symbols()
  fn = lib[:kotlin][:root][:evaluate]
  evaluation_result = fn.call(rule_json, user_json)
  evaluation_result.read_string
end