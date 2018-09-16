require 'rubygems'
require 'yaml'
require 'fileutils'
require 'httparty'
require_relative 'helper'

class DriverManager

  def initialize
    p @system = Gem::Platform.local.to_a.compact # ler as configuracoes da maquina.
    @path = __dir__ + "/commands/list_cmds.yml"
    @dados = YAML::load_file(File.join(@path)) # dados do arquivo .yml
    @cmds, @url, @file = [], nil, nil # inicializando as variaveis.
    @drivers = []
  end

  def read_yml(dados=@dados)
    case
    when @system.include?("mingw32") && osarchitecture=="32" then
      @drivers << [dados['win32']['ff_name'], dados['win32']['firefox']]
      @drivers << [dados['win32']['chr_name'], dados['win32']['chrome']]
    when @system.include?("mingw64") || osarchitecture=="64" then
      @drivers << [dados['win64']['ff_name'], dados['win64']['firefox']]
      @drivers << [dados['win64']['chr_name'], dados['win64']['chrome']]
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
  end

  def runner
    read_yml # ler os dados do yml com relacao aos drivers.
    location = RbConfig::CONFIG["bindir"] # pegando o local pro ruby.
    FileUtils.makedirs("tmp") unless File.exists?(__dir__ + "/tmp/")
    @drivers.each{|name, link|
      file_path = __dir__ + "/tmp/" + name
      unless File.exists?(file_path)
        File.open( __dir__ + "/tmp/" + name, "wb") do |file|
          file << HTTParty.get( link )
        end
      end
      extract_zip(file_path, location, name) if name.include?(".zip")
      extract_gz(file_path, location, name) if name.include?(".gz")
    }
  end
end

test = DriverManager.new
test.runner
