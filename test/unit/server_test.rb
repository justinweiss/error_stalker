require 'test_helper'
require 'rack/test'
require 'error_stalker/server'
require 'mocha'
require 'json'

ENV['RACK_ENV'] = 'test'

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    ErrorStalker::Server
  end

  def setup
    @store = ErrorStalker::Store::InMemory.new
    ErrorStalker::Server.any_instance.stubs(:store).returns(@store)
  end

  def test_report_exception
    report_exception
    assert last_response.ok?
    assert_equal 1, @store.exceptions.length
  end

  def test_can_see_homepage
    get '/'
    assert last_response.ok?
    assert_no_match /table/, last_response.body

    get "/recent.json"
    assert last_response.ok?
    stats = JSON.parse(last_response.body)
    assert_equal [], stats['recent_exceptions']
  end

  def test_can_see_homepage_table_after_exception_logged
    report_exception
    get '/'
    assert last_response.ok?
    assert_match /table/, last_response.body
    assert_match /failed/, last_response.body

    get "/recent.json"
    assert last_response.ok?
    stats = JSON.parse(last_response.body)
    assert_equal 1, stats['recent_exceptions'][0]['count']
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
    assert_no_match /exceptions\/4.html/, last_response.body
  end

  def test_emails_sent_only_on_first_report_in_group
    app.any_instance.stubs(:plugins).returns([ErrorStalker::Plugin::EmailSender.new(nil, {'to' => nil, 'from' => nil})])
    report_exception('test', 2)
    assert_equal 1, Mail::TestMailer.deliveries.length
    report_exception('test', 1)
    assert_equal 2, Mail::TestMailer.deliveries.length
  end

  def test_stats_renders_total
    report_exception('test', 4)
    get "/stats.json"
    assert last_response.ok?
    stats = JSON.parse(last_response.body)
    assert_equal 4, stats['total']
  end

  def test_stats_renders_timestamp
    report_exception('test', 1)
    timestamp = Time.now.to_i - 60 # one minute ago
    get "/stats.json", :timestamp => timestamp
    assert last_response.ok?
    stats = JSON.parse(last_response.body)
    assert_equal timestamp, stats['timestamp']
  end

  def test_stats_renders_total_since
    report_exception('test', 1)
    timestamp = Time.now.to_i - 60 # one minute ago
    get "/stats.json", :timestamp => timestamp
    assert last_response.ok?
    stats = JSON.parse(last_response.body)
    assert_equal 1, stats['total_since']
  end

  def test_advanced_search_shows_up
    get "/search"
    assert last_response.ok?
    assert_no_match /<label for="data">/, last_response.body

    @store.stubs(:supports_extended_searches?).returns(true)
    get "/search"
    assert last_response.ok?
    assert_match /<label for="data">/, last_response.body
  end

  def test_perform_search
    report_exception('test', 4)
    report_exception('te-t')
    get "/search?application=&machine=&exception=test&Search=Search"
    assert_match /exceptions\/0.html/, last_response.body
    assert_no_match /exceptions\/4.html/, last_response.body

    get "/search?application=&machine=&exception=te&Search=Search"
    assert_match /exceptions\/0.html/, last_response.body
    assert_match /exceptions\/4.html/, last_response.body

    get "/search?application=foo&machine=&exception=te&Search=Search"
    assert_no_match /exceptions\/0.html/, last_response.body
    assert_no_match /exceptions\/4.html/, last_response.body
  end

  protected
  def report_exception(message = "failed", count = 1, data = {})
    e = nil
    count.times do
      begin
        raise NoMethodError, message
      rescue => ex
        e = ErrorStalker::ExceptionReport.new(:exception => ex, :application => 'test', :data => data)
      end

      post '/report.json', e.to_json
    end
    e
  end
end

