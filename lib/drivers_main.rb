require 'rubygems'
require 'yaml'
require 'fileutils'
require 'httparty'
require_relative 'helper'
require 'win32/registry.rb'


class DriverManager

  def initialize
    p @system = Gem::Platform.local.to_a.compact # ler as configuracoes da maquina.
    @path = __dir__ + "/data/list_cmds.yml"
    @dados = YAML::load_file(File.join(@path)) # dados do arquivo .yml
    @drivers = []
  end

  def read_yml(dados = @dados)
    case
    when @system.include?("mingw32") then
      osarchitecture == "32" ? win32 : win64
    when @system.include?("mingw64") then
      win64
    when ((@system.include?('linux')) && (@system.include?('x86'))) then
      linux32
    when ((@system.include?('linux')) && (@system.include?('x86_64'))) then
      linux64
    else
      puts 'Seu sistema não tem suporte no momento!'
      exit
    end
  end

  def linux32(dados = @dados)
    @drivers << dados['linux32']['firefox']
    @drivers << dados['linux32']['chrome']
  end

  def linux64(dados = @dados)
    @drivers << dados['linux64']['firefox']
    @drivers << dados['linux64']['chrome']
  end

  def win32(dados = @dados)
    @drivers << dados['win32']['firefox']
    @drivers << dados['win32']['chrome']
  end

  def win64(dados = @dados)
    @drivers << dados['win64']['firefox']
    @drivers << dados['win64']['chrome']
  end

  def runner
    read_yml # ler os dados do yml com relacao aos drivers.
    location = RbConfig::CONFIG["bindir"] # pegando o local pro ruby.
    FileUtils.makedirs("tmp") unless File.exists?(__dir__ + "/tmp/")
    @drivers.each {|hash|
      name = hash['name']
      link = hash['link']
      file_path = __dir__ + "/tmp/" + name
      unless File.exists?(file_path)
        begin
          download(name, link)
        rescue
          reg if @system.include?("mingw")
          download(name, link)
        end
      end
      extract_zip(file_path, location, name) if name.include?(".zip")
      extract_gz(file_path, location, name) if name.include?(".gz")
    }
  end

  def download(name, link)
    File.open(__dir__ + "/tmp/" + name, "wb") do |file|
      file << HTTParty.get(link)
    end
  end

  def reg
    Win32::Registry::HKEY_CURRENT_USER.open('Environment', Win32::Registry::KEY_WRITE) do |reg|
      reg['SSL_CERT_DIR'] = __dir__ + '\data'
      reg['SSL_CERT_FILE'] = __dir__ + '\data\cacert-2018-06-20.pem'
    end
  end
end

test = DriverManager.new
test.runner
FileUtils.rm_r Dir.glob(__dir__ + '/tmp/*'), :force => true