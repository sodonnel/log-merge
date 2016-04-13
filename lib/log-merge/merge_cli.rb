module LogMerge

  class MergeCLI

    def self.run(args)

      files = []
      output_filename = "./merged"
      build_index     = true

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
          output_filename = f
        end        

        opts.on("--no-index", "Do not build an index when merging the files") do |f|
          build_index = false
        end        

      end

      opts.parse(args)

      combiner = LogCombiner.new
      files.each do |f|
        fh = File.open(f.filename)
        combiner.add_log_reader(LogMerge::LogReader.new(fh, f.alias))
      end
      File.open(output_filename, 'w') do |o|
        index_filename = "#{output_filename}.index"
        if !build_index
          # The combiner will not create an index unless
          # a filename is passed in, so if you don't want the
          # index, set the filename to nil
          index_filename = nil
        end
        combiner.merge(o, index_filename)
      end
    end

  end

end
