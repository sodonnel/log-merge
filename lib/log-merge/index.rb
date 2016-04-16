module LogMerge

  class Index

    attr_reader :index
    
    def initialize
      @index = Hash.new
      @index[:levels]  = Hash.new {|h,k| h[k] = 0 }
      @index[:aliases] = Hash.new {|h,k| h[k] = 0 }
      @index[:count]   = 0
      @index[:minutes] = Hash.new { |h,k|
        v = Hash.new
        v[:count]        = 0
        v[:log_position] = nil
        v[:aliases]      = Hash.new
        v[:levels]       = Hash.new
        h[k] = v
      }                           
    end
    
    def index(log_line, log_position=nil)
      date_to_minute = datetime_to_minute(log_line.timestamp)

      @index[:levels][log_line.level]  += 1
      @index[:aliases][log_line.log_alias] += 1
      @index[:count] += 1
      
      stat = @index[:minutes][date_to_minute]
      stat[:count] += 1
      unless stat[:log_position]
        stat[:log_position] = log_position
      end
      # Could have used default Hash values for this, but Marshal cannot serialize
      # them. If defaults are used, then you need to check all sub hashes inside
      # the :minutes key to remove them all
      stat[:levels][log_line.level] = (stat[:levels][log_line.level] || 0 ) + 1
      stat[:aliases][log_line.log_alias] = (stat[:aliases][log_line.log_alias] || 0) + 1      
    end

    def save(filename)
      # Marshal cannot serialize a hash with a default proc, so need to remove it
      @index.keys.each {|k|
        if @index[k].is_a?(Hash)
          @index[k].default = nil
        end
      }
      @index.default = nil
      File.open(filename, 'wb') {|f| f.write(Marshal.dump(@index))}
    end

    def load(filename)
      # reset anything that might be in the object already
      @index = nil
      @index = Marshal.load(File.binread(filename))
    end

    # Search through @index[:minutes] backwards for the first date earlier
    # than the passed date, then return the position
    def io_position_for_dtm(dtm)
      # Ruby returns hash keys in the order they were added. As they *should*
      # have been added in ascending order, it means there is no need to sort.
      @index[:minutes].keys.reverse_each do |k|
        if dtm >= k
          return @index[:minutes][k][:log_position]
        end
      end
      return 0
    end

    def aliases
      @index[:aliases].keys.sort
    end

    def levels
      @index[:levels].keys.sort
    end

    private

    def datetime_to_minute(dtm)
      dtm - ((dtm.sec + dtm.sec_fraction) / 86400.0)
    end

    
  end

end
