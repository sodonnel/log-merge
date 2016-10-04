module LogMerge
  class ReverseFileReader

    # TODO - limit max line length. If you get a really long line it will keep reading until OOM

    attr_writer :read_size, :max_buffer_size

    def initialize(fh)
      @fh              = fh
      @read_size       = 64*1024 # 64KB
      @max_buffer_size = 1024 * 1024 # 1MB
      
      @buffer = ''
      @lines  = []
      set_positions
    end

    def readline
      if @lines.length > 0
        line = @lines.pop
        @logical_pos -= line.length
        line
      else
        if @eof
          raise EOFError
        end
        fill_buffer
        readline
      end
    end
      
    def pos
      @logical_pos
    end

    def seek(val)
      @physical_pos = val
      @logical_pos  = val
    end

    private

    def fill_buffer
      @physical_pos -= @read_size
      bytes_to_read = @read_size
      if @physical_pos < 0
        # Indicates this read went past the start of the file
        # so we don't need to read again from the file. We need
        # to tidy up the positions and read length
        bytes_to_read += @physical_pos
        @physical_pos = 0
        @eof = true
      end
      @fh.seek(@physical_pos, IO::SEEK_SET)
      buff = @fh.read(bytes_to_read)
      buff = buff + @buffer
      # This regex splits on newline, but it retains the newline
      # character in the lines that are split out.
      @lines = buff.split(/(?<=\n)/)
      # The earliest line might be a partial line
      # so split it off unless EOF has been reached
      unless @eof
        @buffer = @lines.shift
      end
    end

    def set_positions
      @fh.seek(0, IO::SEEK_END)
      @physical_pos = @fh.pos
      @logical_pos = @fh.pos
    end

  end
end
