# REPLACED BY get_data

# Create target file from file full
# by extracting the second sentence in each pair
# and removing all latex tags and number 

class String
  def is_integer?
    self.to_i.to_s == self
  end
end

class Join
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  

  def join_files(in_path,out_path)
  
  	begin
		first_line = ''
		contents = ''

		flag = false
		join_file = File.open(out_path,"a+")
		file = File.open(in_path, "r").each do |line|

			
			# if the first character of the line is < --> skip this line
			next if line.match(/^</)
			#next if !/\A\d+\z/.match(line[0,1]) 

			# if the line is numeric --> skip this line
			#if line.match(/[0-9]/)
			if line.strip.match(/\A\d+\z/)
				flag = true
				next
			end

			if (flag == true)
				flag = false
				next
			end

			join_file.write(line)

		end
		
	rescue Exception => e
		puts "Error happened in #{e.message}"
	end
  
  end
  
    def main
    files = Dir.new(INPUT_PATH).entries

	header_file = File.open("./output/header.txt","w")
	header_file.write("")
	
	join_file = File.open("./output/target.txt","w")
	join_file.write("")
	
    files.each do |file|
      if file != "." and file != ".." and file != ".DS_Store"
        in_path = "#{INPUT_PATH}/#{file}"
        out_path = "#{OUTPUT_PATH}/target.txt"
		puts "in_put: #{in_path}"
		puts "out_put: #{out_path}"
		join_files(in_path,out_path)

      end
    end
  end
  
end


obj = Join.new
obj.main
