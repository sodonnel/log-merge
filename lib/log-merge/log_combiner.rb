module LogMerge

  class LogCombiner

    def initialize
      # List of LogReader objects
      @file_list = []
    end

    def add_log_reader(lr)
      @file_list.push lr
    end
    
    def merge(out_io)
      while 1
        top_reader = @file_list.sort!.first
        if top_reader.current.nil?
          # If the earliest sorted object has no line, then
          # there are no lines left, so exit
          break
        else
          out_io.puts top_reader.current.content_with_alias
          top_reader.next
        end
      end
    end
        
  end
  
end
