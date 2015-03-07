require 'backto/scanner'
require 'minitest/autorun'
require_relative './helper'

class ScannerTest < Minitest::Test


  def scan_result(*args)
    Backto::Scanner.new(*args).to_enum.to_a.map(&:first)
  end

  def assert_equal_set(expected, actual)
    assert_equal expected.sort, actual.sort
  end

  def test_exclude_dir_patterns
    tree = TempTree.new do |t|
      t.mkdir 'foo'
      t.mkdir 'foobar'
      t.file 'bar'
    end

    assert_equal_set ['foobar', 'bar'], scan_result(tree.dir, ['foo/'])
    assert_equal_set ['foo', 'foobar', 'bar'], scan_result(tree.dir, ['bar/'])
  end

  def test_exclude_recursive_patterns
    tree = TempTree.new do |t|
      t.file 'foo'
      t.file '1/foo'
      t.file '1/2/foo'
    end

    # test without exclude_pattern
    assert_equal_set ['foo', '1', '1/foo', '1/2', '1/2/foo'], scan_result(tree.dir, [])
    assert_equal_set ['1', '1/2'], scan_result(tree.dir, ['foo'])
    assert_equal_set ['1', '1/foo', '1/2', '1/2/foo'], scan_result(tree.dir, ['/foo'])
  end


  def test_exclude_subdirectory_files
    tree = TempTree.new do |t|
      t.file 'foo/bar/a'
    end

    assert_equal_set ['foo'], scan_result(tree.dir, ['bar'])
    assert_equal_set [], scan_result(tree.dir, ['foo'])
  end

  def test_exclude_match_patterns
    tree = TempTree.new do |t|
      t.file 'foo1'
      t.file 'foo2'
      t.file 'foo3/bar3'
      t.file 'foo4/bar4/4'
      t.file 'foo5/bar5/foobar5/5'
    end

    assert_equal_set [], scan_result(tree.dir, ['foo*'])
    assert_equal_set ['foo1', 'foo2'], scan_result(tree.dir, ['foo*/'])
    assert_equal_set ['foo1', 'foo2', 'foo3', 'foo3/bar3', 'foo4', 'foo5'], scan_result(tree.dir, ['foo*/*/'])
    assert_equal_set ['foo1', 'foo2', 'foo3', 'foo3/bar3', 'foo4', "foo4/bar4", "foo5", "foo5/bar5", "foo5/bar5/foobar5"], scan_result(tree.dir, ['foo*/**/?'])
  end


  def test_skip_recursive_all
    tree = TempTree.new do |t|
      t.file 'foo1'
      t.file 'foo2/bar2'
      t.file 'foo3/bar3/3'
    end

    assert_equal_set ['foo1', 'foo2', 'foo3'], scan_result(tree.dir, [], true)
    assert_equal_set ['foo1', 'foo2', 'foo2/bar2', 'foo3'], scan_result(tree.dir, [], ['foo3'])
  end

end
