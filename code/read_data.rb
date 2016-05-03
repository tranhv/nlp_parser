class ReadData
  DATA_PATH = "./data"
  Sentence_Pair = Struct.new(:source, :target, :Alignment)
  Alignment = Struct.new(:source_numbers, :target_number, :tag_name)

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
    merge_aln_crp(merged_aln_crp)

    data = get_data(DATA_PATH + "/merged_aln_crp.txt")
 
    puts "#{count_alignment(data)}"
  end 

  #Input: file
  #Output: Array of sentence pairs
  #:Alignment is a array of Alignment struct
  def get_data(path)
    data = []
    sentence_pair = Sentence_Pair.new
    File.open(path, 'r').each_with_index do |line, index|
      if (index%4 == 0)
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line
        next
      end

      if (index - 1)%4 == 0
        sentence_pair.target = line
        next
      end

      if (index - 2)%4 == 0
        sentence_pair.Alignment = parse_alignment(line)
        data << sentence_pair
      end
    end
    data.each_with_index do |line, index|
      puts "#{line}"
      puts "\n"
      break if index > 4
    end
    return data
  end

  # parse a line in Yawat format into an Alignment struct
  def parse_alignment(align)
    data = []
    arr = align.split(" ")
    arr.delete_at(0)
    arr.each_with_index do |e, index|
      data << Alignment.new(e.split(":")[0], e.split(":")[1], e.split(":")[2])
    end
    return data
  end

  def count_alignment(sentence_pair_array)
    count = 0
    sentence_pair_array.each_with_index do |pairs, index|
      count = count + pairs.Alignment.length 
    end
    return count
  end

  def compare_alignment(align1, align2)
    align1.each_with_index do |
  end

end


obj = ReadData.new
obj.main

