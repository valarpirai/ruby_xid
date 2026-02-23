# frozen_string_literal: true
# Xid implementatin in Ruby 
require 'socket'
require 'securerandom'
require 'date'
require 'digest'

class Xid

  RAW_LEN = 12

  @@generator = nil

  def initialize(id = nil)
    @@generator ||= Generator.new(init_rand_int, real_machine_id)
    if id
      # Convert array to binary string if needed
      @value = id.is_a?(String) ? id : id.pack('C*')
    else
      @value = @@generator.generate
    end
  end

  def next
    @string = nil
    @value = @@generator.generate
    string
  end

  def value
    # Return as array for backward compatibility
    @value.bytes
  end

  def pid
    # type: () -> int
    (@value.getbyte(7) << 8 | @value.getbyte(8))
  end

  def counter
    # type: () -> int
    @value.getbyte(9) << 16 | @value.getbyte(10) << 8 | @value.getbyte(11)
  end

  def machine
    # type: () -> str
    @value[4, 3]
  end

  def datetime
    Time.at(time).to_datetime
  end

  def time
    # type: () -> int
    @value.getbyte(0) << 24 | @value.getbyte(1) << 16 | @value.getbyte(2) << 8 | @value.getbyte(3)
  end

  def inspect
    "Xid('#{string}')"
  end

  def to_s
    string
  end

  def bytes
    # type: () -> str
    @value
  end

  def ==(other_xid)
    # type: (Xid) -> bool
    to_s == other_xid.to_s
  end

  def <(other_xid)
    # type: (Xid) -> bool
    to_s < other_xid.to_s
  end

  def >(other_xid)
    # type: (Xid) -> bool
    to_s > other_xid.to_s
  end

  def self.from_string(str)
    raise 'Invalid Xid' if str.nil? || !str.match(/^[a-v0-9]{20}$/i)
    val = Base32.b32decode(str)
    value_check = val.select { |x| x >= 0 && x <= 255 }

    (value_check.length..RAW_LEN - 1).each do |i|
      value_check[i] = false
    end

    raise 'Invalid Xid' unless value_check.all?

    # Convert array to binary string
    binary_val = val.pack('C*')
    Object.const_get(name).new(binary_val)
  end

  private
  def string
    # type: () -> str
    @string ||= Base32.b32encode(@value)
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

  # Xid Generator
  class Generator
    attr_accessor :value

    def initialize(rand_val = nil, machine_id = 0)
      @mutex = Mutex.new
      @rand_int = rand_val || rand(65_535)
      @pid = Process.pid
      @machine_id = machine_id
    end

    def generate
      # () -> str
      @mutex.synchronize do
        @rand_int += 1
      end
      [::Time.new.to_i, @machine_id, @pid, @rand_int << 8].pack('N NX n NX')
    end
  end
end

require_relative 'xid/base32'
