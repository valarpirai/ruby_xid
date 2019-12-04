class Xid
    require 'socket'
    require 'securerandom'

    # Some Constants
    # trimLen = 20
    # encodedLen = 24
    # decodedLen = 14

    # encodedLen = 20 # string encoded len
    # rawLen     = 12 # binary raw len

    # // encoding stores a custom version of the base32 encoding with lower case
    # // letters.
    encoding = "0123456789abcdefghijklmnopqrstuv".freeze
    # encodeHex = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
    # padChar = "="

    decodeHexMap = Hash[encoding.chars.each_with_index.map { |x, i| [x, i] }]

    def initialize
        @mutex = Mutex.new
        rand_int
    end

    def pid
        Process.pid
    end

    def machineID
        @machineID ||= real_machineID
    end

    def rawLen
        12
    end

    def rand_int
        # type: () -> int
        @randInt = begin
            buford = SecureRandom.hex(3).scan(/.{2}/m).map { |s| s.hex }
            buford[0] << 16 | buford[1] << 8 | buford[2]
        end
    end

    def real_machineID
        # type: () -> List[int]
        hostname = Socket.gethostname.encode('utf-8')
        md5 = Digest::MD5.new
        md5 << hostname
        val = md5.hexdigest[0..5]
        return val.scan(/.{2}/m).map { |s| s.hex }
    rescue
        SecureRandom.hex(3).scan(/.{2}/m).map { |s| s.hex }
    end

    def generate_xid
        # type: () -> List[int]
        now = Time.now.to_i
        id = [0] * rawLen

        id[0] = (now >> 24) & 0xff
        id[1] = (now >> 16) & 0xff
        id[2] = (now >> 8) & 0xff
        id[3] = now & 0xff

        id[4] = machineID[0]
        id[5] = machineID[1]
        id[6] = machineID[2]

        id[7] = (pid >> 8) & 0xff
        id[8] = (pid) & 0xff

        @mutex.synchronize do
            @randInt += 1
        end
        i = @randInt

        id[9] = (i >> 16) & 0xff
        id[10] = (i >> 8) & 0xff
        id[11] = (i) & 0xff

        return id
    end
end

sd = Xid.new
p sd.rand_int

p sd.real_machineID

p sd.generate_xid
p sd.generate_xid
p sd.generate_xid
