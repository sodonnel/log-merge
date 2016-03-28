require './test_helper'

class LogReaderTest < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_nil_returned_for_next_when_no_log_lines_exist
    io = StringIO.new("20-01-13 22:28:09,834 INFO Log line 1\n20-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.current, nil)
  end

  def test_nil_returned_for_next_when_logfile_is_empty
    io = StringIO.new("", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.current, nil)
  end
  
  def test_correct_line_returned_when_first_line_is_a_log
    io = StringIO.new("2016-01-13 22:28:09,834 INFO Log line 1\n2016-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.current.raw_content, "2016-01-13 22:28:09,834 INFO Log line 1\n")
  end

  def test_correct_line_returned_when_first_line_is_not_a_log
    io = StringIO.new("20-01-13 22:28:09,834 INFO Log line 1\n2016-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.current.raw_content, "2016-01-13 22:28:09,834 DEBUG Log line 2")
  end

  def test_correct_line_for_each_call_of_next
    io = StringIO.new("2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n2016-01-13 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.next.raw_content, "2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
    assert_equal(lr.next.raw_content, "2016-01-13 22:28:09,834 DEBUG Log line 2\npart2")
    assert_equal(lr.next, nil)
  end

  def test_correct_line_for_each_call_of_next_for_aliased_lines
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-13 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_equal(lr.next.raw_content, "abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
    assert_equal(lr.next.raw_content, "def 2016-01-13 22:28:09,834 DEBUG Log line 2\npart2")
    assert_equal(lr.next, nil)
  end

  def test_skip_to_time_errors_unless_date_passed
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-13 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    assert_raises(RuntimeError) do
      lr.skip_to_time('abc')
    end
  end

  def test_skip_to_time_sets_correct_position_when_in_middle_of_stream
    #                  0        10        20        30        40          50      56
    #                  123456789012345678901234567890123456789012 345678 901234 5 6
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    lr.skip_to_time(Date.new(2016,1, 14))
    assert_equal(lr.io_position, 56)
    assert_equal(lr.next.raw_content, "def 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2")
  end

  def test_skip_to_time_sets_correct_position_when_before_start_of_stream
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    lr.skip_to_time(Date.new(2015,1, 14))
    assert_equal(lr.io_position, 0)
    assert_equal(lr.next.raw_content, "abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
  end

  def test_skip_to_time_sets_correct_position_when_after_end_of_stream
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    lr.skip_to_time(Date.new(2017,1, 14))
    assert_equal(lr.next, nil)
  end

  def test_skip_to_time_does_not_alter_position_when_stream_already_past_date
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    lr = LogMerge::LogReader.new(io)
    # Get the first line to advance the position of the stream
    lr.current
    # Skip to the line that would be the next line
    lr.skip_to_time(Date.new(2016,1, 14))

    assert_equal(lr.current.raw_content, "abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
    assert_equal(lr.next.raw_content, "def 2016-01-14 22:28:09,834 DEBUG Log line 2\npart2")
  end
  
end
