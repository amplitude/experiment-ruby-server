# frozen_string_literal: true

# Implements 32-bit x86 MurmurHash3
module AmplitudeExperiment
  module Evaluation
    class Murmur3
      C1_32 = -0x3361d2af
      C2_32 = 0x1b873593
      R1_32 = 15
      R2_32 = 13
      M_32 = 5
      N_32 = -0x19ab949c

      class << self
        def hash32x86(input, seed = 0)
          data = string_to_utf8_bytes(input)
          length = data.length
          n_blocks = length >> 2
          hash = seed

          # Process body
          n_blocks.times do |i|
            index = i << 2
            k = read_int_le(data, index)
            hash = mix32(k, hash)
          end

          # Process tail
          index = n_blocks << 2
          k1 = 0

          case length - index
          when 3
            k1 ^= data[index + 2] << 16
            k1 ^= data[index + 1] << 8
            k1 ^= data[index]
            k1 = (k1 * C1_32) & 0xffffffff
            k1 = rotate_left(k1, R1_32)
            k1 = (k1 * C2_32) & 0xffffffff
            hash ^= k1
          when 2
            k1 ^= data[index + 1] << 8
            k1 ^= data[index]
            k1 = (k1 * C1_32) & 0xffffffff
            k1 = rotate_left(k1, R1_32)
            k1 = (k1 * C2_32) & 0xffffffff
            hash ^= k1
          when 1
            k1 ^= data[index]
            k1 = (k1 * C1_32) & 0xffffffff
            k1 = rotate_left(k1, R1_32)
            k1 = (k1 * C2_32) & 0xffffffff
            hash ^= k1
          end

          hash ^= length
          fmix32(hash) & 0xffffffff
        end

        private

        def mix32(k, hash)
          k = (k * C1_32) & 0xffffffff
          k = rotate_left(k, R1_32)
          k = (k * C2_32) & 0xffffffff
          hash ^= k
          hash = rotate_left(hash, R2_32)
          ((hash * M_32) + N_32) & 0xffffffff
        end

        def fmix32(hash)
          hash ^= hash >> 16
          hash = (hash * -0x7a143595) & 0xffffffff
          hash ^= hash >> 13
          hash = (hash * -0x3d4d51cb) & 0xffffffff
          hash ^= hash >> 16
          hash
        end

        def rotate_left(x, n, width = 32)
          n %= width if n > width
          mask = (0xffffffff << (width - n)) & 0xffffffff
          r = ((x & mask) >> (width - n)) & 0xffffffff
          ((x << n) | r) & 0xffffffff
        end

        def read_int_le(data, index = 0)
          n = (data[index] << 24) |
              (data[index + 1] << 16) |
              (data[index + 2] << 8) |
              data[index + 3]
          reverse_bytes(n)
        end

        def reverse_bytes(n)
          ((n & -0x1000000) >> 24) |
            ((n & 0x00ff0000) >> 8) |
            ((n & 0x0000ff00) << 8) |
            ((n & 0x000000ff) << 24)
        end

        def string_to_utf8_bytes(str)
          str.encode('UTF-8').bytes
        end
      end
    end
  end
end
