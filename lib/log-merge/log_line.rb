module LogMerge

  class LogLine
    attr_accessor :timestamp, :level, :log_alias, :content

    def initialize
    end

    def to_s
      @content
    end

    def content_with_alias
      if log_alias
        "#{log_alias} #{content}"
      else
        content
      end
    end

    def <=> obj
      timestamp <=> obj.timestamp
    end

  end

end
