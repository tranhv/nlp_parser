# Correction Detection

class Get_data
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"

  def get_source
    array_source = []
    File.open(INPUT_PATH + "/source.txt", 'r').each do |line|
      array_source << line
    end
    return array_source
  end

  def get_target
    array_target = []
    File.open(INPUT_PATH + "/target.txt", 'r').each do |line|
      array_target << line
    end
    return array_target
  end

  def extract_basic_edits
    array_source = get_source
    array_target = get_target

    array_source.each_with_index do |line, index|
      tmp_source = array_source[index].split(" ")
      tmp_target = array_target[index].split(" ")
      tmp_source.
    end

  end

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
        next if line.match(/^</)      # if the first character of the line is < --> skip this line
        #next if !/\A\d+\z/.match(line[0,1]) 
        next if line.strip.match(/\A\d+\z/)     # if the line is numeric --> skip this line
        source_file.write(line)
        flag = true             # if we have written a line --> mark the flag and we will skip the next line
      end      
    rescue Exception => e
      puts "Error happened in #{e.message}"
    end

  end
  def main
    files = Dir.glob(INPUT_PATH + "/full_crp.txt").entries

    source_file = File.open("./output/source.txt","w")
    source_file.write("")

    target_file = File.open("./output/target.txt","w")
    target_file.write("")

    source_file = File.open(source_file,"a+")
    target_file = File.open(target_file,"a+")


    files.each do |file|
      if file != "." and file != ".." and file != ".DS_Store"
        puts "in_put: #{file}"
        puts "out_put: #{source_file.inspect} - #{target_file.inspect}"
        get_data(file,source_file,target_file)
      end
    end

    target_file.close
    source_file.close

  end
end

obj = Get_data.new
obj.main
