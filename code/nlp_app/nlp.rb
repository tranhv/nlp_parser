require 'sinatra/base'
require 'read_data'
require 'rjb'
class Nlp < Sinatra::Base
    @content = ""
    @output = ""
    data_path = "./data"
    file_path = "./data/import_file.txt"
    # meteor_path = "../../../../meteor-1.5"
    meteor_path = "/Users/me865/Documents/Learning/Master/NLP/Tools/meteor-1.5"
    get '/' do
      # puts "run get"
      @content = ""
      if File.exists?(file_path)
        data = []
        File.open(file_path).each do |line|
          data << line
        end
        @content = data.join("")
        read_data = ReadData.new
        #@output = read_data.data_output
      else
        @content = "Data not found"
      end
      puts " content -->#{@content}---"
      read_data = ReadData.new
      @data_output = read_data.build_output_data(read_data.get_data_fce("./data/test_json.xml"))
      puts "data --> #{@data_output.inspect}"
      erb :home
    end

    post '/' do
      puts "run post"
      @content = params["content"]
      # puts "content --> #{@content}"
      import_file = File.open(file_path, 'w')
      import_file.write("")
      import_file.write(@content)
      import_file.close
      read_data = ReadData.new
      data_input = read_data.get_data_demo(file_path)
      puts "data input --> #{data_input}"
      read_data.generate_data_meteor(data_input)

      # Chay cau lenh Meteor
      meteor_cmd = "java -Xmx2G -cp #{meteor_path}/meteor-*.jar Matcher #{data_path}/source_meteor.txt #{data_path}/target_meteor.txt -l en > #{data_path}/result_meteor.txt"
      `#{meteor_cmd}`

      # Parse data generate tu file result_meteor
      data_aligned = read_data.get_data_meteor_1_5(data_path + "/result_meteor.txt")

      # Parse file ra dang ARFF dua vao weka

      # read_data.build_weka_naivebayes(data_path + "/SWA_20.arff")
      read_data.build_weka_svm(data_path + "/SWA_20.arff")
      # weka_cmd = "java -classpath ./lib/weka.jar weka.classifiers.functions.LibSVM -t ./data/SWA_20.arff"
      redirect '/'
    end

    
end