require 'test_helper'

class InMemoryTest < Test::Unit::TestCase
  def setup
    @store = Exceptionl::Store::InMemory.new
  end
  
  def test_store_exception
    assert @store.empty?
    store_exception(@store)
    assert !@store.empty?
    assert_equal 1, @store.recent.length
    assert @store.find(0)
  end

  def test_group
    store_exception(@store, "test", 2)
    store_exception(@store, "test2")

    assert_equal 2, @store.recent.length
    assert_equal 1, @store.reports_in_group(@store.find(2).digest).length
    assert_equal 1, @store.group(@store.find(2).digest).count
    assert_equal 2, @store.reports_in_group(@store.find(0).digest).length
    assert_equal 2, @store.group(@store.find(0).digest).count
  end

  def test_search
    store_exception(@store, "test", 2)
    store_exception(@store, "text")
    assert_equal 3, @store.search(:application => 'test').length
    assert_equal 0, @store.search(:application => 'foo').length
    assert_equal 3, @store.search(:machine => `hostname`.chomp, :application => 'test').length
    assert_equal 0, @store.search(:machine => 'example.com', :application => 'test').length
    assert_equal 1, @store.search(:application => 'test', :exception => 'tex').length
    assert_equal 3, @store.search(:application => 'test', :exception => 'te').length
  end

  def test_machines_and_applications
    store_exception(@store, "test", 2)
    assert_equal 1, @store.machines.length
    assert_equal 1, @store.applications.length
    assert_equal 'test', @store.applications.first
  end
  
  protected
  def store_exception(store, message = "failed", count = 1, data = {})
    e = nil
    count.times do 
      begin
        raise NoMethodError, message
      rescue => ex
        e = Exceptionl::ExceptionReport.new(:exception => ex, :application => 'test', :data => data)
      end
      @store.store(e)
    end
    e
  end
end
