module LogMerge

  class LogLineBuilder

    def self.build(lines, log_alias=nil)
      return nil unless lines

      entry = LogLine.new

      # After the alias and date, the remaining parts are optional. This is because
      # especially when reading backwards, you could start right in the middle of a line.
      # This cannot happen going forwards as it will read until it matches the leading alias+date.
      #
      # There is also the danger of a malformed log message that does not have a level
      # or content, so if the parts after the date are not present it would break the reader.
      # The date has to be present, as it is used to mark the start or a log - if it is not present
      # the logs is naturally part of the previous or next log entry.
      lines =~ /^                                             # STARTS WITH
              (?:([^\s]+)\s)?                                 #   optional alias
              (\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3})    #   date
              \s?                   
              ([^\s]*)                                        #   log level
               \s?
              (.*)\Z/mx                                       #   rest of lines

      entry.content      = $4
      entry.level        = $3
                                                 # 2016-01-13 22:28:09,834
      entry.timestamp    = DateTime.strptime($2, "%Y-%m-%d %H:%M:%S,%L")
      entry.raw_content  = lines
      entry.log_alias    = log_alias || $1
      entry
    end

  end

end
