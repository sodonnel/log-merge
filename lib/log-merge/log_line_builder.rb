module LogMerge

  class LogLineBuilder

    def self.build(lines, log_alias=nil)
      return nil unless lines

      entry = LogLine.new
      pieces = lines.split(/\s/, 4)
      
      # Store the content without the leading date and level in stripped content
      entry.content = pieces.pop

      if pieces.length == 3
        entry.level     = pieces.pop
      end
                                                            # 2016-01-13 22:28:09,834
      entry.timestamp = DateTime.strptime(pieces.join(" "), "%Y-%m-%d %H:%M:%S,%L")
      entry.raw_content  = lines
      entry.log_alias = log_alias
      entry
    end

  end

end
