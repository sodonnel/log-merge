Gem::Specification.new do |s| 
  s.name = "log-merge"
  s.version = "0.0.1"
  s.author = "Stephen O'Donnell"
  s.email = "stephen@appsintheopen.com"
  s.homepage = "http://appsintheopen.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A tool to merge log files and serve them on a local webserver"
  s.files = (Dir.glob("{bin,lib}/**/*") + Dir.glob("[A-Z]*")).reject{ |fn| fn.include? "temp" }

  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables << 'log-merge'
  s.description  = "A tool to merge log files and serve them on a local webserver"
#  s.autorequire = "name"
#  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
#  s.extra_rdoc_files = ["README"]
#  s.add_dependency("dependency", ">= 0.x.x")
end
