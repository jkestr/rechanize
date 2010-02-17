require 'rechanize/xml'

describe "A simple XML interface" do

  it "should just work" do
    xml = Xml.parse("<xml><foo>bar</foo></xml>")
    xml.keys.should.equal ['foo']
    xml['foo'].should.equal 'bar'
  end

  it "should auto expand arrays" do
    xml = Xml.parse("<xml><foo>bar</foo><foo>bar2</foo></xml>")
    xml['foo'].should.equal ['bar', 'bar2']
  end

end

