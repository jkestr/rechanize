class Array

  # Convert an array of tuples to a #Hash
  # [[:foo, :bar]].to_hash # => {:foo => :bar}
  def to_hash
    reject { |pair|
      pair.length != 2
    }.inject({}) { |h,p|
      h[p[0]] = p[1]; h
    }
  end

  # Zip two arrays into an array of tuples and convert to a key/value hash.
  # [:foo].zip_hash(:bar) # => {:foo => :bar}
  def zip_hash(vals)
    zip(vals).to_hash
  end

end

