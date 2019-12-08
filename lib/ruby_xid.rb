# Xid implementatin in Ruby 
class Xid
  require 'socket'
  require 'securerandom'
  require 'date'

  RAW_LEN = 12
  TRIM_LEN = 20

  attr_accessor :value
  attr_reader :machine_id

  def initialize(id = nil)
    @mutex = Mutex.new
    init_rand_int
    @pid = Process.pid
    @machine_id = real_machine_id
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

  def string
    # type: () -> str
    byte_value = bytes
    Base32.b32encode(byte_value).downcase[0..TRIM_LEN - 1]
  end

  def bytes
    # type: () -> str
    value.map(&:chr).join('')
  end

  def init_rand_int
    # type: () -> int
    @rand_int = begin
      buford = SecureRandom.hex(3).scan(/.{2}/m).map(&:hex)
      buford[0] << 16 | buford[1] << 8 | buford[2]
    end
  end

  def ==(other_xid)
    # type: (Xid) -> bool
    string < other_xid.string
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
end

require_relative 'xid/base32'
