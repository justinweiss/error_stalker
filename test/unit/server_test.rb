require 'test_helper'
require 'rack/test'
require 'exceptionl/server'
require 'mocha'

ENV['RACK_ENV'] = 'test'

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Exceptionl::Server
  end

  def setup
    @store = Exceptionl::Store::InMemory.new
    Exceptionl::Server.any_instance.stubs(:store).returns(@store)
  end

  def test_report_exception
    report_exception
    assert last_response.ok?
    assert_equal 1, @store.exceptions.length
  end

  def test_can_see_homepage
    get '/'
    assert last_response.ok?
    assert_not_match /table/, last_response.body
  end

  def test_can_see_homepage_table_after_exception_logged
    report_exception
    get '/'
    assert last_response.ok?
    assert_match /table/, last_response.body
    assert_match /failed/, last_response.body
  end

  def test_groups_aggregated_on_homepage
    report_exception
    report_exception('test2', 2)
    get '/'
    assert last_response.ok?
    assert_match /<td class="count">2/, last_response.body
  end

  def test_find_exception
    report_exception
    get '/exceptions/0.html'
    assert last_response.ok?
    assert_match /failed/, last_response.body
    assert_match /server_test.rb/, last_response.body
  end

  def test_find_related
    e = report_exception('test', 4)
    report_exception('test2', 1)
    get "/similar/#{e.digest}.html"
    assert last_response.ok?
    assert_match /exceptions\/0.html/, last_response.body
    assert_not_match /exceptions\/4.html/, last_response.body
  end

  def test_emails_sent_only_on_first_report_in_group
    app.any_instance.stubs(:plugins).returns([Exceptionl::Plugin::EmailSender.new(nil, {'to' => nil, 'from' => nil})])
    report_exception('test', 2)
    assert_equal 1, Mail::TestMailer.deliveries.length
    report_exception('test', 1)
    assert_equal 2, Mail::TestMailer.deliveries.length
  end
  
  def report_exception(message = "failed", count = 1, data = {})
    e = nil
    count.times do 
      begin
        raise NoMethodError, message
      rescue => ex
        e = Exceptionl::ExceptionReport.new(:exception => ex, :application => 'test', :data => data)
      end
      
      post '/report.json', e.to_json
    end
    e
  end
end

