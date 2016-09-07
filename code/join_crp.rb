# Join all files having file extension crp in Input folder into one file "full_crp.txt"

class Join
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  PATH = "./data"
  
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
  files = Dir.glob(PATH + "/kigoshi/*.crp").sort.entries

  join_file = File.open("./data/full_crp_kigoshi.txt","w")
  join_file.write("")
  out_path = "#{PATH}/full_crp_kigoshi.txt"
  

  files.each do |file|
    if file != "." and file != ".." and file != ".DS_Store"
      in_path = "#{file}"
      
      join_file = File.open(out_path,"a+")
      join_files(in_path,out_path,join_file)
      join_file.close
    end
  end
end

end
obj = Join.new
obj.main
