require 'minitest/autorun'
require 'ruby_xid'

class XidTest < Minitest::Test
  TestXids = [
    # taken from https://github.com/rs/xid/blob/master/id_test.go
    {
      'xid': Xid.new([0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4, 0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9]),
      'ts': 1300816219,
      'machine': [0x60, 0xf4, 0x86].map(&:chr).join(''),
      'pid': 0xe428,
      'counter': 4271561
    },
    {
      'xid': Xid.new([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
      'ts': 0,
      'machine': [0x00, 0x00, 0x00].map(&:chr).join(''),
      'pid': 0x0000,
      'counter': 0
    },
    {
      'xid': Xid.new([0x00, 0x00, 0x00, 0x00, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0x00, 0x00, 0x01]),
      'ts': 0,
      'machine': [0xaa, 0xbb, 0xcc].map(&:chr).join(''),
      'pid': 0xddee,
      'counter': 1
    }
  ]

  def test_no_duplicates
    collect = []
    1000.times { collect << Xid.new }
    ids = collect.each(&:string)
    assert_equal (ids | []).length, 1000
  end

  def test_from_string
    x = Xid.new
    y = Xid.from_string(x.string)

    assert_equal x.value, y.value
    assert_equal x.bytes, y.bytes
    assert_equal x.string, y.string
  end

  def test_xid_always_reversible
    10.times do
      str = Xid.new.string
      assert_equal(Xid.from_string(str).string, str)
    end
  end

  def test_timestamp
    TestXids.each do |x|
      assert_equal(x[:xid].time, x[:ts])
    end
  end

  def test_machine
    TestXids.each do |x|
      assert_equal(x[:xid].machine, x[:machine])
    end
  end

  def test_pid
    TestXids.each do |x|
      assert_equal(x[:xid].pid, x[:pid])
    end
  end

  def test_counter
    TestXids.each do |x|
      assert_equal(x[:xid].counter, x[:counter])
    end
  end

  def test_copy_array_from_golang
    x = Xid.new([0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4,
             0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9])
    assert_equal('9m4e2mr0ui3e8a215n4g', x.string)
  end

  def test_copy_string_from_golang
    x = Xid.from_string('9m4e2mr0ui3e8a215n4g')
    assert_equal(x.value, [0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4,
                               0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9])
  end
end
