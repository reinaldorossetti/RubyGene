require 'zip'
require 'rubygems/package'
require 'zlib'
require 'open3'

TAR_LONGLINK = '././@LongLink'

def extract_zip(file, destination, name)
  ::Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
      puts "Driver #{name} instalado com sucesso em #{destination}"
    end
  end
end

def extract_gz(tar_gz_archive, destination, name)
  Gem::Package::TarReader.new( Zlib::GzipReader.open tar_gz_archive ) do |tar|
    dest = nil
    tar.each do |entry|
      if entry.full_name == TAR_LONGLINK
        dest = File.join destination, entry.read.strip
        next
      end
      dest ||= File.join destination, entry.full_name
      if entry.directory?
        FileUtils.rm_rf dest unless File.directory? dest
        FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
      elsif entry.file?
        FileUtils.rm_rf dest unless File.file? dest
        File.open dest, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod entry.header.mode, dest, :verbose => false
      elsif entry.header.typeflag == '2' #Symlink!
        File.symlink entry.header.linkname, dest
      end
      puts "Driver #{name} instalado com sucesso em #{destination}"
      dest = nil
    end
  end
end

# pega a versão do windows correto.
def osarchitecture
  o, e, s = Open3.capture3("wmic os get osarchitecture")
  o.gsub!(/\D/, '')
rescue => ex
  p ex
  return "32"
end
