require 'sinatra/base'
class Nlp < Sinatra::Base
    @content = ""
    file_path = "./data/import_file.txt"
    get '/' do
      puts "run get"
      @content = ""
      if File.exists?(file_path)
        data = []
        File.open(file_path).each do |line|
          data << line
        end
        @content = data.join("")
      else
        @content = "Data not found"
      end
      puts " content -->#{@content}---"
      erb :home
    end

    post '/' do
      puts "run post"
      @content = params["content"]
      puts "content --> #{@content}"
      import_file = File.open(file_path, 'w')
      import_file.write("")
      import_file.write(@content)
      import_file.close
      redirect '/'
    end

    def alignment(path_file)
      
    end
end