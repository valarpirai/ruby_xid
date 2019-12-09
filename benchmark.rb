require 'benchmark/ips'
require 'ruby_xid'

Benchmark.ips do |x|
    x.config(:time => 5, :warmup => 2)

    x.report('Xid generation') do 
        Xid.new
    end

    x.report('Xid generate and convert to bytes') do 
        Xid.new.bytes
    end

    x.report('Xid generate and convert to string') do 
        Xid.new.string
    end

    x.compare!
end
