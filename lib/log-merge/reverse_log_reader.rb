module LogMerge

  class ReverseLogReader

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
      raise "not implemented"
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
      log_entry = nil
      begin
        loop do
          line = @rfr.readline
          if line.match(MATCHER)
            log_entry = LogLine.new(line, $1 || @log_alias, $2, $3, $4)
            break
          end
          lines.unshift line
        end
      rescue EOFError
        @reached_eof = true
        # Disguard any lines built up as the line starting the log message has not been found
        return nil
      end
      log_entry.append(lines.join(""))
      log_entry
    end
          
  end
  
end
