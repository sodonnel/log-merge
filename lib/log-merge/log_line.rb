module LogMerge

  class LogLine
    attr_accessor :level, :log_alias, :content, :raw_content

    def initialize(raw_line=nil, lalias=nil, ts=nil, lvl=nil, rest=nil)
      @raw_content = raw_line
      @log_alias = lalias
      @timestamp = ts
      @level = lvl
      @content = rest
    end

    def append(line)
      raw_content << line
      content << line
    end

    def timestamp=(val)
      @timestamp = val
      @converted_timestamp = nil
    end
    
    def timestamp
      @converted_timestamp ||= DateTime.strptime(@timestamp, "%Y-%m-%d %H:%M:%S,%L")
    end

    def to_s
      @raw_content
    end

    def content_with_alias
      if log_alias
        "#{log_alias} #{raw_content}"
      else
        content
      end
    end

    def <=> obj
      timestamp <=> obj.timestamp
    end

  end

end
