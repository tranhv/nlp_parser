# Extract paraphrases from SWA and Blast
# Input: Corpus *.aln, *.crp and annotation file from Blast
# Output: paraphrases.txt

class Paraphrases
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"
  

  def paraphrases(out_path)
  
  	#begin
  		arr_para = []
  		arr = []

  		File.open(INPUT_PATH + "/full_ann_crp_aln.txt", 'r').each_with_index do |line, index|
  			#puts "line #{line.inspect}"
  			if (index%5 == 0)
  				arr = []
  				arr << line
  				next
  			end

  			if (index - 1)%5 == 0
  				arr << line
  				next
  			end

  			if (index - 2)%5 == 0
  				arr1 = line.split(" ")
  				arr_temp1 = []
  				arr1.each do |word1|
  					if word1.include? "para"
  						arr_temp1 << word1
  					end
  				end 
  				arr << arr_temp1
  				next
  			end

  			if (index - 3)%5 == 0
  				
  				arr2 = line.split(" ")
  				arr_temp2 = []
  				arr2.each do |word2|
  					if word2.include? "paraphrase"
  						arr_temp2 << word2
  					end
  				end 
  				arr << arr_temp2
  				arr_para << arr
  			end
  		end

  		extract_paraphrase = File.open(out_path, "w")
  		extract_paraphrase.write("")

  		arr_para.each do |arr|
  			arr.each_with_index do |line, index|
  				extract_paraphrase.write(line.gsub("\n","")) if index <= 1
  				extract_paraphrase.write(line.join(" ").gsub("\n","")) if index > 1 and line.count > 0
  				extract_paraphrase.write("\n")
  			end
  			extract_paraphrase.write("\n")
  		end
  		extract_paraphrase.close
		
	end
		
	#rescue Exception => e
		#puts "My error happened in #{e.message}"
	#end
  
  
 def main
   paraphrases("#{OUTPUT_PATH}/paraphrases.txt")
 end
  
end


obj = Paraphrases.new
obj.main
