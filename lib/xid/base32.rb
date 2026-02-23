
class Xid::Base32

  # 0123456789abcdefghijklmnopqrstuv - Used for encoding
  ENCODE_HEX = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v"].freeze
  DECODE_HEX_MAP = Hash[ENCODE_HEX.each_with_index.map { |x, i| [x, i] }].freeze
  TRIM_LEN = 20

  # Start class methods
  class << self

    def b32encode(src)
      encode(src)
    end

    def b32decode(src)
      decode(src, ENCODE_HEX)
    end

    def encode(id)
      # Convert to byte array if binary string
      id = id.bytes if id.is_a?(String)

      # Build string directly instead of array + join
      dst = String.new(capacity: 20)
      dst << ENCODE_HEX[id[0] >> 3]
      dst << ENCODE_HEX[(id[0] << 2) & 0x1f | (id[1] >> 6) & 0x1f]
      dst << ENCODE_HEX[(id[1] >> 1) & 0x1f]
      dst << ENCODE_HEX[(id[1] << 4) & 0x1f | (id[2] >> 4) & 0x1f]
      dst << ENCODE_HEX[(id[2] << 1) & 0x1f | id[3] >> 7]
      dst << ENCODE_HEX[(id[3] >> 2) & 0x1f]
      dst << ENCODE_HEX[(id[3] << 3) & 0x1f | id[4] >> 5]
      dst << ENCODE_HEX[id[4] & 0x1f]
      dst << ENCODE_HEX[id[5] >> 3]
      dst << ENCODE_HEX[(id[5] << 2) & 0x1f | (id[6] >> 6) & 0x1f]
      dst << ENCODE_HEX[(id[6] >> 1) & 0x1f]
      dst << ENCODE_HEX[(id[6] << 4) & 0x1f | (id[7] >> 4) & 0x1f]
      dst << ENCODE_HEX[(id[7] << 1) & 0x1f | id[8] >> 7]
      dst << ENCODE_HEX[(id[8] >> 2) & 0x1f]
      dst << ENCODE_HEX[(id[8] << 3) & 0x1f | (id[9] >> 5)]
      dst << ENCODE_HEX[id[9] & 0x1f]
      dst << ENCODE_HEX[id[10] >> 3]
      dst << ENCODE_HEX[(id[10] << 2) & 0x1f | (id[11] >> 6) & 0x1f]
      dst << ENCODE_HEX[(id[11] >> 1) & 0x1f]
      dst << ENCODE_HEX[(id[11] << 4) & 0x1f]

      dst.freeze
    end

    def decode(src, str_map)
      src = src.downcase

      end_loop = false
      result = []
      while src && !src.empty? && !end_loop
        dst = [0] * 5
        dbuf = [0] * 8
        src_len = 8

        (0..8).each do |i|
          if i >= src.length
            src_len = i
            end_loop = true
            break
          end
          char = src[i]
          dbuf[i] = DECODE_HEX_MAP[char]
        end

        if src_len >= 8
          dst[4] = (dbuf[6] << 5) | (dbuf[7])
        end
        if src_len >= 7
          dst[3] = (dbuf[4] << 7) | (dbuf[5] << 2) | (dbuf[6] >> 3)
        end
        if src_len >= 5
          dst[2] = (dbuf[3] << 4) | (dbuf[4] >> 1)
        end
        if src_len >= 4
          dst[1] = (dbuf[1] << 6) | (dbuf[2] << 1) | (dbuf[3] >> 4)
        end
        if src_len >= 2
          dst[0] = (dbuf[0] << 3) | (dbuf[1] >> 2)
        end

        dst = dst.map { |x| x & 0xff }

        if src_len == 2
          dst = dst[0]
        elsif src_len == 4
          dst = dst[0..1]
        elsif src_len == 5
          dst = dst[0..2]
        elsif src_len == 7
          dst = dst[0..3]
        elsif src_len == 8
          dst = dst[0..4]
        end

        result += dst
        src = src[8..src.length]
      end

      result
    end
  end
  # END - Class methods
end
