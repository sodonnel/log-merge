module LogMerge

  class LogLine
    attr_accessor :timestamp, :level, :log_alias, :content, :raw_content

    def initialize
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
