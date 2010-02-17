module Xml
  require 'xmlsimple'

  # Convert a XML #String into a ruby #Hash.
  def self.parse(str)
    XmlSimple.xml_in(str, 'ForceArray' => false)
  end

end
