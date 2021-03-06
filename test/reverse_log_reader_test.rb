require './test_helper'

class ReverseLogReaderTest < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_nil_returned_for_next_when_no_log_lines_exist
    io = StringIO.new("20-01-13 22:28:09,834 INFO Log line 1\n20-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.current, nil)
  end

  def test_nil_returned_for_next_when_logfile_is_empty
    io = StringIO.new("", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.current, nil)
  end
  
  def test_correct_line_returned_when_first_line_is_a_log
    io = StringIO.new("2016-01-13 22:28:09,834 INFO Log line 1\n2016-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.current.raw_content, "2016-01-13 22:28:09,834 DEBUG Log line 2")
  end

  def test_correct_line_returned_when_first_line_is_not_a_log
    io = StringIO.new("2016-01-13 22:28:09,834 INFO Log line 1\n20-01-13 22:28:09,834 DEBUG Log line 2", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.current.raw_content, "2016-01-13 22:28:09,834 INFO Log line 1\n20-01-13 22:28:09,834 DEBUG Log line 2")
  end

  def test_correct_line_for_each_call_of_next
    io = StringIO.new("2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n2016-01-13 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.next.raw_content, "2016-01-13 22:28:09,834 DEBUG Log line 2\npart2")
    assert_equal(lr.next.raw_content, "2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
    assert_equal(lr.next, nil)
  end

  def test_correct_line_for_each_call_of_next_for_aliased_lines
    io = StringIO.new("abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\ndef 2016-01-13 22:28:09,834 DEBUG Log line 2\npart2", 'r')
    io.seek(0, IO::SEEK_END)
    lr = LogMerge::ReverseLogReader.new(io)
    assert_equal(lr.next.raw_content, "def 2016-01-13 22:28:09,834 DEBUG Log line 2\npart2")
    assert_equal(lr.next.raw_content, "abc 2016-01-13 22:28:09,834 INFO Log line 1\npart2\npart3\n")
    assert_equal(lr.next, nil)
  end
  
end
