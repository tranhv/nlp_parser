class ReadData
  DATA_PATH = "./data"

  def get_aln
    array_alns = []
    File.open(DATA_PATH + "/full_aln.txt", 'r').each do |line|
      array_alns << line
    end
    return array_alns
  end

  def get_crp_1
    array_crp = []
    File.open(DATA_PATH + "/full_crp.txt", 'r').each do |line|
      array_crp << line
    end
    return array_crp
  end

  def get_crp
    array_crps = []
    arr = []
    flag_para = false
    alns = get_aln
    index_aln = 0
    File.open(DATA_PATH + "/full_crp.txt", 'r').each_with_index do |line, index|      
      if (index%3 == 0)
        arr = []
        arr << line
        next
      end

      if (index - 1)%3 == 0
        arr << line
        next
      end

      if (index - 2)%3 == 0
        arr << line
        arr << alns[index_aln]
        array_crps << arr
        index_aln += 1
      end
    end
    return array_crps
  end

  def merge_aln_crp_1(output_file)
    array_aln = get_aln
    array_crp = get_crp
    
    flag = false
    array_crp.each_with_index do |line, index|
      if (flag == true)
        flag = false
        output_file.write(line)
        output_file.write(array_aln[index])
        next
      end
      next if line.match(/^</)      # if the first character of the line is < --> skip this line
      next if line.strip.match(/\A\d+\z/)     # if the line is numeric --> skip this line
      output_file.write(line)
      flag = true             # if we have written a line --> mark the flag and we will skip the next line
    end
  end

  def merge_aln_crp(output_file)
    array_crp = get_crp
    
    array_crp.each_with_index do |line, index|
      if not line[1].match(/^</)
        output_file.write(line[1].to_s)
        output_file.write(line[2].to_s)
        output_file.write(line[3].to_s)
        output_file.write("\n")
      end
    end
  end  

  def main
    merged_aln_crp = File.open(DATA_PATH + "/merged_aln_crp.txt","w")
    merged_aln_crp.write("")
    puts "#{merged_aln_crp}"

    merge_aln_crp(merged_aln_crp)
  end 

end


obj = ReadData.new
obj.main
