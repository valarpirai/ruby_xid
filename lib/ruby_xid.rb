# Xid implementatin in Ruby 
require 'socket'
require 'securerandom'
require 'date'

class Xid

  RAW_LEN = 12
  TRIM_LEN = 20

  @@generator = nil

  attr_accessor :value

  def initialize(id = nil)
    @@generator ||= Generator.new(init_rand_int, real_machine_id)
    @value = id || @@generator.next_xid
  end

  def next
    @value = @@generator.next_xid
    string
  end

  def pid
    # type: () -> int
    (value[7] << 8 | value[8])
  end

  def counter
    # type: () -> int
    value[9] << 16 | value[10] << 8 | value[11]
  end

  def machine
    # type: () -> str
    value[4..6].map(&:chr).join('')
  end

  def datetime
    Time.at(time).to_datetime
  end

  def time
    # type: () -> int
    value[0] << 24 | value[1] << 16 | value[2] << 8 | value[3]
  end

  def inspect
    "Xid('#{string}')"
  end

  def string
    # type: () -> str
    Base32.b32encode(value)[0..TRIM_LEN - 1]
  end

  def bytes
    # type: () -> str
    value.map(&:chr).join('')
  end

  def init_rand_int
    # type: () -> int
    SecureRandom.random_number(16_777_215)
  end

  def real_machine_id
    # type: () -> int
    Digest::MD5.digest(Socket.gethostname).unpack('N')[0]
  rescue
    init_rand_int
  end

  def ==(other_xid)
    # type: (Xid) -> bool
    string == other_xid.string
  end

  def <(other_xid)
    # type: (Xid) -> bool
    string < other_xid.string
  end

  def >(other_xid)
    # type: (Xid) -> bool
    string > other_xid.string
  end

  def self.from_string(str)
    val = Base32.b32decode(str)
    value_check = val.select { |x| x >= 0 && x <= 255 }

    (value_check.length..RAW_LEN - 1).each do |i|
      value_check[i] = false
    end

    raise 'Invalid Xid' unless value_check.all?

    Object.const_get(name).new(val)
  end

  # Xid Generator
  class Generator
    attr_accessor :value

    def initialize(rand_val = nil, machine_id = 0)
      @mutex = Mutex.new
      @rand_int = rand_val || rand(65_535)
      @pid = Process.pid
      @machine_id = machine_id
    end

    def next_xid
      # type: () -> List[int]
      value = Array.new(RAW_LEN, 0)

      now = Time.now.to_i
      value[0] = (now >> 24) & 0xff
      value[1] = (now >> 16) & 0xff
      value[2] = (now >> 8) & 0xff
      value[3] = now & 0xff

      value[4] = (@machine_id >> 16) & 0xff
      value[5] = (@machine_id >> 8) & 0xff
      value[6] = @machine_id & 0xff

      value[7] = (@pid >> 8) & 0xff
      value[8] = @pid & 0xff

      @mutex.synchronize do
        @rand_int += 1
      end

      value[9] = (@rand_int >> 16) & 0xff
      value[10] = (@rand_int >> 8) & 0xff
      value[11] = @rand_int & 0xff

      value
    end
  end
end

require_relative 'xid/base32'
