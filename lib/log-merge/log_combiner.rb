module LogMerge

  class LogCombiner

    require 'pp'
    
    def initialize
      # List of LogReader objects
      @file_list = []
      @index = Index.new
    end

    def add_log_reader(lr)
      @file_list.push lr
    end
    
    def merge(out_io, index_filename=nil)
      while 1
        top_reader = @file_list.sort!.first
        if top_reader.current.nil?
          # If the earliest sorted object has no line, then
          # there are no lines left, so exit
          break
        else
          if index_filename
            @index.index(top_reader.current, out_io.pos)
          end
          out_io.puts top_reader.current.content_with_alias
          top_reader.next
        end
      end
      if index_filename
        @index.save(index_filename)
      end
    end

  end

end
