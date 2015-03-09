require 'backto'
require 'minitest/autorun'
require_relative './helper'


class BacktoTest < Minitest::Test

  def test_softlink
    from = TempTree.new do |t|
      t.file 'a/b/c'
      t.mkdir 'a/d'
    end

    to = TempTree.new
    Backto.run({from: from.dir, to: to.dir, verbose: false})

    assert to.symlink? 'a/b/c'
    assert to.directory? 'a/d'
  end

  def test_hardlink
    from = TempTree.new do |t|
      t.file 'a/b/c'
      t.mkdir 'a/d'
    end

    to = TempTree.new
    Backto.run({from: from.dir, to: to.dir, verbose: false, hardlink: true})

    assert_equal from.inode('a/b/c'), to.inode('a/b/c')
    assert to.directory? 'a/d'
  end

  def test_target_exist
    from = TempTree.new do |t|
      t.file 'a/b/c'
    end

    to = TempTree.new do |t|
      t.file 'a/b/c'
    end
    assert_raises Errno::EEXIST do
      Backto.run({from: from.dir, to: to.dir, verbose: false})
    end
    assert to.file? 'a/b/c'
  end

  def test_force
    from = TempTree.new do |t|
      t.file 'a/b/c'
    end

    to = TempTree.new do |t|
      t.file 'a/b/c'
    end

    refute to.symlink? 'a/b/c'
    Backto.run({from: from.dir, to: to.dir, verbose: false, force: true})
    assert to.symlink? 'a/b/c'
  end

  def test_link_directory
    from = TempTree.new do |t|
      t.file 'a/b/c'
    end
    to = TempTree.new
    Backto.run({from: from.dir, to: to.dir, verbose: false, link_directory: true})
    assert to.symlink? 'a'
    refute to.symlink? 'a/b/c'
  end

  def test_link_directory_when_target_exist
    from = TempTree.new do |t|
      t.mkdir 'a'
    end

    to = TempTree.new do |t|
      t.mkdir 'a'
    end
    assert_raises Errno::EEXIST do
      Backto.run({from: from.dir, to: to.dir, verbose: false, link_directory: true})
    end
    assert to.directory? 'a'
    refute to.exist? 'a/a'
  end

  def test_force_link_directory_when_target_exist
    from = TempTree.new do |t|
      t.mkdir 'a'
    end

    to = TempTree.new do |t|
      t.file 'a/b'
    end
    Backto.run({from: from.dir, to: to.dir, verbose: false, force: true, link_directory: true})
    assert to.symlink? 'a'
    refute to.exist? 'a/b'
    Backto.run({from: from.dir, to: to.dir, verbose: false, force: true, link_directory: true})
    refute to.exist? 'a/a'
  end

  def test_exclude_patterns
    from = TempTree.new do |t|
      t.file 'a/b/c'
      t.file 'foo'
    end
    to = TempTree.new
    Backto.run({from: from.dir, to: to.dir, verbose: false, exclude_patterns: ['f*']})
    assert to.symlink? 'a/b/c'
    refute to.exist? 'foo'
  end

end
