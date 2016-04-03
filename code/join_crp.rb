# Join all files having file extension crp in Input folder into one file "full_crp.txt"

class Join
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  
  def join_files(in_path,out_path, join_file)

  	begin
      first_line = ''
      contents = ''
      file = File.open(in_path, "r").each do |line|
       join_file.write(line)
     end

   rescue Exception => e
    puts "Error happened in #{e.message}"
  end
  
end

def main
  files = Dir.glob(INPUT_PATH + "/SWA/*.crp").entries

  join_file = File.open("./output/full_crp.txt","w")
  join_file.write("")
  out_path = "#{OUTPUT_PATH}/full_crp.txt"
  join_file = File.open(out_path,"a+")

  files.each do |file|
    if file != "." and file != ".." and file != ".DS_Store"
      in_path = "#{file}"
      
      puts "in_put: #{in_path}"
      puts "out_put: #{out_path}"
      join_files(in_path,out_path,join_file)
    end
  end
  join_file.close

end

end
obj = Join.new
obj.main
