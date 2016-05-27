require 'engtagger'
require 'lemmatizer'
require 'json'

class ReadData
  DATA_PATH = "./data"
  Sentence_Pair = Struct.new(:source, :target, :Alignment)
  Alignment = Struct.new(:source_numbers, :target_numbers, :tag_name)

  Features = Struct.new(:s_str,
                        :t_str,
                        :st_samestr,
                        :s_stem, 
                        :t_stem,
                        :st_samestem,
                        :s_pos, # NN JJ
                        :t_pos,
                        :st_precede, #precede word (compare 2 words target vs source)
                        :st_follow, #following word (compare 2 words target vs source)
                        # :st_matrix1, Mấy thuộc tính này chưa biết làm
                        # :st_matrix2,
                        # :st_matrix3,
                        # :st_matrix4,
                        # :st_matrix5,
                        # :st_matrix6,
                        # :st_matrix7,
                        # :st_matrix8,
                        :tag_name
                        )

  def lemmatizer
    return @Lemmatizer if @Lemmatizer
    @Lemmatizer = Lemmatizer.new
  end

  def engtagger
    return @EngTagger if @EngTagger
    @EngTagger = EngTagger.new
  end

  def get_list_of_features(data)
    puts "Start #{Time.now}"
    #Todo: build Array of Features
    data_features = []
    puts "data --> #{data.count}"
    data.each_with_index do |sentence_pair, index|
      sentence_pair.Alignment.each_with_index do |align, index_aln|
        data_features << get_feature(align, sentence_pair)
      end
    end
    puts "End #{Time.now}"
    return data_features
  end

  def get_feature(align, sentence_pair)
    feature = Features.new
    feature.s_str = esc_string(get_string_by_index(align.source_numbers, sentence_pair.source))
    feature.t_str = esc_string(get_string_by_index(align.target_numbers, sentence_pair.target))
    feature.st_samestr = (feature.s_str == feature.t_str)? "1" : "0"
    feature.s_pos = esc_string(get_pos_string(feature.s_str))
    feature.t_pos = esc_string(get_pos_string(feature.t_str))
    feature.st_precede = (get_precede_word(align.source_numbers,sentence_pair.source) == get_precede_word(align.target_numbers,sentence_pair.target))? "1" : "0"
    feature.st_follow = (get_following_word(align.source_numbers,sentence_pair.source) == get_following_word(align.target_numbers,sentence_pair.target))? "1" : "0"
    feature.s_stem = esc_string(get_stem_string(feature.s_str.tr("'","")))
    feature.t_stem = esc_string(get_stem_string(feature.t_str.tr("'","")))
    feature.st_samestem = (feature.s_stem == feature.t_stem)? "1" : "0"
    feature.tag_name = align.tag_name
    return feature
  end

  def esc_string(str)
    if ["%", "'"].any? { |e| str.include? e }
      str.gsub!('\'',%q(\\\'))
      str.gsub!("%", "\%")
    end

    if [" ", "\"", ",", "\'", "}", "#", "{", "%"].any? { |e| str.include? e }
      str = "'" + str + "'"
    end
    str
  end

  def get_stem_string(str)
    tmp = str.split(" ").map { |e| get_stem(e) }.join(" ")
    # if [" ", "\"", ",", "\'"].any? { |e| tmp.include? e } # tmp.include? " " or tmp.include? "," or tmp.include? "\""
    #   return "'" + tmp + "'"
    # else
    #   return tmp
    # end
  end

  def get_stem(value)
    lemmatizer.lemma(value)
  end

  def get_pos_string(str)
    tmp = str.split(" ").map { |e| get_pos(e) }.join(" ")
    # if [" ", "\"", ",", "\'"].any? { |e| tmp.include? e } #tmp.include? " " or tmp.include? "," or tmp.include? "\""
    #   return "'" + tmp + "'"
    # else
    #   return tmp
    # end
  end

  def get_pos(value)
    tgr = engtagger.get_readable(value).split("/")[-1]
  end

  # Given the string index and the source/target sentence,
  # return the preceding word
  def get_precede_word(index_string, sentence)
    return "" if index_string.empty?
    precede_index = index_string.split(",").map { |e| e.to_i }.sort.first
    return sentence.split(" ")[precede_index - 1]
  end

  # Given the string index and the source/target sentence,
  # return the following word
  def get_following_word(index_string, sentence)
    return "" if index_string.empty?
    precede_index = index_string.split(",").map { |e| e.to_i }.sort.reverse.first
    return sentence.split(" ")[precede_index + 1]
  end

  def get_string_by_index(index_string, sentence)
    tmp = index_string.split(",").map{|e| sentence.split(" ")[e.to_i]}.join(" ")
    # if [" ", "\"", ","].any? { |e| tmp.include? e } #tmp.include? " " or tmp.include? "," or tmp.include? "\""
    #   tmp = "'" + tmp + "'"
    # end
    # if ["\'"].any? { |e| tmp.include? e }
    #   puts "having backslashes: #{tmp}\n"
    #   tmp = tmp.gsub('\'',"\b\'")
    # end
    # return tmp
  end

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
    # data_giza = get_data_giza(DATA_PATH + "/union.UA3.final")
    # merged_aln_crp = File.open(DATA_PATH + "/Test_merge_aln_crp.txt","w")
    # merged_aln_crp.write("")
    # merge_aln_crp(merged_aln_crp)

    # generate_data_manli(DATA_PATH + "/merged_aln_crp.txt")

    # SWA ====================
    data_SWA = get_data_SWA(DATA_PATH + "/merged_aln_crp.txt")
    data_SWA = refine_tag_preserved(data_SWA)
    # data_SWA = remove_tags_misc(data_SWA)
    # data_SWA = convert_to_Meteor_tag(data_SWA)
    puts "SWA: #{count_alignment(data_SWA)}\n"

    # data_SWA1, data_SWA2 = split_data(data_SWA, 2720)

    # data_SWA2 = reduce_tags_preserved(data_SWA2)
    # data_SWA2 = reduce_tags_paraphrase(data_SWA2)

    # print_csv(data_SWA2)
    # END SWA ================

    # METEOR ================
    # data_meteor_blast = get_data_meteor_blast(DATA_PATH + "/Annotation-5-with-preprocess.txt")
    
    # data_meteor_1_5 = get_data_meteor_1_5(DATA_PATH + "/result_meteor_1.5.txt")
    # data_meteor_1_5 = insert_unaligned(data_meteor_1_5)
    # data_meteor_1_5 = remove_all_tags(data_meteor_1_5)   

    # puts "#{count_alignment(data_meteor_1_5)}\n\n"

    # data_meteor_1_5 = assign_tags(data_SWA, data_meteor_1_5)
    # data_meteor_1_5 = assign_tags_wa(data_meteor_1_5)
    # data_meteor_1_5 = remove_tags_misc(data_meteor_1_5)

    # data_meteor1, data_meteor2 = split_data(data_meteor_1_5, 2720)
    # data_meteor2 = reduce_tags_preserved(data_meteor2)
    # data_meteor2 = reduce_tags_wa(data_meteor2)

    # print_csv(data_meteor2)
    # END METEOR ============

    # MANLI =================
    data_manli = get_data_json(DATA_PATH + "/output.json")
    data_manli = insert_unaligned(data_manli)

    puts "Manli: #{count_alignment(data_manli)}\n\n"    

    data_manli = assign_tags(data_SWA, data_manli)
    data_manli = assign_tags_wa(data_manli)
    # data_manli = remove_tags_misc(data_manli)

    # data_manli1, data_manli2 = split_data(data_manli, 2720)
    # data_manli2 = reduce_tags_preserved(data_manli2)
    # data_manli2 = reduce_tags_unaligned(data_manli2)
    # data_manli2 = reduce_tags_wa(data_manli2)

    # print_csv(data_manli2)
    # # END MANLI =============

    # GIZA ====================
    # data_moses = get_data_moses(DATA_PATH + "/source", DATA_PATH + "/target", DATA_PATH + "/aligned.grow-diag-final-and")
    # data_moses = insert_unaligned(data_moses)
    # puts "#{count_alignment(data_moses)}\n"

    # data_moses = assign_tags(data_SWA, data_moses)
    # data_moses = assign_tags_wa(data_moses)
    # data_moses = remove_tags_misc(data_moses)

    # data_moses1, data_moses2 = split_data(data_moses, 2720)
    # data_moses2 = reduce_tags_preserved(data_moses2)
    # data_moses2 = reduce_tags_unaligned(data_moses2)
    # data_moses2 = reduce_tags_wa(data_moses2)

    # print_csv(data_moses2)
    # END GIZA ================

    # # CHECK DATA ============
    # # tags = ["exact", "stem", "syn", "para", "unaligned"]
    tags = ["preserved", "bigrammar-vtense", "bigrammar-wform", "bigrammar-inter", "paraphrase", "unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "typo", "spelling", "duplicate", "moproblematic", "biproblematic", "unspec", "wa"]
    puts "Tag count SWA: #{count_tags(data_SWA, tags)}\n"
    puts "Tag count Manli: #{count_tags(data_manli, tags)}\n\n"
    puts "compare_data_alignment --> #{compare_data_alignment(data_SWA, data_manli)}\n"
    puts "compare_data --> #{compare_data(data_SWA, data_manli, tags)}"

    # # print_data(data_SWA)
    # # print_data(data_meteor_1_5)
    # print_csv(data_SWA2)

    # tmp = []
    # data_meteor_1_5.each do |line|
    #   line.Alignment.each do |aln|
    #     tmp << aln.tag_name
    #   end
    #   tmp = tmp.uniq
    # end
    # tmp = tmp.uniq
    # puts "#{tmp}"

    # a, b, c = compare_data_on_tag(data_SWA, data_manli, "unaligned")
    # print_data(c)

    # So sánh chỉ dựa trên alignment, ko dựa vào tag name 
    # identical, difference_swa, difference_giza = compare_data_count(data_SWA, data_giza_new)
    # puts "#{identical}\n#{difference_swa}\n#{difference_giza}\n"
    # puts "#{count_alignment(data_SWA)} , #{count_alignment(data_giza)}"

    # puts "#{data_SWA.length} , #{data_meteor_blast.length}, #{data_meteor_1_5.length}"

    # data1.each_with_index do |line, index|
    #   puts "#{line}\n\n" #if line.source.include? "This paper analyzes the effects"
    #   #break if line.source.include? "This paper analyzes the effects"
    # end 
    # data_meteor_blast.each_with_index do |line, index|
    #   puts "#{line}\n\n" if line.source.include? "The conditional probability of a label sequence"
    #   break if line.source.include? "The conditional probability of a label sequence"
    # end 
    # data_meteor_1_5.each_with_index do |line, index|
    #   puts "#{line}\n\n#{index}\n" if line.source.include? "This paper analyzes the"
    #   break if line.source.include? "This paper analyzes the"
    # end   

    # data_SWA.each_with_index do |line, index|
    #   puts "#{line}\n\n" if index == 2784
    #   break if index == 2784
    # end
    data_manli.each_with_index do |line, index|
      line.Alignment.each do |aln|
        if aln.tag_name.empty? or aln.tag_name == "" or aln.tag_name.nil?
          puts "#{line.source}\n"
          puts "#{aln}"
        end
      end
    end

    # # Kiem tra rieng thuoc tinh source thi data 1 khac data 2 nhung gi
    # puts "#{data_meteor_1_5.collect{|e| e.source} - data_SWA.collect{|e| e.source}}"

    
  end


  def get_data_moses(source_path, target_path, align_path)
    #source --> file: source
    #target --> file: target
    #align --> file: aligned.grow-diag-final

    data = []
    sources = []
    targets = []
    File.open(source_path, 'r').each do |line|
      sources << line
    end

    File.open(target_path, 'r').each do |line|
      targets << line
    end
    if sources.length != targets.length
      return data
    end


    sentence_pair = Sentence_Pair.new
    File.open(align_path, 'r').each_with_index do |line, index|
      sentence_pair = Sentence_Pair.new
      sentence_pair.source = sources[index]
      sentence_pair.target = targets[index]
      sentence_pair.Alignment = parse_align_moses(line)
      data << sentence_pair 
    end
    return data
  end

  def parse_align_moses(line)
    aligns = []
    align_1_1_array = line.split(" ")
    next_indexs = []

    align = Alignment.new
    align_1_1_array.each_with_index do |algn,index|
      number_source = algn.split("-")[0]
      number_target = algn.split("-")[1]
      algn_source_exist = nil
      algn_target_exist = nil
      if aligns.count > 0
        algn_source_exist = aligns.select{|e| e.source_numbers.include?(number_source)}.first
        if algn_source_exist
          algn_source_exist.target_numbers += ',' + number_target unless algn_source_exist.target_numbers.include?(number_target)
        end

        algn_target_exist = aligns.select{|e| e.target_numbers.include?(number_target)}.first
        if algn_target_exist
          algn_target_exist.source_numbers +=  ',' + number_source unless algn_target_exist.source_numbers.include?(number_source)
        end
      end
    
      if algn_source_exist.nil? and algn_target_exist.nil?
        align = Alignment.new
        align.target_numbers = number_target
        align.source_numbers = number_source
        align.tag_name = ''
        aligns << align
      end

    end
    aligns
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

  def get_data_json(path)
    data = []
    data_file = File.read(path)
    data_json = JSON.parse(data_file)

    sentence_pair = Sentence_Pair.new
    data_json.each_with_index do |para|
      sentence_pair = Sentence_Pair.new
      sentence_pair.source = para["source"]
      sentence_pair.target = para["target"]
      sentence_pair.Alignment = parse_align_json(para["sureAlign"])
      puts "#{para["possibleAlign"]}" if not para["possibleAlign"].empty?
      data << sentence_pair 
    end
    data
  end

  def parse_align_json(sureAlign)
    aligns = []
    align = Alignment.new
    sureAlign.split(" ").each do |alg|
      align = Alignment.new
      align.source_numbers = alg.split("-").first
      align.target_numbers = alg.split("-").last
      align.tag_name = ""
      aligns << align
    end
    aligns
  end

  def get_data_giza(path)
    data = []
    sentence_pair = Sentence_Pair.new
    File.open(path, 'r').each_with_index do |line, index|
      next if (index % 3) == 0

      if (index - 1)%3 == 0
        sentence_pair = Sentence_Pair.new
        sentence_pair.target = line
        sentence_pair.Alignment = []
        next
      end

      if (index - 2)%3 == 0
        sentence_pair.Alignment, sentence_pair.source = parse_giza_line(line)
        data << sentence_pair
      end
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

        align.source_numbers = tmp_index.to_s
        align.target_numbers = target_tag.split(",").map {|e| 
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

  def generate_data_manli(path)
    output = File.open(DATA_PATH + "/input_manli.txt", "w")
    output.write("")
    File.open(path, 'r').each_with_index do |line, index|
      if (index%4 == 0)
        line = line.gsub("\n", "")
        output.write(line + "\t")
        next
      end
      if (index - 1)%4 == 0
        line = line.gsub("\n", "")
        output.write(line + "\n")
        next
      end
    end
  end

  def print_data(data)
    output_crp = File.open(DATA_PATH + "/output.crp", "w")
    output_crp.write("")
    output_aln = File.open(DATA_PATH + "/output.aln", "w")
    output_aln.write("")

    data.each_with_index do |line, index|
      output_crp.write(index.to_s + "\n")
      output_crp.write(line.source)
      output_crp.write(line.target)

      output_aln.write(index.to_s + " ")
      line.Alignment.each do |aln|
        output_aln.write(aln.source_numbers + ":" + aln.target_numbers + ":" + aln.tag_name + " ")
      end
      output_aln.write("\n")
    end
    output_crp.close
    output_aln.close
  end

  def print_arff(data)
    data_features = get_list_of_features(data) 
    file_arff = File.open(DATA_PATH + "/arff.arff", "w")
    file_arff.write("")
    file_arff.write("@RELATION SWA_classification\n\n")
    file_arff.write("@ATTRIBUTE s_str {#{build_distinct_value('s_str', data_features).join(",")}}\n")
    file_arff.write("@ATTRIBUTE t_str {#{build_distinct_value('t_str', data_features).join(",")}}\n")
    file_arff.write("@ATTRIBUTE st_samestr {0,1}\n")
    file_arff.write("@ATTRIBUTE s_stem {#{build_distinct_value('s_stem', data_features).join(",")}}\n")
    file_arff.write("@ATTRIBUTE t_stem {#{build_distinct_value('t_stem', data_features).join(",")}}\n")
    file_arff.write("@ATTRIBUTE st_samestem {0,1}\n")
    file_arff.write("@ATTRIBUTE s_pos {#{build_distinct_value('s_pos', data_features).join(",")}}\n")
    file_arff.write("@ATTRIBUTE t_pos {#{build_distinct_value('t_pos', data_features).join(",")}}\n")
    # file_arff.write("@ATTRIBUTE s_pos STRING")
    # file_arff.write("@ATTRIBUTE t_pos STRING")
    file_arff.write("@ATTRIBUTE st_precede {0,1}\n")
    file_arff.write("@ATTRIBUTE st_follow {0,1}\n")
    file_arff.write("@ATTRIBUTE class {preserved,bigrammar-vtense,bigrammar-wform,bigrammar-inter,paraphrase,unaligned,mogrammar-prep,mogrammar-det,bigrammar-prep,bigrammar-det,bigrammar-others,typo,spelling,duplicate,moproblematic,biproblematic,unspec}\n\n")
    file_arff.write("@DATA\n")

    data_features.each do |ft|
      array = [ft.s_str, ft.t_str, ft.st_samestr, ft.s_stem, ft.t_stem, ft.st_samestem, ft.s_pos, ft.t_pos, ft.st_precede, ft.st_follow, ft.tag_name]
      file_arff.write(array.map{|e| (e == nil || e == "") ? "?" : "#{e}"}.join(",") + "\n")
    end
  end

  def print_csv(data)
    data_features = get_list_of_features(data) 
    file_arff = File.open(DATA_PATH + "/csv.csv", "w")
    file_arff.write("")
    file_arff.write("s_str,t_str,st_samestr,s_stem,t_stem,st_samestem,s_pos,t_pos,st_precede,st_follow,class\n")

    data_features.each do |ft|
      array = [ft.s_str, ft.t_str, ft.st_samestr, ft.s_stem, ft.t_stem, ft.st_samestem, ft.s_pos, ft.t_pos, ft.st_precede, ft.st_follow, ft.tag_name]
      file_arff.write(array.map{|e| (e == nil || e == "") ? "?" : "#{e}"}.join(",") + "\n")
    end
  end

  def split_data(data, no_sentences_of_1st_part)
    data1 = []
    data2 = []
    data.each_with_index do |sent, index|
      if index <= no_sentences_of_1st_part 
        data1 << sent
      else
        data2 << sent
      end
    end
    return data1, data2
  end

  #Data is 1 array of list of features
  def build_distinct_value(attribute_name, data_features)
    data_features.map { |e| e[attribute_name.to_sym] }.uniq
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
        pairs.Alignment << Alignment.new(remain.to_s,"","")
      end
      target_remain.each do |remain|
        pairs.Alignment << Alignment.new("",remain.to_s,"")
      end
    end
    return data
  end

  def refine_tag_preserved(data)
    data.each do |line| 

      aln_arrs = []
      aln_delete = []
      line.Alignment.each_with_index do |aln,i|
        if (aln.tag_name == "preserved") and (aln.source_numbers.include? ",") and (aln.target_numbers.include? ",") and (aln.source_numbers.scan(/,/).count == aln.target_numbers.scan(/,/).count)
          aln_arrs << break_alignment(aln)
          aln_delete << i
        end
      end

      # delete old preserved alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }

      # add new preserved alignments into the original array
      line.Alignment << aln_arrs.flatten
      line.Alignment.flatten!
    end 
    return data
  end

  def reduce_tags_preserved(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "preserved")
          aln_delete << i
          count = count + 1
          break if count >= 12484
        end
        break if count >= 12484
      end
      # delete preserved alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 12484 
      #57082 SWA 80
      #12484 SWA 20
      #12246 meteor 20
      # 9959 manli 20
      # 12087 moses 20
      #68300 meteor #44200 giza
    end
    return data
  end

  def reduce_tags_paraphrase(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "paraphrase")
          aln_delete << i
          count = count + 1
          break if count >= 60
        end
        break if count >= 60
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 60
      # 300 SWA 80
      # 60 SWA 20
    end
    return data
  end

  def reduce_tags_wa(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "wa")
          aln_delete << i
          count = count + 1
          break if count >= 748
        end
        break if count >= 748
      end
      # delete wa alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 748 
      # 2795 meteor 20
      # 3222 manli 20
      # 748 moses 20
      #12000 meteor #35100 giza
    end
    return data
  end

  def reduce_tags_unaligned(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "unaligned")
          aln_delete << i
          count = count + 1
          break if count >= 224
        end
        break if count >= 224
      end
      # delete unaligned alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 224
      # 1579 manli 20 
      # 224 moses 20
    end
    return data
  end

  def remove_tags_misc(data)
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "moproblematic") or (aln.tag_name == "biproblematic") or (aln.tag_name == "unspec")
          aln_delete << i
        end
      end
      
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
    end
    return data
  end

  def remove_all_tags(data)
    data.each do |line|
      line.Alignment.each do |aln|
        aln.tag_name = ""
      end
    end
    return data
  end

  def break_alignment(aln)
    aln_arr = []
    source_tmp = aln.source_numbers.split(",").map { |e| e.to_i }.sort
    target_tmp = aln.target_numbers.split(",").map { |e| e.to_i }.sort
    source_tmp.each_with_index do |line,i|
      aln_arr << Alignment.new(source_tmp[i].to_s,target_tmp[i].to_s,"preserved")
    end
    return aln_arr
  end

  def count_alignment(data)
    count = 0
    data.each_with_index do |pairs, index|
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

  def assign_tags(data1, data2)
    data1.each_with_index do |alignment1, index|
      # if data1[index].source.gsub("\n", "").strip == data2[index].source.gsub("\n", "").strip and data1[index].target.gsub("\n", "").strip == data2[index].target.gsub("\n", "").strip
        # Lấy ra được mãng có các mảng con mà mảng con có 2 phần tử là source_numbers và target_numbers
        alignment1_arr = data1[index].Alignment.map { |e| [e.source_numbers.split(",").sort.join(","), e.target_numbers.split(",").sort.join(",")] }
        alignment2_arr = data2[index].Alignment.map { |e| [e.source_numbers.split(",").sort.join(","), e.target_numbers.split(",").sort.join(",")] }
        
        # So sánh tìm ra phần chung
        # này là mảng 2 phần tử [["","1"], ["2,3","2,3"], ["4","4"]]
        alignment_inter = (alignment1_arr & alignment2_arr)
        # puts "alignment_inter --> #{alignment_inter.inspect}"
        # puts data1[index].Alignment
        # puts data2[index].Alignment
        if alignment_inter.length > 0
          alignment_inter.each do |align|
            # puts "align #{align.inspect}"
            # puts "data1[index].Alignment ==> #{data1[index].Alignment.inspect}"
            # puts "data2[index].Alignment ==> #{data2[index].Alignment.inspect}"
            algn1 = data1[index].Alignment.select{|al| al.source_numbers.split(",").sort.join(",") == align[0] && al.target_numbers.split(",").sort.join(",") == align[1]}.first
            algn2 = data2[index].Alignment.select{|al| al.source_numbers.split(",").sort.join(",") == align[0] && al.target_numbers.split(",").sort.join(",") == align[1]}.first
            # puts "algn1 --> #{algn1.inspect}"
            # puts "algn2 --> #{algn2.inspect}"
            algn2.tag_name = algn1.tag_name
          end
        end
      # end
    end
    data2
  end

  def assign_tags_wa(data)
    data.each do |line|
      line.Alignment.each do |aln|
        if (aln.tag_name.empty?)
          aln.tag_name = "wa"
        end
      end
    end
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

  # Compare 2 data based on alignment only
  # DO NOT compare tag
  def compare_data_alignment(data1, data2)
    count = 0
    # puts "data1: #{data1.count}"
    # puts "data2: #{data2.count}"
    data1.each_with_index do |alignment1, index|
      arr_tmp = data1[index].Alignment.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers }} &
        data2[index].Alignment.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers}}

      count = count + arr_tmp.length
    end
    return count
  end

  # Compare 2 data on a specific tag
  # The data returned will be 3 arrays: array of intersection alignment, 
  # array of alignments which are in data1 but not in data2, 
  # and array of alignments which are in data2 but not in data1.
  def compare_data_on_tag(data1, data2, tag)
    inter_arr = []
    different_arr1 = []
    different_arr2 = []

    data1.each_with_index do |alignment1, index|
      inter_arr_tmp = data1[index].Alignment & data2[index].Alignment
      different_arr1_tmp = data1[index].Alignment - data2[index].Alignment
      different_arr2_tmp = data2[index].Alignment - data1[index].Alignment

      sentence_pair = Sentence_Pair.new
      sentence_pair.source = alignment1.source
      sentence_pair.target = alignment1.target
      sentence_pair.Alignment = []

      inter_arr_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
        end
      end
      if sentence_pair.Alignment != []
        inter_arr << sentence_pair
      end

      sentence_pair = Sentence_Pair.new
      sentence_pair.source = alignment1.source
      sentence_pair.target = alignment1.target
      sentence_pair.Alignment = []

      different_arr1_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
        end
      end
      if sentence_pair.Alignment != []
        different_arr1 << sentence_pair
      end

      sentence_pair = Sentence_Pair.new
      sentence_pair.source = alignment1.source
      sentence_pair.target = alignment1.target
      sentence_pair.Alignment = []

      different_arr2_tmp.each do |aln|
        if aln.tag_name == tag
          sentence_pair.Alignment << aln
        end
      end
      if sentence_pair.Alignment != []
        different_arr2 << sentence_pair
      end   
      
    end
    return inter_arr, different_arr1, different_arr2
  end

  # Count total numbers of tags in data
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

  # Convert SWA corpus with SWA tags into Meteor tag
  # Exact, Stem, Synonym, Paraphrase and Unaligned
  # exact, stem, syn, para and unaligned
  def convert_to_Meteor_tag(data)
    stem_mapping = ["bigrammar-vtense", "bigrammar-wform", "bigrammar-inter"]
    unaligned_mapping = ["unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "typo", "spelling", "duplicate", "moproblematic", "unspec"]
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
        if (aln.tag_name == "paraphrase" or aln.tag_name == "biproblematic")
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

