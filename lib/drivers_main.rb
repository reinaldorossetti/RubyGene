require 'open3'
require 'yaml'
require 'fileutils'
require 'httparty'
require 'rubygems'
require 'zip'
require 'rubygems/package'
require 'zlib'

p @system = Gem::Platform.local.to_a # ler as configuracoes da maquina.
@path = __dir__ + "/commands/list_cmds.yml"
dados=YAML::load_file(File.join(@path)) # dados do arquivo .yml
@cmds, @url, @file = [], nil, nil # inicializando as variaveis.
p @location = RbConfig::CONFIG["bindir"] # pegando o local pro ruby.
@drivers = []
TAR_LONGLINK = '././@LongLink'

def extract_zip(file, destination)
  ::Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

def extract_gz(tar_gz_archive, destination)
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
      dest = nil
    end
  end
end

case
when @system.include?("mingw32") then
  @drivers << [dados['win32']['ff_name'], dados['win32']['firefox']]
  @drivers << [dados['win32']['chr_name'], dados['win32']['chrome']]
when ((@system.include?('linux')) && (@system.include?('x86'))) then
  @drivers << [dados['linux32']['ff_name'], dados['linux32']['firefox']]
  @drivers << [dados['linux32']['chr_name'], dados['linux32']['chrome']]
when ((@system.include?('linux')) && (@system.include?('x86_64'))) then
  @drivers << [dados['linux64']['ff_name'], dados['linux64']['firefox']]
  @drivers << [dados['linux64']['chr_name'], dados['linux64']['chrome']]
else
    puts 'Seu sistema não tem suporte no momento!'
    exit
end

FileUtils.makedirs("tmp") unless File.exists?(__dir__ + "/tmp/")

@drivers.each{|name, link|
  file_path = __dir__ + "/tmp/" + name
  unless File.exists?(file_path)
    File.open( __dir__ + "/tmp/" + name, "wb") do |file|
      file << HTTParty.get( link )
    end
  end
  extract_zip(file_path, @location) if name.include?(".zip")
  extract_gz(file_path, @location) if name.include?(".gz")
}
