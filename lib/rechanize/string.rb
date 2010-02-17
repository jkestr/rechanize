class String

  # Split a string of key/value pairs
  def multisplit(first, last)
    split(first).map { |pair| pair.split(last) }
  end

end
