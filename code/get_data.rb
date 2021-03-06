# Replace create_source and create_target

# Create source and target file from file full
# by removing all latex tags and number,
# extracting the first and second sentence in each pair,
# and putting them to corresponding files

class Get_data
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  PATH = "./data"

  def get_data(in_path,source_file,target_file)
    begin
     first_line = ''
     contents = ''

     flag = false
      file = File.open(in_path, "r").each do |line|
        if (flag == true)
          flag = false
          target_file.write(line)
          next
        end
        # puts "line --> #{line}"
        next if line.match(/^</)      # if the first character of the line is < --> skip this line
        #next if !/\A\d+\z/.match(line[0,1]) 
        next if line.strip.match(/\A\d+\z/)     # if the line is numeric --> skip this line
        source_file.write(line)
        flag = true             # if we have written a line --> mark the flag and we will skip the next line
      end      
    rescue Exception => e
      puts "Error happened in #{e.message}"
      #puts line
    end

  end
  def main
    files = Dir.glob(PATH + "/full_crp_quynhanh.txt").entries

    source_file = File.open("./data/source_quynhanh.txt","w")
    source_file.write("")

    target_file = File.open("./data/target_quynhanh.txt","w")
    target_file.write("")

    source_file = File.open(source_file,"a+")
    target_file = File.open(target_file,"a+")


    files.each do |file|
      if file != "." and file != ".." and file != ".DS_Store"
        # puts "in_put: #{file}"
        # puts "out_put: #{source_file.inspect} - #{target_file.inspect}"
        get_data(file,source_file,target_file)
      end
    end

    target_file.close
    source_file.close

  end
end

obj = Get_data.new
obj.main
