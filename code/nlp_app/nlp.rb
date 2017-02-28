require 'sinatra/base'
require 'read_data'
require 'rjb'
class Nlp < Sinatra::Base
    @content = ""
    @output = ""
    @@data_classified = {}
    @training_output = "Chưa có ngữ liệu huấn luyện"
    @statistics = ""
    @@classifier = nil
    @@train = nil
    data_path = "./data"
    # file_path = "./data/import_file.txt"
    source = "./data/source.txt"
    target = "./data/target.txt"
    # meteor_path = "../../../../meteor-1.5"
    meteor_path = "/Users/me865/Documents/Learning/Master/NLP/Tools/meteor-1.5"
    get '/' do
      # puts "run get"
      @content = ""
      @content2 = ""
      if File.exists?(source)
        data = []
        File.open(source).each do |line|
          data << line
        end
        @content = data.join("")
        read_data = ReadData.new
        #@output = read_data.data_output
      else
        @content = "Data not found"
      end

      if File.exists?(target)
        data = []
        File.open(target).each do |line|
          data << line
        end
        @content2 = data.join("")
        read_data = ReadData.new
        #@output = read_data.data_output
      else
        @content2 = "Data not found"
      end
      read_data = ReadData.new
      #@@data_classified = read_data.get_data_fce("./data/test_json.xml")
      
      unless @@data_classified.nil?
        @data_output = read_data.build_output_data(@@data_classified)
        @statistics = read_data.build_statistics(@@data_classified)
      else
        @data_output = []
      end

      unless @@train.nil?
        @training_output = "Ngữ liệu đã được huấn luyện"
      else
        @training_output = "Chưa có ngữ liệu huấn luyện"
      end

      erb :home
    end

    # post '/' do
    #   puts "run post"
    #   @content = params["content"]
    #   # puts "content --> #{@content}"
    #   import_file = File.open(file_path, 'w')
    #   import_file.write("")
    #   import_file.write(@content)
    #   import_file.close
    #   read_data = ReadData.new
    #   data_input = read_data.get_data_demo(file_path)
    #   puts "data input --> #{data_input}"
    #   read_data.generate_data_meteor(data_input)

    #   # Chay cau lenh Meteor
    #   meteor_cmd = "java -Xmx2G -cp #{meteor_path}/meteor-*.jar Matcher #{data_path}/source_meteor.txt #{data_path}/target_meteor.txt -l en > #{data_path}/result_meteor.txt"
    #   `#{meteor_cmd}`

    #   # Parse data generate tu file result_meteor
    #   data_aligned = read_data.get_data_meteor_1_5(data_path + "/result_meteor.txt")

    #   # insert unaligned and remove Meteor tag
    #   data_aligned = read_data.insert_unaligned(data_aligned)
    #   data_aligned = read_data.remove_all_tags(data_aligned)

    #   # Parse file ra dang ARFF dua vao weka
    #   read_data.print_arff(data_aligned)

    #   # read_data.build_weka_naivebayes(data_path + "/SWA_20.arff")
    #   if @@classifier.nil? || @@train.nil?
    #     redirect '/'
    #   end
    #   classification_results = read_data.build_weka_svm_test(data_path + "/arff.arff", @@classifier, @@train)
    #   @@data_classified = read_data.assign_classification_results(data_aligned, classification_results)
    #   # weka_cmd = "java -classpath ./lib/weka.jar weka.classifiers.functions.LibSVM -t ./data/SWA_20.arff"
    #   redirect '/'
    # end

    post '/' do
      puts "run post"
      @content = params["content"]
      @content2 = params["content2"]
      # puts "content --> #{@content}"
      file1 = File.open(source, 'w')
      file2 = File.open(target, 'w')
      file1.write("")
      file1.write(@content)
      file1.close
      file2.write("")
      file2.write(@content2)
      file2.close
      read_data = ReadData.new
      data_input = read_data.get_data_demo(file1,file2)
      puts "data input --> #{data_input}"
      read_data.generate_data_meteor(data_input)

      # Chay cau lenh Meteor
      meteor_cmd = "java -Xmx2G -cp #{meteor_path}/meteor-*.jar Matcher #{data_path}/source_meteor.txt #{data_path}/target_meteor.txt -l en > #{data_path}/result_meteor.txt"
      `#{meteor_cmd}`

      # Parse data generate tu file result_meteor
      data_aligned = read_data.get_data_meteor_1_5(data_path + "/result_meteor.txt")

      # insert unaligned and remove Meteor tag
      data_aligned = read_data.insert_unaligned(data_aligned)
      data_aligned = read_data.remove_all_tags(data_aligned)

      # Parse file ra dang ARFF dua vao weka
      read_data.print_arff(data_aligned)

      # read_data.build_weka_naivebayes(data_path + "/SWA_20.arff")
      if @@classifier.nil? || @@train.nil?
        redirect '/'
      end
      classification_results = read_data.build_weka_svm_test(data_path + "/arff.arff", @@classifier, @@train)
      @@data_classified = read_data.assign_classification_results(data_aligned, classification_results)
      # weka_cmd = "java -classpath ./lib/weka.jar weka.classifiers.functions.LibSVM -t ./data/SWA_20.arff"
      redirect '/'
    end

    post "/training" do
      puts "Start training"
      read_data = ReadData.new
      @@classifier, @@train = read_data.build_weka_svm_train(data_path + "/SWA_20.arff")
      puts "End training"
      redirect '/'
    end
end