require 'benchmark/ips'
require 'ruby_xid'
require 'mongoid'

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('MongoId') do
    BSON::ObjectId.new
  end

  x.report('BSON Generate') do
    BSON::ObjectId::Generator.new
  end

  # x.report('Xid Generate') do
  #   Xid::Generator.new
  # end

  x.report('Xid') do
    Xid.new
  end

  x.report('Xid - string') do
    Xid.new.to_s
  end

  x.compare!
end
