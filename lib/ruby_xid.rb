class RubyXid
  require 'socket'
  require 'securerandom'
  require 'date'

  RAW_LEN = 12
  ENCODE_HEX = '0123456789ABCDEFGHIJKLMNOPQRSTUV'.freeze
  PAD_CHAR = '='.freeze

  def initialize(id = nil)
    @mutex = Mutex.new
    init_rand_int
    @pid = Process.pid
    unless id.nil?
      # Decoded array
      @value = id
    else
      @value = generate_xid
    end
  end

  def next_xid
    @value = generate_xid
    string
  end

  def pid
    # type: () -> int
    (@value[7] << 8 | @value[8])
  end

  def counter
    # type: () -> int
    @value[9] << 16 | @value[10] << 8 | @value[11]
  end

  def machine
    # type: () -> str
    @value[4..7].map(&:chr)
  end

  def datetime
    Time.at(time).to_datetime
  end

  def time
    # type: () -> int
    @value[0] << 24 | @value[1] << 16 | @value[2] << 8 | @value[3]
  end

  def machine_id
    @machine_id ||= real_machine_id
  end

  def string
    # type: () -> str
    byte_value = bytes
    b32encode(byte_value).downcase
  end

  def bytes
    # type: () -> str
    @value.map(&:chr).join('')
  end

  def init_rand_int
    # type: () -> int
    @rand_int = begin
      buford = SecureRandom.hex(3).scan(/.{2}/m).map(&:hex)
      buford[0] << 16 | buford[1] << 8 | buford[2]
    end
  end

  def ==(arg)
    # type: (Xid) -> bool
    self.string < arg.string
  end

  def <(arg)
    # type: (Xid) -> bool
    self.string < arg.string
  end

  def >(arg)
    # type: (Xid) -> bool
    self.string > arg.string
  end

  # Start class methods
  class << self

    def decode_hex_map
      Hash[ENCODE_HEX.chars.each_with_index.map { |x, i| [x, i] }]
    end

    def from_string(str)
      val = b32decode(str)
      value_check = val.select { |x| 0 <= x && x < 255 }

      unless value_check.all?
        raise InvalidXid(str)
      end

      Object.const_get(self.name).new(val)
    end

    def b32decode(src)
      decode(src, ENCODE_HEX)
    end

    def decode(src, str_map)
      src.upcase!
    
      end_loop = false
      result = []
      while !src.empty? && !end_loop
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
          if char == PAD_CHAR
            end_loop = true
            src_len = i
            break
          else
            dbuf[i] = decode_hex_map[char]
          end
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
    
        dst = dst.map{ |x| x & 0xff }
    
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

  private

    def real_machine_id
      # type: () -> List[int]
      hostname = Socket.gethostname.encode('utf-8')
      md5 = Digest::MD5.new
      md5 << hostname
      val = md5.digest[0..3]
      val.scan(/.{1}/m).map(&:ord)
    rescue
      SecureRandom.hex(3).scan(/.{2}/m).map(&:hex)
    end

    def b32encode(src)
      src = src.scan(/.{1}/m).map(&:ord)
      encode(src, ENCODE_HEX)
    end

    def generate_xid
      # type: () -> List[int]
      now = Time.now.to_i
      id = [0] * RAW_LEN

      id[0] = (now >> 24) & 0xff
      id[1] = (now >> 16) & 0xff
      id[2] = (now >> 8) & 0xff
      id[3] = now & 0xff

      id[4] = machine_id[0]
      id[5] = machine_id[1]
      id[6] = machine_id[2]

      id[7] = (@pid >> 8) & 0xff
      id[8] = @pid & 0xff

      @mutex.synchronize do
        @rand_int += 1
      end
      i = @rand_int

      id[9] = (i >> 16) & 0xff
      id[10] = (i >> 8) & 0xff
      id[11] = i & 0xff

      id
    end

    def encode(src_str, str_map)
      return '' if src_str.empty?

      dst = []
      src_len = 0
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

      dst[-1] = '=' if src_len < 5
      if src_len < 4
        dst[-2] = '='
        dst[-3] = '='
      end
      if src_len < 3
        dst[-4] = '='
      end
      if src_len < 2
        dst[-5] = '='
        dst[-6] = '='
      end

      dst.join('')
    end
end

class InvalidXid < ::StandardError; end
