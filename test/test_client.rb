require 'test/mocha_on_bacon'
require 'rechanize/client'

EXAMPLE_URL = 'http://user:pass@host.com/login_path'

describe 'Initializing a Client' do

  it 'should set scheme from login url' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.scheme.should.equal 'http'
  end

  it 'should set host from login url' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.host.should.equal 'host.com'
  end

  it 'should set login path from login url' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.login_path.should.equal '/login_path'
  end

  it 'should set user and password from login url' do
    agent = mock('mechanize')
    agent.expects(:auth).with('user', 'pass')
    WWW::Mechanize.expects(:new).returns(agent)
    Rechanize::Client.new(EXAMPLE_URL).agent.should.equal agent
  end

  it 'should set user from login url' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    uri = URI.parse(EXAMPLE_URL)
    client.user.should.equal uri.user
  end

end

describe 'Authenticating a Client' do

  it 'should assume authorized if paths are set' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.authenticated?.should.equal !client.paths.empty?
  end

  it 'should return false by default' do
    agent = stub('agent', :get => stub('page', :content => '<xml></xml>'))

    client = Rechanize::Client.new(EXAMPLE_URL)
    client.stubs(:agent).returns(agent)
    client.stubs(:build_uri)
    client.stubs(:login_path)
    client.stubs(:parse_paths)
    client.stubs(:set_paths)

    client.authenticate.should.equal false
  end

  it 'should raise an authentication error' do
    agent = stub('agent', :get => stub('page', :content => '<xml></xml>'))

    client = Rechanize::Client.new(EXAMPLE_URL)
    client.stubs(:agent).returns(agent)
    client.stubs(:parse_paths)
    client.stubs(:set_paths)

    lambda {
      client.authenticate!
    }.should.raise(Rechanize::AuthenticationError)
  end

end

describe 'Working with metadata' do

  it 'should fetch' do
    page  = mock('page', :content => 'data')
    agent = mock('agent', :get => page)

    client = Rechanize::Client.new(EXAMPLE_URL)
    client.expects(:path).returns('')
    client.expects(:agent).returns(agent)

    client.metadata 
  end
  
  it 'should download and archive' do
    io   = mock('io', :read => 'metadata')
    file = mock('file', :<< => 'metadata')

    client = Rechanize::Client.new(EXAMPLE_URL)
    client.expects(:metadata).returns(io)

    File.expects(:open).yields(file)

    client.metadata!('path')
  end

end

describe 'Path Caching' do

  it "should return path for request method" do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.expects(:paths).returns({'Foo' => '/path/to/foo'})
    client.path('Foo').should.equal '/path/to/foo'
  end

  it 'should build uris and cache request method paths' do
    paths = mock('hash')
    paths.expects(:clear)
    paths.expects(:[]=).with('Foo', '/foo')
    paths.expects(:keys).returns(['Foo'])

    client = Rechanize::Client.new(EXAMPLE_URL)
    client.stubs(:paths).returns(paths)
    client.expects(:build_uri).with('/foo').returns('/foo')
    client.send(:set_paths, {'Foo' => '/foo'}).should.equal ['Foo']
  end

  it 'should build uri from login url' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    uri = URI.parse(EXAMPLE_URL)
    uri = "#{uri.scheme}://#{uri.host}:#{uri.port}/path"
    client.send(:build_uri, '/path').should.equal uri 
  end

end

describe 'Building URIs' do
  
  it 'should return an Array of known methods' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.known_methods.should.is_a?(Array)
  end

  it 'should return true if the method is known' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.stubs(:known_methods).returns(['Foo'])
    client.method_known?('Foo').should.be.true
  end

  it 'should generate URI from login url and method path' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.send(:build_uri, '/foo').should.equal "http://host.com:80/foo"
  end

  it 'should raise error if path is not a valid path' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    lambda { 
      client.send(:build_uri, 'foo')
    }.should.raise(Rechanize::InvalidPathError)
  end

end

describe 'Getting Data' do
end

describe 'Parsing Results' do
end

describe 'Parsing Paths' do

  it 'should multisplit RETS-RESPONSE into a hash' do
    client = Rechanize::Client.new(EXAMPLE_URL)
    client.stubs(:method_known?).returns(true)
    data = {"RETS-RESPONSE" => "R=2\nD=2"}
    expected = {"R" => "2", "D" => "2"}
    client.send(:parse_paths, data).should.equal expected
  end

end

describe 'Parising XML' do
end

describe 'Parsing RETS Compact XML' do
end

describe 'Parsing Multiparts' do
end

describe 'Parsing Parallel Data' do
end

