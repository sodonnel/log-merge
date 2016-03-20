module LogMerge

  class LogLineBuilder

    def self.build(lines, log_alias=nil)
      return nil unless lines

      entry = LogLine.new
      pieces = lines.split(/\s/, 4)
      # Throw away all the content, as we don't need it for anything
      pieces.pop

      if pieces.length == 3
        entry.level     = pieces.pop
      end
                                                            # 2016-01-13 22:28:09,834
      entry.timestamp = DateTime.strptime(pieces.join(" "), "%Y-%m-%d %H:%M:%S,%L")
      entry.content  = lines
      entry.log_alias = log_alias
      entry
    end

  end

end
