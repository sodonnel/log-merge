require './test_helper'

class LogCombinerTest < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_combiner_operates_on_single_file
    io = StringIO.new("2012-01-13 22:28:09,834 INFO Log line 1\n2012-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    output = StringIO.new("", 'w+')
    lr = LogMerge::LogReader.new(io, 'alias')
    combiner = LogMerge::LogCombiner.new
    combiner.add_log_reader(lr)
    combiner.merge(output)
    output.rewind
    assert_equal('alias 2012-01-13 22:28:09,834 INFO Log line 1',  output.readline.chomp)
    assert_equal('alias 2012-01-13 22:28:09,834 DEBUG Log line 2', output.readline.chomp)
  end

  def test_combiner_operates_on_two_files_and_sorts_correctly
    io1 = StringIO.new("2012-01-13 22:28:09,834 INFO file 1 line 1\n2012-01-13 22:30:09,834 DEBUG file 1 line 2", 'r')
    io2 = StringIO.new("2012-01-13 22:29:09,834 DEBUG file 2 line 1", 'r')
    output = StringIO.new("", 'w+')
    lr1 = LogMerge::LogReader.new(io1, 'alias')
    lr2 = LogMerge::LogReader.new(io2, 'alias')
    combiner = LogMerge::LogCombiner.new
    combiner.add_log_reader(lr1)
    combiner.add_log_reader(lr2)
    combiner.merge(output)
    output.rewind
    assert_equal('alias 2012-01-13 22:28:09,834 INFO file 1 line 1',  output.readline.chomp)
    assert_equal('alias 2012-01-13 22:29:09,834 DEBUG file 2 line 1', output.readline.chomp)
    assert_equal('alias 2012-01-13 22:30:09,834 DEBUG file 1 line 2', output.readline.chomp)
  end

  def test_combiner_operates_on_three_files_and_sorts_correctly
    ios = [
      StringIO.new("2012-01-13 22:28:09,802 INFO file 1 line 1\n2012-01-13 22:28:09,803 INFO file 1 line 2", 'r'),
      StringIO.new("2012-01-13 22:28:09,801 INFO file 2 line 1", 'r'),
      StringIO.new("2012-01-13 22:28:09,800 INFO file 3 line 1", 'r')
    ]
    output   = StringIO.new("", 'w+')
    combiner = LogMerge::LogCombiner.new
    ios.each{|io| lr = combiner.add_log_reader(LogMerge::LogReader.new(io, 'alias')) }

    combiner.merge(output)
    output.rewind
    
    assert_equal('alias 2012-01-13 22:28:09,800 INFO file 3 line 1', output.readline.chomp)
    assert_equal('alias 2012-01-13 22:28:09,801 INFO file 2 line 1', output.readline.chomp)
    assert_equal('alias 2012-01-13 22:28:09,802 INFO file 1 line 1', output.readline.chomp)
    assert_equal('alias 2012-01-13 22:28:09,803 INFO file 1 line 2', output.readline.chomp)
  end
  
end
