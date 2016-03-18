class Get_data
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"

	def get_data(in_path,out_path_source,out_path_target)
		begin
			first_line = ''
			contents = ''

			flag = false
			source_file = File.open(out_path_source,"a+")
			target_file = File.open(out_path_target,"a+")

			#source_file.write("gigi start ------- #{in_path}\n")
			#target_file.write("gigi start ------- #{in_path}\n")
			file = File.open(in_path, "r").each do |line|

				if (flag == true)
					flag = false
					target_file.write(line)
					next
				end
				next if line.match(/^</)			# if the first character of the line is < --> skip this line
				#next if !/\A\d+\z/.match(line[0,1]) 
				next if line.strip.match(/\A\d+\z/)			# if the line is numeric --> skip this line
				source_file.write(line)
				flag = true							# if we have written a line --> mark the flag and we will skip the next line
			end

			#source_file.write("gigi end ------- #{in_path}\n")
			#target_file.write("gigi end ------- #{in_path}\n")
		
		rescue Exception => e
			puts "Error happened in #{e.message}"
		end

	end
	 def main
    files = Dir.new(INPUT_PATH).entries
	
	source_file = File.open("./output/source.txt","w")
	source_file.write("")

	target_file = File.open("./output/target.txt","w")
	target_file.write("")
	
    files.each do |file|
      if file != "." and file != ".." and file != ".DS_Store"
        in_path = "#{INPUT_PATH}/#{file}"
        out_source_path = "#{OUTPUT_PATH}/source.txt"
        out_target_path = "#{OUTPUT_PATH}/target.txt"

		puts "in_put: #{in_path}"
		puts "out_put: #{out_source_path} - #{out_target_path}"
		get_data(in_path,out_source_path,out_target_path)

      end
    end
  end
end

obj = Get_data.new
obj.main
