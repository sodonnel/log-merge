module LogMerge

  class LogReader

    # 2016-01-13 22:28:09,834
    DATE_FORMAT = /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3}/


    def initialize(io, log_alias = nil)
      @log_alias   = log_alias
      @fh = io
      @current_line    = nil
      @next_log_bugger = nil
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
      @current_line = LogLineBuilder.build(read_full_log_entry, @log_alias)
    end

    # Allow the actual logReader objects to be sorted based on their
    # current log entry timestamp. This allow use to find the next
    # log message in the sequence
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

    # Log entry can run over multiple lines in the file - think of a
    # stack track which really belongs to the log line above it
    def read_full_log_entry
      if @fh.closed?
        return nil
      end
      
      this_log_line = @next_log_buffer || ''

      # Handle the case where there is nothing in the next line buffer, which is usually
      # only when the log file is first opened. In that case you read until you first the
      # first log line, and then break.
      unless @next_log_buffer
        begin
          loop do
            line = @fh.readline
            if line.match(DATE_FORMAT)
              this_log_line << line
              break
            end
          end
        rescue EOFError
          @fh.close
          return nil
        end
      end
        
      # Here we have found a log line, either by the loop above, or from the next_log_buffer
      # Here we need to read more lines until we find another log line match, which will
      # replace the contents of the buffer
      begin
        loop do
          line = @fh.readline
          if line.match(DATE_FORMAT)
            @next_log_buffer = line
            break
          else
            this_log_line << line
          end
        end
      rescue EOFError
        @fh.close
      end
      this_log_line
    end
    
  end
  
end
