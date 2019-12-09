
class Xid::Base32
  
  ENCODE_HEX = '0123456789abcdefghijklmnopqrstuv'.freeze
  PAD_CHAR = '='.freeze

  # Start class methods
  class << self

    def decode_hex_map
      Hash[ENCODE_HEX.chars.each_with_index.map { |x, i| [x, i] }]
    end

    def b32encode(src)
      src = src.chars.map(&:ord)
      encode(src, ENCODE_HEX)
    end

    def b32decode(src)
      decode(src, ENCODE_HEX)
    end

    def encode(src_str, str_map)
      return '' if src_str.empty?

      dst = []
      while src_str && !src_str.empty?
        src_len = src_str.length
        next_byte = [0] * 8

        if src_len > 4
          next_byte[7] = src_str[4] & 0x1f
          next_byte[6] = src_str[4] >> 5
        end
        if src_len > 3
          next_byte[6] = next_byte[6] | (src_str[3] << 3) & 0x1f
          next_byte[5] = (src_str[3] >> 2) & 0x1f
          next_byte[4] = src_str[3] >> 7
        end
        if src_len > 2
          next_byte[4] = next_byte[4] | (src_str[2] << 1) & 0x1f
          next_byte[3] = (src_str[2] >> 4) & 0x1f
        end
        if src_len > 1
          next_byte[3] = next_byte[3] | (src_str[1] << 4) & 0x1f
          next_byte[2] = (src_str[1] >> 1) & 0x1f
          next_byte[1] = (src_str[1] >> 6) & 0x1f
        end
        if src_len > 0
          next_byte[1] = next_byte[1] | (src_str[0] << 2) & 0x1f
          next_byte[0] = src_str[0] >> 3
        end

        next_byte.each do |nb|
          dst << str_map[nb]
        end
        src_str = src_str[5..src_str.length]
      end

      dst.join('')
    end

    def decode(src, str_map)
      src.downcase!

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
          dbuf[i] = decode_hex_map[char]
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
