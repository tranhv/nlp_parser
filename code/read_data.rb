class ReadData
  DATA_PATH = "./data"
  Sentence_Pair = Struct.new(:source, :target, :Alignment)
  Alignment = Struct.new(:source_numbers, :target_numbers, :tag_name)

  def get_aln
    array_alns = []
    File.open(DATA_PATH + "/full_aln.txt", 'r').each do |line|
      array_alns << line
    end
    return array_alns
  end

  # def get_crp_1
  #   array_crp = []
  #   File.open(DATA_PATH + "/full_crp.txt", 'r').each do |line|
  #     array_crp << line
  #   end
  #   return array_crp
  # end

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

  # def merge_aln_crp_1(output_file)
  #   array_aln = get_aln
  #   array_crp = get_crp
    
  #   flag = false
  #   array_crp.each_with_index do |line, index|
  #     if (flag == true)
  #       flag = false
  #       output_file.write(line)
  #       output_file.write(array_aln[index])
  #       next
  #     end
  #     next if line.match(/^</)      # if the first character of the line is < --> skip this line
  #     next if line.strip.match(/\A\d+\z/)     # if the line is numeric --> skip this line
  #     output_file.write(line)
  #     flag = true             # if we have written a line --> mark the flag and we will skip the next line
  #   end
  # end

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
      get_data_giza(DATA_PATH + "/test.UA3.final")
    # merged_aln_crp = File.open(DATA_PATH + "/merged_aln_crp.txt","w")
    # merged_aln_crp.write("")
    # merge_aln_crp(merged_aln_crp)

    # data_SWA = get_data_SWA(DATA_PATH + "/merged_aln_crp.txt")
    # data_meteor_blast = get_data_meteor_blast(DATA_PATH + "/Annotation-5-with-preprocess.txt")
    # data_meteor_1_5 = get_data_meteor_1_5(DATA_PATH + "/result_meteor_1.5.txt")

    # data_SWA = convert_to_Meteor_tag(data_SWA)
    # data_meteor_blast = insert_unaligned(data_meteor_blast)
    # data_meteor_1_5 = insert_unaligned(data_meteor_1_5)

    # # tags = ["preserved", "bigrammar-vtense", "bigrammar-wform", "bigrammar-inter", "paraphrase", "unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "spelling", "duplicate"]
    # tags = ["exact", "stem", "syn", "para", "unaligned"]
    # puts "#{count_tags(data_SWA, tags)}"
    # puts "#{count_tags(data_meteor_blast, tags)}"
    # puts "#{count_tags(data_meteor_1_5, tags)}"
    # puts "\n"

    # puts "#{compare_data(data_SWA, data_meteor_blast, tags)}"
    # puts "#{compare_data(data_SWA, data_meteor_1_5, tags)}"
    # puts "#{compare_data(data_meteor_blast, data_meteor_1_5, tags)}"
    # puts "\n"

    # a, b, c = compare_data_on_tag(data_meteor_blast, data_meteor_1_5, "exact")

    # a.each_with_index do |line, index|
    #   puts "#{line}\n\n"
    #   break if index > 2
    # end

    #print_data(data_SWA)

    # identical, difference_swa, difference_meteor = compare_data_count(data_SWA, data_meteor_blast)
    # puts "#{identical}\n#{difference_swa}\n#{difference_meteor}\n"
    # puts "#{count_alignment(data_SWA)} , #{count_alignment(data_meteor_blast)}"

    # puts "#{data_SWA.length} , #{data_meteor_blast.length}, #{data_meteor_1_5.length}"


    # data_SWA.each_with_index do |line, index|
    #   puts "#{line}\n\n" if line.source.include? "The conditional probability of a label sequence"
    #   break if line.source.include? "The conditional probability of a label sequence"
    # end 
    # data_meteor_blast.each_with_index do |line, index|
    #   puts "#{line}\n\n" if line.source.include? "The conditional probability of a label sequence"
    #   break if line.source.include? "The conditional probability of a label sequence"
    # end 
    # data_SWA.each_with_index do |line, index|
    #   puts "#{line}\n\n" if index == 2784
    #   break if index == 2784
    # end
    # data_meteor_blast.each_with_index do |line, index|
    #   puts "#{line}\n\n" if index == 2784
    #   break if index == 2784
    # end

    # data_meteor_1_5.each_with_index do |line, index|
    #   puts "#{line}\n\n#{index}\n" if line.source.include? "A phrase-based SMT system"
    #   break if line.source.include? "A phrase-based SMT system"
    # end 

    # # Kiem tra rieng thuoc tinh source thi data 1 khac data 2 nhung gi
    # puts "#{data_meteor_1_5.collect{|e| e.source} - data_SWA.collect{|e| e.source}}"
  end

  #Input: file
  #Output: Array of sentence pairs
  #:Alignment is a array of Alignment struct
  def get_data_SWA(path)
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
        sentence_pair.Alignment = parse_alignment_SWA(line)
        data << sentence_pair
      end
    end

    return data
  end

  def get_data_meteor_blast(path)
    data = []
    sentence_pair = Sentence_Pair.new
    File.open(path, 'r').each_with_index do |line, index|
      
      next if index <= 2

      if ((index-3)%5 == 0)
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line
        next
      end

      if (index - 4)%5 == 0
        sentence_pair.target = line
        next
      end

      if (index)%5 == 0
        sentence_pair.Alignment = parse_alignment_meteor_blast(line)
        data << sentence_pair
      end
    end

    return data
  end  

  def get_data_meteor_1_5(path)
    data = []
    sentence_pair = Sentence_Pair.new
    start_para = -1
    File.open(path, 'r').each_with_index do |line, index|
      line_array = line.split(" ")
      if line_array[0] == 'Alignment' and line_array.length == 2  
        start_para = 0
        next
      end

      if start_para == 0
        start_para = 1
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line
        sentence_pair.Alignment = []
        next
      end

      if start_para == 1
        sentence_pair.target = line
        start_para = 2
        next
      end

      if start_para == 2
        start_para = 3
        next
      end

      if line == "\n"
        data << sentence_pair
        start_para = -1
      end

      if start_para == 3
        sentence_pair.Alignment << parse_alignment_meteor(line)
        next
      end
    end

    return data
  end

  def get_data_giza(path)
    data = []
    sentence_pair = Sentence_Pair.new
    File.open(path, 'r').each_with_index do |line, index|
      next if (index % 3) == 0

      if (index - 1)%3 == 0
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line
        sentence_pair.Alignment = []
        next
      end

      if (index - 2)%3 == 0
        sentence_pair.Alignment, sentence_pair.target = parse_giza_line(line)
        data << sentence_pair
      end
    end

    data.each_with_index do |e, index|
      puts "-------------------------------------"
      puts e.inspect
      break if index > 3
    end
    return data
  end


  def parse_giza_line(line)
    data = []
    source = line.gsub("NULL","").gsub(/\s*\(\{(\w*\s*)*\}\)\s*/," ").strip

    #  "NULL ({7}) This ({1,12}) paper ({2}) analyzes ({3}) 33 ({4})"
    # ["NULL", "({7})", "This", "({1,12})", "paper", "({2})", "analyzes", "({3})", "33", "({4})"]
    source_group_matches = line.gsub(/\(\{(\w*\s*)*\}\)/) {
      |tmp| tmp.gsub(/(\s*\w*)*/) {
    |tmp1| tmp1.strip.gsub(/\s/,",")
      }
    }.strip.split(' ')

    source_match_array = source_group_matches.each_slice(2).map { |e| e }

    null_value = []
    result = ""
    target = []

    source_match_array.each_with_index do |item,index|
      unless null_value.count == 0
        tmp_index = index - 1
      end

      if item[0] == 'NULL'
        null_value << item
      else
        align = Alignment.new
        align.tag_name = ''
        
        target << item[0]
        target_tag = item[1].gsub(/[{()}]/,"")

        align.target_numbers = tmp_index.to_s
        align.source_numbers = target_tag.split(",").map {|e| 
                                  if e.to_i == 0
                                    e.to_s
                                  else
                                    e.to_i - 1
                                  end
                                  }.join(",").strip
        data << align
      end
    end


    unless null_value.count == 0 
      align = Alignment.new
      align.tag_name = ''
      align.source_numbers = ''
      
      align.target_numbers = null_value[0][1].gsub(/[{()}]/,"").split(",").map { |e| 
        if e.to_i == 0
          e.to_s
        else
          e.to_i - 1
        end
      }.join(",")
      data << align
    end
    return [data, target.join(" ")]
  end

  def parse_alignment_meteor(line_align)
    line_align.gsub!("\t\t\t", "\t\t")
    line_array = line_align.split("\t\t")
    mapping = {"0" => "exact", "1" => "stem", "2" => "syn", "3" => "para"}

    align = Alignment.new
    align.target_numbers = parse_each_part_meteor(line_array[0])
    align.source_numbers = parse_each_part_meteor(line_array[1])
    align.tag_name = mapping[line_array[2]]

    align
  end

  def parse_each_part_meteor(tmp)
    target_align_arr = tmp.split(":")
    data = target_align_arr[0]

    if target_align_arr[1].to_i > 1
      ((target_align_arr[0].to_i + 1) .. (target_align_arr[1].to_i + target_align_arr[0].to_i - 1)).each do |i|
        data += ',' + i.to_s
      end
    end
    data
  end

    # parse a line in Yawat format into an Alignment struct
  def parse_alignment_meteor_blast(align)
    data = []
    arr = align.split(" ")
    arr.each_with_index do |e, index|
      data << Alignment.new(e.split("#")[2], e.split("#")[1], e.split("#")[3])
    end
    return data
  end

  # parse a line in Yawat format into an Alignment struct
  def parse_alignment_SWA(align)
    data = []
    arr = align.split(" ")
    arr.delete_at(0)
    arr.each_with_index do |e, index|
      data << Alignment.new(e.split(":")[0], e.split(":")[1], e.split(":")[2])
    end
    return data
  end

  def print_data(data)
    output = File.open(DATA_PATH + "/output", "w")
    output.write("")

    data.each do |line|
      output.write(line.source)
      output.write(line.target)
      line.Alignment.each do |aln|
        output.write(aln.source_numbers + ":" + aln.target_numbers + ":" + aln.tag_name)
      end
      output.write("\n")
    end
    output.close
  end

  def insert_unaligned(data)
    data.each_with_index do |pairs, index|
      source_length = pairs.source.split(" ").length
      target_length = pairs.target.split(" ").length
      source_num = []
      target_num = []
      pairs.Alignment.each_with_index do |aln, i|
        source_num << aln.source_numbers.split(",")
        target_num << aln.target_numbers.split(",")
      end
      # puts "source_num: #{source_num}"
      # puts "target_num: #{target_num}"
      source_remain = (0..(source_length - 1)).to_a - source_num.flatten.map{|e| e.to_i}
      target_remain = (0..(target_length - 1)).to_a - target_num.flatten.map{|e| e.to_i}

      source_remain.each do |remain|
        pairs.Alignment << Alignment.new(remain.to_s,"","unaligned")
      end
      target_remain.each do |remain|
        pairs.Alignment << Alignment.new("",remain.to_s,"unaligned")
      end
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

  def compare_data_count(data1, data2)
    count = 0 # number of identical alignments
    count_aln1 = 0 # number of different alignments in data1
    count_aln2 = 0 # number of different alignments in data2
    data1.each_with_index do |alignment1, index|
      count = count + (data1[index].Alignment & data2[index].Alignment).length
      count_aln1 = count_aln1 + (data1[index].Alignment - data2[index].Alignment).length
      count_aln2 = count_aln2 + (data2[index].Alignment - data1[index].Alignment).length
    end
    return count, count_aln1, count_aln2
  end

  def compare_data(data1, data2, tags)
    tags_count = {}
    tags.each_with_index do |line, index|
      tags_count[line] = 0
    end

    data1.each_with_index do |alignment1, index|
      arr_tmp = data1[index].Alignment & data2[index].Alignment

      tags.each_with_index do |tag, index|
        arr_tmp.each do |aln|
          if aln.tag_name == tag
            tags_count[tag] = tags_count[tag] + 1
          end
        end
      end
    end
    return tags_count
  end

  def compare_data_on_tag(data1, data2, tag)
    inter_arr = []
    different_arr1 = []
    different_arr2 = []

    data1.each_with_index do |alignment1, index|
      inter_arr_tmp = data1[index].Alignment & data2[index].Alignment
      different_arr1_tmp = data1[index].Alignment & data2[index].Alignment
      different_arr2_tmp = data2[index].Alignment & data1[index].Alignment

      sentence_pair = Sentence_Pair.new
      sentence_pair.source = alignment1.source
      sentence_pair.target = alignment1.target
      sentence_pair.Alignment = []

      inter_arr_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
          # puts "#{aln}"
        end
      end
      #sentence_pair.Alignment = tmp
      inter_arr << sentence_pair
      puts "#{sentence_pair}"
      sentence_pair.Alignment = []

      different_arr1_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
        end
      end
      different_arr1 << sentence_pair
      sentence_pair.Alignment = []

      different_arr2_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
        end
      end
      different_arr2 << sentence_pair  
      sentence_pair.Alignment = []    
      
    end
    return inter_arr, different_arr1, different_arr2
  end

  def count_tags(data, tags)
    tags_count = {}
    tags.each do |line|
      tags_count[line] = 0
    end

    data.each_with_index do |alignment, index|
      tags.each do |tag|
        alignment.Alignment.each do |aln|
          if aln.tag_name == tag
            tags_count[tag] = tags_count[tag] + 1
          end
        end
      end
    end
    return tags_count
  end


  def compare_alignment(aln1, aln2)
    if (aln1.source_numbers == aln2.source_numbers) and (aln1.target_numbers == aln2.target_numbers) and (aln1.tag_name == aln2.tag_name)
      return true
    else
      return false
    end
  end

  def convert_to_Meteor_tag(data)
    stem_mapping = ["bigrammar-vtense", "bigrammar-wform", "bigrammar-inter"]
    unaligned_mapping = ["unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "spelling", "duplicate"]
    data.each do |aln_arr|
      aln_arr.Alignment.each do |aln|
        if (aln.tag_name == "preserved")
          aln.tag_name = "exact"
        end
        if (stem_mapping.include? aln.tag_name)
          aln.tag_name = "stem"        
        end
        if (unaligned_mapping.include? aln.tag_name)
          aln.tag_name = "unaligned"
        end
        if (aln.tag_name == "paraphrase")
          if !(aln.source_numbers.include? ",") and !(aln.target_numbers.include? ",")
            aln.tag_name = "syn"
          else
            aln.tag_name = "para"
          end
        end
      end
    end
    return data
  end

end


obj = ReadData.new
obj.main

