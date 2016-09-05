# Join all files having file extension aln in Input folder into one file "full_aln.txt"

class Join
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  
  def join_files(in_path,out_path, join_file)

  	begin
      first_line = ''
      contents = ''
      #i = 0
      file = File.open(in_path, "r").each do |line|
        #i += 1
        #if i == 1
          #puts "line -->#{line}----"
        #end
        #next if i == 1
        join_file.write(line)
     end

   rescue Exception => e
    puts "Error happened in #{e.message}"
  end
  
end

def main
  files = Dir.glob(INPUT_PATH + "/SWA/*.aln").sort.entries

  join_file = File.open("./output/full_aln_v2.txt","w")
  join_file.write("")
  out_path = "#{OUTPUT_PATH}/full_aln_v2.txt"
  

  files.each do |file|
    if file != "." and file != ".." and file != ".DS_Store"
      in_path = "#{file}"
      
      puts "in_put: #{in_path}"
      puts "out_put: #{out_path}"
      join_file = File.open(out_path,"a+")
      join_files(in_path,out_path,join_file)
      join_file.close

    end
  end

end

end
obj = Join.new
obj.main
