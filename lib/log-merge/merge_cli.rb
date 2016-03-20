module LogMerge

  class MergeCLI

    def self.run(args)

      files = []

      opts = OptionParser.new do |opts|
        opts.on("-f", "--file FILE", "Files to merge") do |f|
          file_struct = OpenStruct.new
          file_struct.filename = f
          file_struct.alias    = nil
          files.push file_struct
        end

        opts.on("-a", "--alias ALIAS", "Alias for previous file") do |f|
          files.last.alias    = f
        end        

        opts.on("-o", "--output FILENAME", "Override default output filename") do |f|
          files.last.alias    = f
        end        


      end

      opts.parse(args)

      combiner = LogCombiner.new
      files.each do |f|
        fh = File.open(f.filename)
        combiner.add_log_reader(LogMerge::LogReader.new(fh, f.alias))
      end
      output = File.open('merged.txt', 'w')
      combiner.merge(output)
    end

  end

end
