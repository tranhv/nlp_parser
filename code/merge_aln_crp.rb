# Merge full_aln.txt and full_crp.txt
# Input: Corpus *.aln, *.crp
# Output: full.txt

class Merge_aln_crp
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  

  def join_files(in_path,out_path)
  
  	begin
		first_line = ''
		contents = ''

		flag = false
		join_file = File.open(out_path,"a+")
		file = File.open(in_path, "r").each do |line|

			if (flag == true)
				flag = false
				next
			end
			next if line.match(/^</)			# if the first character of the line is < --> skip this line
			#next if !/\A\d+\z/.match(line[0,1]) 
			next if line.strip.match(/\A\d+\z/)			# if the line is numeric --> skip this line
			join_file.write(line)
			flag = true							# if we have written a line --> mark the flag and we will skip the next line
			
		end
		
	rescue Exception => e
		puts "Error happened in #{e.message}"
	end
  
  end
  
 def main
    file1 = File.open(INPUT_PATH + "/full_aln.txt", 'r').readlines
    file2 = File.open(INPUT_PATH + "/full_crp.txt", 'r').readlines
		
	
	
	join_file = File.open("./output/full.txt","w")
	join_file.write("")

	out_path = "#{OUTPUT_PATH}/full.txt"
    join_file = File.open(out_path,"a+")

    file1.each_with_index do |line1, index|
    	
    	puts "index: #{index}"
    	puts "line1: #{line1}"
    	line2 = file2[index]
    	puts "line2: #{line2}"

      	#join_files(line1, line2, out_path)
      	
    end
    
    join_file.close

  end
  
end


obj = Merge_aln_crp.new
obj.main
