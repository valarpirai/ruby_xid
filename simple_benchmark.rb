require 'benchmark'
require_relative 'lib/ruby_xid'

iterations = 100_000

puts "Running benchmarks with #{iterations} iterations..."
puts

Benchmark.bm(25) do |x|
  x.report("Xid.new") do
    iterations.times { Xid.new }
  end

  x.report("Xid.new.to_s") do
    iterations.times { Xid.new.to_s }
  end

  x.report("from_string") do
    xid_string = Xid.new.to_s
    iterations.times { Xid.from_string(xid_string) }
  end

  x.report("field extraction") do
    xid = Xid.new
    iterations.times do
      xid.time
      xid.machine
      xid.pid
      xid.counter
    end
  end
end
