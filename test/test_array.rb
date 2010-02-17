require 'rechanize/array'

describe 'Converting an array to a hash' do

  it 'should convert tuples to a key/value hash' do
    ary = [[:foo, :bar]]
    ary.to_hash.should.equal({:foo => :bar})
  end

  it 'should zip two arrays into a hash' do
    keys = [:foo]
    vals = [:bar]
    hash = keys.zip_hash(vals)
    hash.should.equal({:foo => :bar})
  end

end

