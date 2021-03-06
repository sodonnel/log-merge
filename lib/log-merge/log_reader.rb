module LogMerge

  class LogReader

    # 
    #    DATE_FORMAT = /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}/
    # Matches lines that start with dates 2016-01-13 22:28:09,834 or
    # lines that start xxxx123 2016-01-13 22:28:09,834 - ie have an alias before the log
    DATE_FORMAT =  /^(?:[^\s]+\s)?\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}/

    MATCHER = /^                                             # STARTS WITH
              (?:([^\s]+)\s)?                                 #   optional alias
              (\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3})    #   date
              \s?                   
              ([^\s]*)                                        #   log level
               \s?
              (.*)\Z/mx                                       #   rest of line

    attr_reader :io_position
    attr_accessor :index


    def initialize(io, log_alias = nil)
      @log_alias   = log_alias
      @fh = io
      @current_line    = nil
      @next_log_bugger = nil
      @io_position     = @fh.pos
      @reached_eof     = false
      @index           = nil

      # To allow peeking ahead in the stream without advancing the
      # iterator, we find and buffer the next entry before anything
      # else can run
      fill_next_log_buffer
    end

    def previous
    end

    def current
      unless @current_line
        self.next
      end
      @current_line
    end
    
    def next
      @current_line = read_full_log_entry
    end


    # Moves the IO stream forward to the passed date / datetime
    # such that the passed date is equal to or less than the current
    # log line timestamp.
    #
    # If the stream is at EOF or if the requested timestamp is after EOF
    # then this method returns silently, but a call to next will return nil
    #
    # If the stream has already advanced past the requested date, then this method
    # will silently return and current / next will be unchanged
    def skip_to_time(ts)
      unless ts.is_a?(Date)
        raise "#{ts.class} is not a Date or Date subclass"
      end

      # If the index has been set, then use it to find a position to start
      # searching from, otherwise we just search from wherever the io_stream
      # is already at, which is slow if the file is large
      if @index
        pos = @index.io_position_for_dtm(ts)
        if pos && pos > @io_position
          # Then we have to move the stream forward to new pos. To do that, we need
          # to reset the stream by clearing current_line and the next_log_buffer
          # and then resetting next_log_buffer
          @current_line = nil
          @next_log_buffer = nil
          @fh.seek(pos, IO::SEEK_SET)
          @io_position = pos
          fill_next_log_buffer
        end
        # If POS was earlier than the current position, it means the stream
        # is already after the requested dtm, so current / next will be unchanged
        # when this method returns
      end
      
      # Peek at @next_log_buffer as we know if contains at least the first
      # line of a log entry and this lets us test if the next line matches
      # without advancing the iterator
      loop do
        if @reached_eof || ts <= @next_log_buffer.timestamp
          break
        end
        self.next
      end
    end

    # Allow the actual logReader objects to be sorted based on their
    # current log entry timestamp. Note that calling this method will
    # populate current but calling next, so it will advance the iterator
    #
    # TODO - should this use @next_log_buffer to peek ahead if current not populated?
    #        which would prevent the iterator potentially being advanced by the compare
    def <=> obj
      me    = self.current
      other = obj.current
      if me == nil && other == nil
        0
      elsif me == nil
        1
      elsif other == nil
        -1
      else
        me <=> other
      end
    end
    

    private

    def fill_next_log_buffer
      # If the buffer has something in it, just return
      return if @next_log_buffer
      return if @reached_eof
      
      # Read the IO object until we get a line that starts a log message
      # If we hit EOF, set the flag
      begin
        loop do
          line = @fh.readline
          if line.match(MATCHER)
            @next_log_buffer = LogLine.new(line, $1 || @log_alias, $2, $3, $4)
            # NOTE we don't advance the io_position here as the user of
            # the LogReader has not yet see this line by calling next or current
            break
          end
        end
      rescue EOFError
        @reached_eof = true
      end
    end

    # Log entry can run over multiple lines in the file - think of a
    # stack track which really belongs to the log line above it
    def read_full_log_entry
      if @reached_eof
        return nil
      end

      # Here we have found a log line, as there must at least be one in @next_log_buffer
      # Here we need to read more lines until we find another log line match, which will
      # replace the contents of the buffer
      this_log_line = @next_log_buffer
      begin
        loop do
          # Need to keep the position which matches the last line seen by the reader, ie any buffered lines
          # should not count toward the position. So get the position before each readline. That means it will
          # always hold the trailing lines end position
          @io_position = @fh.pos
          line = @fh.readline
          if line.match(MATCHER)
            @next_log_buffer = LogLine.new(line, $1 || @log_alias, $2, $3, $4)
            break
          else
            this_log_line.append(line)
          end
        end
      rescue EOFError
        # The logReader should not close the IO object passed to it.
        @next_log_buffer = nil
        @reached_eof = true
      end
      this_log_line
    end
    
  end
  
end
