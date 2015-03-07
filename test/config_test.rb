require 'backto/config'
require 'minitest/autorun'

class ConfigTest < Minitest::Test

  def test_default_config
    config = Backto::Config.new({})
    assert_equal config[:verbose], true
  end

  def test_necessary_config
    config = Backto::Config.new({})
    %i(from to).each do |key|
      assert_raises KeyError do
       config[key]
      end
    end
  end

  def test_expand_user_path
    config = Backto::Config.new({from: '~/foo', to: '~root/foo'})
    assert_equal config[:from], File.expand_path('~/foo')
    assert_equal config[:to], File.expand_path('~root/foo')
  end

  def test_expand_relative_path
    config = Backto::Config.new({from: './foo', to: 'bar'})
    assert_equal config[:from], File.expand_path(File.join(Dir.pwd, 'foo'))
    assert_equal config[:to], File.expand_path(File.join(Dir.pwd, 'bar'))
  end

  def test_file_config
    fixtures_dir = File.expand_path('../fixtures', __FILE__)
    file = File.join(fixtures_dir, 'test_file_config.json')
    config = Backto::Config.new(file)
    assert_equal config[:from], File.join(fixtures_dir, 'foo')
    assert_equal config[:to], File.join(fixtures_dir, 'bar')
    assert_equal config[:verbose], false
  end

end
