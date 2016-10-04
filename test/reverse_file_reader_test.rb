require './test_helper'

class ReverseFileReaderTest < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_read_all_lines_from_simple_file
    io = StringIO.new("line1\nline2\nline3\nline4", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    assert_equal(f.readline, "line4")
    assert_equal(f.readline, "line3\n")
    assert_equal(f.readline, "line2\n")
    assert_equal(f.readline, "line1\n")
    assert_raises EOFError do
      f.readline
    end
  end

  def test_read_all_lines_from_file_bigger_than_read_size
    io = StringIO.new("line1\nline2\nline3\nline4", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    f.read_size = 5
    assert_equal(f.readline, "line4")
    assert_equal(f.readline, "line3\n")
    assert_equal(f.readline, "line2\n")
    assert_equal(f.readline, "line1\n")
    assert_raises EOFError do
      f.readline
    end
  end

  def test_read_all_lines_from_file_with_position
    #                  0      6      12     18
    io = StringIO.new("line1\nline2\nline3\nline4", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    assert_equal(f.readline, "line4")
    assert_equal(f.pos, 18)
    assert_equal(f.readline, "line3\n")
    assert_equal(f.pos, 12)
    assert_equal(f.readline, "line2\n")
    assert_equal(f.pos, 6)
    assert_equal(f.readline, "line1\n")
    assert_equal(f.pos, 0)
    assert_raises EOFError do
      f.readline
    end
  end

  def test_correct_next_line_read_when_seek_set_to_boundry
    #                  0      6      12     18
    io = StringIO.new("line1\nline2\nline3\nline4", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    f.seek(18)
    assert_equal(f.readline, "line3\n")
    assert_equal(f.pos, 12)
  end

  def test_correct_next_line_read_when_seek_set_to_not_a_boundry
    #                  0      6      12     18
    io = StringIO.new("line1\nline2\nline3\nline4", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    f.seek(19)
    assert_equal(f.readline, "l")
    assert_equal(f.pos, 18)
    assert_equal(f.readline, "line3\n")
    assert_equal(f.pos, 12)
  end

  def test_correct_next_line_when_only_one_line_in_file
    io = StringIO.new("line1", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    assert_equal(f.readline, "line1")
    assert_equal(f.pos, 0)
  end

  def test_correct_behaviour_when_empty_file
    io = StringIO.new("", 'r')
    f  = LogMerge::ReverseFileReader.new(io)
    assert_raises EOFError do
      f.readline
    end
  end
      
end
