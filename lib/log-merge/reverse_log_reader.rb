module LogMerge

  class ReverseLogReader

    # 
    #    DATE_FORMAT = /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}/
    # Matches lines that start with dates 2016-01-13 22:28:09,834 or
    # lines that start xxxx123 2016-01-13 22:28:09,834 - ie have an alias before the log
    DATE_FORMAT =  /^(?:[^\s]+\s)?\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}/

    attr_accessor :index

    def initialize(io, log_alias = nil)
      @log_alias   = log_alias
      @fh = io
      @rfr = ReverseFileReader.new(io)
      # Whatever position the IO stream is at, we set the RFR to start reading there
      @rfr.seek(@fh.pos)
      
      @current_line    = nil
      @reached_eof     = false
      @index           = nil

    end

    def io_position
      @rfr.pos
    end

    def current
      unless @current_line
        self.next
      end
      @current_line
    end
    
    def next
      @current_line = LogLineBuilder.build(read_full_log_entry, @log_alias)
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
        if @reached_eof || ts <= LogLineBuilder.build(@next_log_buffer).timestamp
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
    #
    # TODO - As this is a reverse reader, what way should compares work?
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

    # As we are reading the file backwards, keep reading lines until you get one that
    # matches the start of a log entry.
    def read_full_log_entry
      if @reached_eof
        return nil
      end

      lines = []
      begin
        loop do
          line = @rfr.readline
          lines.unshift line
          if line.match(DATE_FORMAT)
            break
          end
        end
      rescue EOFError
        @reached_eof = true
        # Disguard any lines built up as the line starting the log message has not been found
        return nil
      end
      lines.join("")
    end
          
  end
  
end
