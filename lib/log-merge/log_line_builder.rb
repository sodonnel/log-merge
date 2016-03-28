module LogMerge

  class LogLineBuilder

    def self.build(lines, log_alias=nil)
      return nil unless lines

      entry = LogLine.new

      # STARTS_WITH
      #   optional alias
      #   date 
      #   level
      #   rest of content# END OF STRING
      
      lines =~ /^
              (?:([^\s]+)\s)?                                 # optional alias
              (\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3})    # date
              \s                    
              ([^\s]+)                                        # log level
               \s+
              (.+)\Z/mx                                       # rest of lines

      entry.content      = $4
      entry.level        = $3
                                                 # 2016-01-13 22:28:09,834
      entry.timestamp    = DateTime.strptime($2, "%Y-%m-%d %H:%M:%S,%L")
      entry.raw_content  = lines
      entry.raw_content  = lines
      entry.log_alias    = log_alias || $1
      entry
    end

  end

end
