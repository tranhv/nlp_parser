require 'engtagger'
require 'lemmatizer'
require 'json'
require 'xmlsimple'
require 'nokogiri'
require 'rjb'

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
  N80_PERCENT = 2759
  PRESERVED = "preserved"

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

  def get_aln(full_aln_path)
    array_alns = []
    # File.open(DATA_PATH + "/full_aln_kigoshi.txt", 'r').each do |line|
    # File.open(full_aln_path, 'r').each do |line|
    File.open(full_aln_path, 'r').each_with_index do |line, index| # --> only in case count sentence for each file, file aln co dong dau trong nen phai bo ra.
      next if index == 0
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

  def get_crp(full_aln_path, full_crp_path)
    array_crps = []
    arr = []
    flag_para = false
    alns = get_aln(full_aln_path)
    index_aln = 0
    # File.open(DATA_PATH + "/full_crp_kigoshi.txt", 'r').each_with_index do |line, index|
    File.open(full_crp_path, 'r').each_with_index do |line, index|      
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

  def merge_aln_crp(output_file, full_aln_path, full_crp_path)
    array_crp = get_crp(full_aln_path, full_crp_path)
    
    array_crp.each_with_index do |line, index|
      # puts "#{line}"
      if not line[1].match(/^</)
        output_file.write(line[1].to_s)
        output_file.write(line[2].to_s)
        output_file.write(line[3].to_s)
        output_file.write("\n")
      end
    end
  end

  def main
    # data_demo = get_data_demo("./data/import_file.txt")
    # puts data_demo
    # data_test = get_data_demo(DATA_PATH + "/import_file.txt")
    data_test = get_data_meteor_1_5(DATA_PATH + "/result_meteor.txt")
    data_test = insert_unaligned(data_test)
    # puts "data test --> #{data_test}"

    data_test = remove_all_tags(data_test)
    print_arff(data_test)
    train = build_weka_svm_train(DATA_PATH + "/SWA_20.arff")
    classification_results = build_weka_svm_test(DATA_PATH + "/arff.arff", train)
    data_test = assign_classification_results(data_test, classification_results)
    puts "data_test --> #{data_test}"
  end

  def main_fce
    files = Dir.glob(DATA_PATH + "/dataset/01*/*.xml").sort.entries
    
    # fce_full = File.open(DATA_PATH + "/dataset/fce_full.xml", "w")
    # fce_full.write("")

    # files.each do |file|
    #   text = File.open(file, 'r').read
    #   # puts "#{text} \n\n\n"
    #   fce_full.write(text + "\n")
    # end

    #get_data_fce(DATA_PATH + "/dataset/0100_2000_06/doc11.xml")
    # data_fce = get_data_fce("./data/fce_full.xml")
    # puts data_fce

    data_fce = []
    files.each do |file|
      data_fce << get_data_fce(file)
      # puts "#{file}  \n"
    end
    data_fce.flatten!
    # puts data_fce

    # Doan nay de delete nhung cau source = "" hoac target = "" (khi dua vao manli bi loi)
    puts "count before deleting --> #{data_fce.count}\n"
    delete_list = []
    data_fce.each_with_index do |line, i|
      if line.source.empty? or line.target.empty?
        delete_list << i
      end
    end
    puts "#{delete_list}"

    i = 0
    delete_list.each do |del|
      data_fce.delete_at(del - i)
      i = i + 1
    end
    puts "count after deleting --> #{data_fce.count}\n"

    # Doan nay de delete nhung cau qua dai (Manli bi loi, chay quai ko ra, ba nui no)
    # i=0
    delete_list = []
    data_fce.each_with_index do |line, index|
      if line.source.length > 1200
        # puts "#{line.source.length} <---> #{line.source} \n"
        # i=i+1
        delete_list << index
      end
    end
    # puts i  #so luong cau da bi delete

    i = 0
    delete_list.each do |del|
      data_fce.delete_at(del - i)
      i = i + 1
    end
    puts "count after deleting --> #{data_fce.count}\n"

    # generate_data_meteor(data_fce)
    # generate_data_manli(data_fce)

    # FCE
    # puts "#{get_tags(data_fce)}"
    data_fce = refine_tag_preserved(data_fce)
    puts "FCE: #{count_alignment(data_fce)}\n"

    data_fce = reduce_tags_preserved(data_fce)

    print_csv(data_fce)

    # METEOR
    data_meteor_fce = get_data_meteor_1_5(DATA_PATH + "/result_meteor_fce.txt")
    data_meteor_fce = insert_unaligned(data_meteor_fce)
    data_meteor_fce = remove_all_tags(data_meteor_fce)   
    # puts "Meteor: #{count_alignment(data_meteor_fce)}\n"

    data_meteor_fce = assign_tags(data_fce, data_meteor_fce)
    data_meteor_fce = assign_tags_waln(data_meteor_fce)
    puts "Meteor count alignment: #{count_alignment(data_meteor_fce)}\n\n"

    # data_meteor_fce = reduce_tags_preserved(data_meteor_fce)
    # data_meteor_fce = reduce_tags_waln(data_meteor_fce)

    # print_csv(data_meteor_fce)

    # MANLI
    data_manli = get_data_json(DATA_PATH + "/output_manli_fce.json")
    data_manli = insert_unaligned(data_manli)
    data_manli = remove_all_tags(data_manli)

    puts "Manli count alignment: #{count_alignment(data_manli)}\n\n"    

    data_manli = assign_tags(data_fce, data_manli)
    data_manli = assign_tags_waln(data_manli)

    # data_manli = reduce_tags_preserved(data_manli)
    # data_manli = reduce_tags_waln(data_manli)

    # print_csv(data_manli)

    # CHECK DATA
    tags = ["preserved", "AGD", "AGN", "AGV", "DA", "DY", "FJ", "FN", "FV", "M", "MA", "MD", "MN", "MP", "MT", "MV", "MY", "R", "RN", "RP", "RQ", "RT", "RV", "RY", "S", "SX", "TV", "U", "UC", "UD", "UN", "UT", "UV", "UY", "W", "waln"]
    puts "Tag count FCE: #{count_tags(data_fce, tags)}\n"
    puts "Tag count METEOR: #{count_tags(data_meteor_fce, tags)}\n"
    puts "Tag count MANLI: #{count_tags(data_manli, tags)}\n"

    puts "compare_data_alignment FCE METEOR --> #{compare_data_alignment(data_fce, data_meteor_fce)}\n"
    puts "compare_data_alignment FCE MANLI --> #{compare_data_alignment(data_fce, data_manli)}\n"

    #===============================

  end

  def main2
    # nucle = get_data_nucle(DATA_PATH + "/nucle2.0.sgml")
    nucle = get_data_nucle(DATA_PATH + "/corpusFull_fix_Trung.sgml")
    data_nucle = parser_data_nucle(nucle)
    data_nucle = remove_blank_senpair(data_nucle)
    # puts "data_nucle --> #{data_nucle.inspect}\n\n"

    # data_nucle = reduce_tags_ArtOrDet(data_nucle)
    # data_nucle = reduce_tags_Wcip(data_nucle)
    # data_nucle = reduce_tags_Rloc(data_nucle)

    # print_csv(data_nucle)

    # Check xem thu tag Um co Correction hay khong
    # Neu co Correction thi puts ra de xem
    # data_nucle.each_with_index do |line, index|
    #   line.Alignment.each_with_index do |aln, i|
    #     if aln.tag_name == "Um" and !aln.target_numbers.empty?
    #       puts ">>>>#{line.inspect}\n"
    #     end
    #   end
    # end

    # generate_data_meteor(data_nucle)
    # generate_data_manli(data_nucle)

    # METEOR ================    
    # data_meteor_nucle = get_data_meteor_1_5(DATA_PATH + "/result_meteor_nucle.txt")
    # data_meteor_nucle = insert_unaligned(data_meteor_nucle)
    # data_meteor_nucle = remove_all_tags(data_meteor_nucle)   
    # puts "Meteor: #{count_alignment(data_meteor_nucle)}\n"

    # data_meteor_nucle = assign_tags(data_nucle, data_meteor_nucle)
    # data_meteor_nucle = assign_tags_waln(data_meteor_nucle)
    # puts "Meteor count alignment: #{count_alignment(data_meteor_nucle)}\n\n"

    # data_meteor_nucle = reduce_tags_waln(data_meteor_nucle)
    # data_meteor_nucle = reduce_tags_Rloc(data_meteor_nucle)

    # print_csv(data_meteor_nucle)
    # END METEOR ============

    # MANLI =================
    # data_manli = get_data_json(DATA_PATH + "/output_nucle.json")
    # data_manli = insert_unaligned(data_manli)
    # data_manli = remove_all_tags(data_manli)

    # # puts "Manli count alignment: #{count_alignment(data_manli)}\n\n"    

    # data_manli = assign_tags(data_nucle, data_manli)
    # data_manli = assign_tags_waln(data_manli)

    # data_manli = reduce_tags_waln(data_manli)
    # data_manli = reduce_tags_Nn(data_manli)
    # data_manli = reduce_tags_Wcip(data_manli)

    # print_csv(data_manli)
    # # END MANLI =============

    # CHECK DATA ============
    # tags = ["Vt", "Vm", "V0", "Vform", "SVA", "ArtOrDet", "Nn", "Npos", "Pform", "Pref", "Wcip", "Wa", "Wform", "Wtone", "Srun", "Smod", "Spar", "Sfrag", "Ssub", "WOinc", "WOadv", "Trans", "Mec", "Rloc", "Cit", "Others", "Um", "waln"]
    # tags = ["exact", "stem", "para", "unaligned", "syn"]

    # puts "Tag count NUCLE: #{count_tags(data_nucle, tags)}\n"
    # puts "Tag count Meteor: #{count_tags(data_meteor_nucle, tags)}\n"
    # puts "Tag count Manli: #{count_tags(data_manli, tags)}\n\n"

    # puts "compare_data_alignment NUCLE METEOR --> #{compare_data_alignment(data_nucle, data_meteor_nucle)}\n"
    # puts "compare_data_alignment NUCLE MANLI --> #{compare_data_alignment(data_nucle, data_manli)}\n"
    # puts "compare_data NUCLE METEOR --> #{compare_data(data_nucle, data_meteor_nucle, tags)}\n"
    # puts "compare_data NUCLE MANLI --> #{compare_data(data_nucle, data_manli, tags)}\n"

    # puts "count NUCLE: #{data_nucle.count}\n"
    # puts "count METEOR: #{data_meteor_nucle.count}\n"
    # puts "count MANLI: #{data_manli.count}\n"
    # puts "#{get_tags(data_meteor_nucle)}"

    # data_meteor_1_5 = remove_all_but_wa(data_meteor_1_5)
    # data_manli = remove_all_but_wa(data_manli)
    # data_moses = remove_all_but_wa(data_moses)

    # # print_data(data_SWA)
    # print_data(data_meteor_1_5)
    # print_data_manli(data_manli)
    # print_data(data_moses)
  end


  def main1
    # data_giza = get_data_giza(DATA_PATH + "/union.UA3.final")
    # merged_aln_crp = File.open(DATA_PATH + "/merged_kigoshi.txt","w")
    # merged_aln_crp.write("")
    # merge_aln_crp(merged_aln_crp, DATA_PATH + "/full_aln_kigoshi.txt", DATA_PATH + "/full_crp_kigoshi.txt")

    # generate_data_manli(DATA_PATH + "/merged_quynhanh.txt")

    # Dem so sentence cua each file trong mot thu muc
    # files = Dir.glob(DATA_PATH + "/quynhanh/*.aln").sort.entries

    # files.each do |file|
    #   filename = file.split(".")[1].split("/")[3]
    #   merged = File.open(DATA_PATH + "/quynhanh/" + filename + "_merged.txt", "w")
    #   merged.write("")
    #   merge_aln_crp(merged, DATA_PATH + "/quynhanh/" + filename + ".aln", DATA_PATH + "/quynhanh/" + filename + ".crp")
    # end

    # files = Dir.glob(DATA_PATH + "/quynhanh/*_merged.txt").sort.entries

    # files.each do |file|
    #   filename = file.split(".")[1].split("/")[3]
    #   sentence_no = get_data_SWA(DATA_PATH + "/quynhanh/" + filename + ".txt").length
    #   puts "#{filename} --> #{sentence_no}"
    # end
    # END Dem so sentence

    files = Dir.glob(DATA_PATH + "/quynhanh/*.aln").sort.entries
    
    file_aln = File.open(DATA_PATH + "/quynhanh/alignments.txt", "w")
    file_aln.write("")

    files.each do |file|
      filename = file.split(".")[1].split("/")[3]
      data = get_data_SWA(DATA_PATH + "/quynhanh/" + filename + "_merged.txt")
      print_alignments(data, filename, file_aln)
    end

    # NEW DATA ===============
    # data_hanh = get_data_SWA(DATA_PATH + "/merged_hanh.txt")
    # data_hanh = refine_tag_preserved(data_hanh)
    # data_hanh = convert_typo_spelling(data_hanh)
    # puts "hanh: #{count_alignment(data_hanh)}\n"
    # puts "Sentence: #{data_hanh.length}"

    # data_quynhanh = get_data_SWA(DATA_PATH + "/merged_quynhanh.txt")
    # data_quynhanh = refine_tag_preserved(data_quynhanh)
    # data_quynhanh = convert_typo_spelling(data_quynhanh)   
    # puts "quynhanh: #{count_alignment(data_quynhanh)}\n" 
    # puts "Sentence: #{data_quynhanh.length}"

    # data_quynhanh = remove_tags_misc(data_quynhanh)
    # puts "quynhanh remove misc: #{count_alignment(data_quynhanh)}\n" 

    # data_quynhanh = reduce_tags_preserved(data_quynhanh)
    # data_quynhanh = reduce_tags_paraphrase(data_quynhanh)
    # data_quynhanh = reduce_tags_mogdet(data_quynhanh)

    # print_csv(data_quynhanh)

    # data_ngan = get_data_SWA(DATA_PATH + "/merged_ngan.txt")
    # data_ngan = refine_tag_preserved(data_ngan)
    # data_ngan = convert_typo_spelling(data_ngan)   
    # puts "ngan: #{count_alignment(data_ngan)}\n" 

    # data_kigoshi = get_data_SWA(DATA_PATH + "/merged_kigoshi.txt")
    # data_kigoshi = refine_tag_preserved(data_kigoshi)
    # data_kigoshi = convert_typo_spelling(data_kigoshi)   
    # puts "data_kigoshi: #{count_alignment(data_kigoshi)}\n" 
    # END NEW DATA ===========

    # SWA ====================
    # data_SWA = get_data_SWA(DATA_PATH + "/merged_aln_crp.txt")
    # data_SWA = refine_tag_preserved(data_SWA)
    # data_SWA = convert_typo_spelling(data_SWA)
    # data_SWA = remove_tags_misc(data_SWA)
    # data_SWA = convert_to_Meteor_tag(data_SWA)
    # puts "SWA: #{count_alignment(data_SWA)}\n"

    # data_SWA1, data_SWA2 = split_data(data_SWA, N80_PERCENT)

    # data_SWA = reduce_tags_preserved(data_SWA)
    # data_SWA = reduce_tags_paraphrase(data_SWA)
    # data_SWA = reduce_tags_exact(data_SWA)
    # data_SWA = reduce_tags_unaligned(data_SWA)

    # print_csv(data_SWA)
    # END SWA ================

    # METEOR ================
    # data_meteor_blast = get_data_meteor_blast(DATA_PATH + "/Annotation-5-with-preprocess.txt")
    
    # data_meteor_1_5 = get_data_meteor_1_5(DATA_PATH + "/meteor_quynhanh.txt")
    # data_meteor_1_5 = insert_unaligned(data_meteor_1_5)
    # data_meteor_1_5 = remove_all_tags(data_meteor_1_5)   
    # puts "Meteor: #{count_alignment(data_meteor_1_5)}\n"

    # data_meteor_1_5 = assign_tags(data_quynhanh, data_meteor_1_5)
    # data_meteor_1_5 = assign_tags_wa(data_meteor_1_5)
    # data_meteor_1_5 = remove_tags_misc(data_meteor_1_5)
    # puts "Meteor remove misc: #{count_alignment(data_meteor_1_5)}\n\n"

    # # data_meteor1, data_meteor2 = split_data(data_meteor_1_5, N80_PERCENT)
    # data_meteor_1_5 = reduce_tags_preserved(data_meteor_1_5)
    # data_meteor_1_5 = reduce_tags_wa(data_meteor_1_5)
    # data_meteor_1_5 = reduce_tags_mogdet(data_meteor_1_5)
    # data_meteor_1_5 = reduce_tags_exact(data_meteor_1_5)
    # data_meteor_1_5 = reduce_tags_unaligned(data_meteor_1_5)
    # data_meteor_1_5 = reduce_tags_wa(data_meteor_1_5)

    # print_csv(data_meteor_1_5)
    # END METEOR ============

    # MANLI =================
    # data_manli = get_data_json(DATA_PATH + "/output_manli_quynhanh.json")
    # data_manli = insert_unaligned(data_manli)
    # data_manli = remove_all_tags(data_manli)

    # puts "Manli: #{count_alignment(data_manli)}\n\n"    

    # data_manli = assign_tags(data_quynhanh, data_manli)
    # data_manli = assign_tags_wa(data_manli)
    # data_manli = remove_tags_misc(data_manli)
    # puts "Manli remove misc: #{count_alignment(data_manli)}\n\n"

    # data_manli1, data_manli2 = split_data(data_manli, N80_PERCENT)
    # data_manli = reduce_tags_preserved(data_manli)
    # data_manli = reduce_tags_wa(data_manli)
    # data_manli = reduce_tags_mogdet(data_manli)
    # data_manli = reduce_tags_exact(data_manli)
    # data_manli = reduce_tags_unaligned(data_manli)
    # data_manli = reduce_tags_wa(data_manli)

    # print_csv(data_manli)
    # # END MANLI =============

    # GIZA ====================
    # data_moses = get_data_moses(DATA_PATH + "/source", DATA_PATH + "/target", DATA_PATH + "/aligned.grow-diag-final")
    # data_moses = insert_unaligned(data_moses)
    # data_moses = remove_all_tags(data_moses)
    # # # # puts "#{count_alignment(data_moses)}\n"

    # data_moses = assign_tags(data_SWA, data_moses)
    # data_moses = assign_tags_wa(data_moses)
    # # # data_moses = remove_tags_misc(data_moses)

    # data_moses1, data_moses2 = split_data(data_moses, N80_PERCENT)
    # # # data_moses = reduce_tags_preserved(data_moses)
    # # # data_moses = reduce_tags_wa(data_moses)
    # data_moses = reduce_tags_exact(data_moses)
    # data_moses = reduce_tags_unaligned(data_moses)
    # data_moses = reduce_tags_wa(data_moses)

    # print_csv(data_moses)
    # --------------------------
    # data_moses = get_data_moses_new(DATA_PATH + "/source", DATA_PATH + "/target", DATA_PATH + "/aligned.grow-diag-final")
    # data_moses = insert_unaligned(data_moses)
    # data_moses = remove_all_tags(data_moses)
    
    # data_moses = assign_tags(data_SWA, data_moses)
    # data_moses = assign_tags_wa(data_moses)
    # data_moses = remove_tags_misc(data_moses)

    # data_moses = reduce_tags_preserved(data_moses)
    # data_moses = reduce_tags_wa(data_moses)

    # puts "#{count_alignment(data_moses)}\n"

    # print_csv(data_moses)
    # print_data(data_moses)
    # END GIZA ================

    # # CHECK DATA ============
    # tags = ["exact", "stem", "syn", "para", "unaligned", "wa"]
    # tags = ["preserved", "bigrammar-vtense", "bigrammar-wform", "bigrammar-inter", "paraphrase", "unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "typo-spelling", "duplicate", "moproblematic", "biproblematic", "unspec", "wa"]
    tags = ["preserved", "bigrammar-vtense", "bigrammar-wform", "bigrammar-inter", "bigrammar-nnum", "paraphrase", "unaligned", "mogrammar-prep", "mogrammar-det", "bigrammar-prep", "bigrammar-det", "bigrammar-others", "typo-spelling", "duplicate", "para-freeword", "para-colocation", "para-passact", "moproblematic", "biproblematic", "unspec", "wa"]
    
    # # puts "Tag count SWA: #{count_tags(data_SWA, tags)}\n"
    # puts "Tag count Meteor: #{count_tags(data_meteor_1_5, tags)}\n\n"
    # puts "Tag count Manli: #{count_tags(data_manli, tags)}"
    # # puts "Tag count GIZA: #{count_tags(data_moses, tags)}"
    # puts "Tag count ngan: #{count_tags(data_ngan, tags)}\n"
    # puts "Tag count kigoshi: #{count_tags(data_kigoshi, tags)}\n"
    # puts "Tag count quynhanh: #{count_tags(data_quynhanh, tags)}"

    # puts "compare_data_alignment --> #{compare_data_alignment(data_ngan, data_kigoshi)}\n"
    # puts "compare_data --> #{compare_data(data_ngan, data_kigoshi, tags)}\n"
    # puts "compare_data_alignment --> #{compare_data_alignment(data_hanh, data_quynhanh)}\n"
    # puts "compare_data --> #{compare_data(data_hanh, data_quynhanh, tags)}\n"

    # puts "#{get_tags(data_hanh)}"

    # data_meteor_1_5 = remove_all_but_wa(data_meteor_1_5)
    # data_manli = remove_all_but_wa(data_manli)
    # data_moses = remove_all_but_wa(data_moses)

    # # print_data(data_SWA)
    # print_data(data_meteor_1_5)
    # print_data_manli(data_manli)
    # print_data(data_moses)

    # tmp = []
    # data_meteor_1_5.each do |line|
    #   line.Alignment.each do |aln|
    #     tmp << aln.tag_name
    #   end
    #   tmp = tmp.uniq
    # end
    # tmp = tmp.uniq
    # puts "#{tmp}"

    # a, b, c = compare_data_on_tag(data_SWA, data_meteor_1_5, "bigrammar-vtense")
    # puts "\n In SWA not in meteor \n #{b}"
    # print_data(c)

    # So sánh chỉ dựa trên alignment, ko dựa vào tag name 
    # identical, difference_swa, difference_giza = compare_data_count(data_SWA, data_giza_new)
    # puts "#{identical}\n#{difference_swa}\n#{difference_giza}\n"
    # puts "#{count_alignment(data_SWA)} , #{count_alignment(data_giza)}"

    # puts "#{data_SWA.length} , #{data_meteor_blast.length}, #{data_meteor_1_5.length}"

    # data_meteor_1_5.each_with_index do |line, index|
    #   puts "#{line}\n\n" if line.source.include? "We examined the performances of both shallow and deep parsers"
    #   break if line.source.include? "We examined the performances of both shallow and deep parsers"
    # end 
    # data_meteor_blast.each_with_index do |line, index|
    #   puts "#{line}\n\n" if line.source.include? "The conditional probability of a label sequence"
    #   break if line.source.include? "The conditional probability of a label sequence"
    # end 
    # data_meteor_1_5.each_with_index do |line, index|
    #   puts "#{line}\n\n#{index}\n" if line.source.include? "This paper analyzes the"
    #   break if line.source.include? "This paper analyzes the"
    # end   

    # data_quynhanh.each_with_index do |line, index|
    #   puts "#{line.source}\n\n" if index == 1
    #   break if index == 1
    # end 
    # data_manli.each_with_index do |line, index|
    #   puts "#{line.source}\n\n" if index == 1
    #   break if index == 1
    # end 

    # data_quynhanh.each_with_index do |line, index|
    #     puts "#{data_quynhanh[index].source}"
    #     puts "#{data_manli[index].source}\n" #if index == 4000
    #     break if data_quynhanh[index].source != data_manli[index].source
    # end

    # data_manli.each_with_index do |line, index|
    #   line.Alignment.each do |aln|
    #     if aln.tag_name.empty? or aln.tag_name == "" or aln.tag_name.nil?
    #       puts "#{line.source}\n"
    #       puts "#{aln}"
    #     end
    #   end
    # end

    # data_meteor_1_5.each_with_index do |line, index|
    #   line.Alignment.each do |aln|
    #     if aln.tag_name == "wa"
    #       puts "#{line.source}"
    #       puts "#{line.target}"
    #       puts "#{aln}\n"
    #     end
    #   end
    # end

    # Kiem tra rieng thuoc tinh source thi data 1 khac data 2 nhung gi
    # puts "#{data_quynhanh.collect{|e| e.source} - data_manli.collect{|e| e.source}}"

    
  end

  def main_suongnhonhoinhoi
    # GIZA ====================
    data_moses = get_data_moses(DATA_PATH + "/source", DATA_PATH + "/target", DATA_PATH + "/aligned.grow-diag-final")
    data_moses = insert_unaligned(data_moses)
    puts "#{count_alignment(data_moses)}\n"
    print_data(data_moses)
  end

  def get_tags(data)
    tags = []
    data.each do |line|
      line.Alignment.each do |aln|
        tags << aln.tag_name
      end
    end
    uniq_tags = tags.uniq
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
      sentence_pair.Alignment = parse_align_moses(line)#refine_line_moses(parse_align_moses(line), sources[index], targets[index])
      data << sentence_pair 
    end
    return data
  end

  def get_data_moses_new(source_path, target_path, align_path)
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
      sentence_pair.Alignment = refine_line_moses(parse_align_moses(line), sources[index], targets[index])
      data << sentence_pair 
    end
    return data
  end

  def refine_line_moses(aligns, source, target)
    add_aligns = []
    alg_need_to_delete = []
    aligns.each_with_index do |alg, index|
      hash_source = {}
      hash_target = {}
      next if (!alg.source_numbers.include?(",") && !alg.target_numbers.include?(","))
      alg.source_numbers.split(",").each_with_index do |num|
        hash_source[source.split(" ")[num.to_i].downcase] = num
      end

      alg.target_numbers.split(",").each_with_index do |num|
        hash_target[target.split(" ")[num.to_i].downcase] = num
      end

      array_intersect = hash_source.keys & hash_target.keys
      if array_intersect.count > 0
        align = Alignment.new
        array_intersect.each do |str|
          align = Alignment.new
          align.target_numbers = hash_target[str]
          align.source_numbers = hash_source[str]
          align.tag_name = ""
          add_aligns << align
          alg.source_numbers.gsub!(hash_source[str],"")
          alg.target_numbers.gsub!(hash_target[str],"")
        end

        align_source = Alignment.new
        alg.source_numbers.split(",").each do |source|
          align_source = Alignment.new
          align_source.target_numbers = ""
          align_source.source_numbers = source
          align_source.tag_name = ""
          add_aligns << align_source unless source.empty?
        end

        align_target = Alignment.new
        alg.target_numbers.split(",").each do |target|
          align_target = Alignment.new
          align_target.target_numbers = target
          align_target.source_numbers = ""
          align_target.tag_name = ""
          add_aligns << align_target unless target.empty?
        end

        alg_need_to_delete << index
      end
    end
    aligns.delete_if.with_index { |_, index| alg_need_to_delete.include? index }
    aligns << add_aligns

    aligns.flatten!
    return aligns
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

  def build_number_fce(sentence_pair, text_source, text_target, tag_name)
          source_arr = sentence_pair.source.split(" ")
          target_arr = sentence_pair.target.split(" ")
          text_source_arr = text_source.to_s.split(" ")
          text_target_arr = text_target.to_s.split(" ")
          
          align = Alignment.new
          sentence_pair.Alignment << align
          source_num_arr = []
          target_num_arr = []

          text_source_arr.each_with_index do |_, index|
            source_num_arr << index + source_arr.length
          end

          text_target_arr.each_with_index do |_, index|
            target_num_arr << index + target_arr.length
          end
          align.source_numbers = source_num_arr.join(",")
          align.target_numbers = target_num_arr.join(",")
          align.tag_name = tag_name
  end

  def get_data_fce(path)
    text = "Nokogiri::XML::Text"
    element = "Nokogiri::XML::Element"

    doc = File.open(path) { |f| Nokogiri::XML(f) }
    data = []
    doc.xpath("//p").each do |p|
      sentence_pair = Sentence_Pair.new
      sentence_pair.source = ''
      sentence_pair.target = ''
      data << sentence_pair

      sentence_pair.Alignment = []

      p.children.each do |tag|
        next if tag.to_s.strip == ""
        if tag.class.to_s == text
          build_number_fce(sentence_pair, tag.to_s, tag.to_s, "preserved")
          sentence_pair.source = sentence_pair.source + tag
          sentence_pair.target = sentence_pair.target + tag
        end
        if tag.class.to_s == element
          if tag.name == "NS"
            source_add = ""
            target_add = ""
            tag.children.each_with_index do |nsChild, nsChild_index|
              if nsChild.class.to_s == element and nsChild.children.length == 1 and nsChild.name == "i"
                  source_add = source_add + " " + nsChild.children.first
              end
              if nsChild.class.to_s == element and nsChild.children.length == 1 and nsChild.name == "c"
                target_add = target_add + " " + nsChild.children.first
              end
              if nsChild.name == "i" and nsChild.class.to_s == element and nsChild.children.length > 1
                nsChild.children.each do |i|
                  if i.class.to_s == text
                    source_add = source_add + i
                  end
                  if i.class.to_s == element and i.name == "NS"
                    i.children.each do |insChild|
                      if insChild.class.to_s == element and insChild.children.length == 1 and insChild.name == "i"
                            source_add = source_add + insChild.children.first
                      end
                    end
                  end
                end
              end

              if nsChild_index == (tag.children.length - 1)
                build_number_fce(sentence_pair, source_add, target_add, tag.attributes.first.last.value.to_s)
                sentence_pair.source = sentence_pair.source + source_add
                sentence_pair.target = sentence_pair.target + target_add
              end

            end
          end
        end
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

  def parser_data_nucle(data)
    return_data = []
    data.values.each do |doc|
      doc.values.each do |para|
        para.values.each do |sen|
          #puts "sen --> #{sen.inspect}"
          next if sen.source.strip.empty?
          return_data << parse_sen_nucle(sen)
        end
      end
    end
    return_data
  end

  def parse_sen_nucle(sen)
    algins = sen.Alignment.sort{|x,y| y.source_numbers.split(",").first.to_i <=> x.source_numbers.split(",").first.to_i}
    sen.source = sen.source.strip
    sen.target = sen.target.strip    
    algins.each_with_index do |al, al_index|
      target_replace = al.target_numbers
      str_source_replace = get_string_by_index(al.source_numbers, sen.source)
             
      sen.target, al.target_numbers = replace_string(target_replace[:str_target], str_source_replace, sen.target, al.source_numbers.split(","), al.tag_name)
      
      #puts "sen --> #{sen.inspect}<<<<<<<<<\n\n" if al.tag_name.upcase == 'UM' && target_replace[:str_target] != ''

      if al.target_numbers.include?(",")
        re_align(algins, al_index, al.target_numbers)
      end

      if str_source_replace != target_replace[:str_source]
        #sen.target, al.target_numbers = replace_string(target_replace[:str_target], str_source_replace, sen.source, al.source_numbers.split(","))
        # puts "Some thing wrong #{sen.inspect}"
        # puts "target_replace[:str_source] ->#{target_replace[:str_source]}<"
        # puts "al --> #{al.inspect}"
        # puts "str_source_replace ->#{str_source_replace}<"
      end
    end
    return sen
  end

  def get_data_demo_old(path)
    data = []
    sentence_pair = Sentence_Pair.new
    File.open(path, 'r').each_with_index do |line, index|
      if (index - 1)%3 == 0
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line.gsub("\n","").gsub("\r","")
        next
      end

      if (index - 2)%3 == 0
        sentence_pair.target = line.gsub("\n","").gsub("\r","")
        data << sentence_pair
      end
    end
  end

  def get_data_demo(path1, path2)
    data = []
    puts "path1 --> #{path1}"
    puts "path2 --> #{path2}"
    
    File.open(path1, 'r').each_with_index do |line, index|
        sentence_pair = Sentence_Pair.new
        sentence_pair.source = line.gsub("\n","").gsub("\r","")
        data << sentence_pair
    end
    File.open(path2, 'r').each_with_index do |line, index|
        data[index].target = line.gsub("\n","").gsub("\r","")
    end

    puts "daaaaaaaaa -> #{data}"

    return data
  end

  def build_weka_svm_train(path)
    dir = "./lib/weka.jar"
    Rjb::load(dir, jvmargs=["-Xmx4000M"])
    package_manager = Rjb::import("weka.core.WekaPackageManager")
    package_manager.loadPackages( false, true, false )

    libsvm = Rjb::import("weka.classifiers.functions.LibSVM")
    svm = libsvm.new
    obj = Rjb::import("weka.classifiers.functions.LibSVM")
    classifier = obj.new

    # weka.classifiers.functions.LibSVM -S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1 -model /Users/hvt/Downloads/weka-3-8-0 -seed 1
    options = ("-S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1")
    optionsArray = options.split(" ")
    classifier.setOptions(optionsArray)

    file = Rjb::import("java.io.FileReader").new(path)
    train = Rjb::import("weka.core.Instances").new(file)

    lastIndex = train.numAttributes() - 1

    train.setClassIndex(train.numAttributes() - 1)
    classifier.buildClassifier(train)

    return classifier, train
  end

  def build_weka_svm_test(path, classifier, train)
    dir = "./lib/weka.jar"
    Rjb::load(dir, jvmargs=["-Xmx4000M"])
    package_manager = Rjb::import("weka.core.WekaPackageManager")
    package_manager.loadPackages( false, true, false )

    file = Rjb::import("java.io.FileReader").new(path)
    test = Rjb::import("weka.core.Instances").new(file)

    lastIndex = train.numAttributes() - 1

    test.setClassIndex(test.numAttributes() - 1)

    results = []
    for i in 0..(test.numInstances() - 1)
      index = classifier.classifyInstance(test.instance(i))
      index = index.to_i
      puts "index --> #{index}"
      className = train.attribute(lastIndex).value(index)
      puts "classname --> #{className}"
      results << className
    end
    return results
  end

  def build_weka_svm(path = '', test_path = '')
    dir = "./lib/weka.jar"
    Rjb::load(dir, jvmargs=["-Xmx4000M"])
    package_manager = Rjb::import("weka.core.WekaPackageManager")
    package_manager.loadPackages( false, true, false )

    # abstract_classifier = Rjb::import("weka.classifiers.AbstractClassifier")
    # classifier = abstract_classifier.new
    libsvm = Rjb::import("weka.classifiers.functions.LibSVM")
    svm = libsvm.new
    # classifier = libsvm.new_with_sig('Lweka.classifiers.AbstractClassifier;')
    obj = Rjb::import("weka.classifiers.functions.LibSVM")
    classifier = obj.new
    # java_class = Rjb::import("java.lang.Class").forName("weka.classifiers.functions.LibSVM").newInstance()

    # weka.classifiers.functions.LibSVM -S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1 -model /Users/hvt/Downloads/weka-3-8-0 -seed 1
    options = ("-S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1")
    optionsArray = options.split(" ")
    classifier.setOptions(optionsArray)

    # DataSource = Rjb::import("weka.core.converters.ConverterUtils.DataSource")
    # data_src = DataSource.new(DATA_PATH + "/SWA_20.arff")
    # instance = data_src.getDataSet()
    file = Rjb::import("java.io.FileReader").new(path)
    train = Rjb::import("weka.core.Instances").new(file)

    file_test = Rjb::import("java.io.FileReader").new(test_path)
    test = Rjb::import("weka.core.Instances").new(file_test)

    lastIndex = train.numAttributes() - 1

    train.setClassIndex(train.numAttributes() - 1)
    classifier.buildClassifier(train)

    test.setClassIndex(test.numAttributes() - 1)

    # test.each_with_index do |ins,i|
    #   pred = classifier.classifyInstance(test.instance(i))
    #   puts "ID: #{test.instance(i).value(0)}\n"
    #   puts "Actual: #{test.classAttribute().value(test.instance(i).classValue())}"
    #   puts "Predict: #{test.classAttribute().value(pred)}"
    # end
    # for i in 0..(test.numInstances())
    #   pred = classifier.classifyInstance(test.instance(i))
    #   puts "ID: #{test.instance(i).value(0)}\n"
    #   # puts "classattribute --> #{test.classAttribute().inspect}"
    #   puts "test --> #{test.instance(i).inspect}"
    #   # puts "Actual: #{test.classAttribute().value(test.instance(i).classValue())}"
    #   att = test.classAttribute()
    #   puts "Predict: #{att.value(pred)}"
    # end

    results = []
    for i in 0..(test.numInstances() - 1)
      index = classifier.classifyInstance(test.instance(i))
      index = index.to_i
      puts "index --> #{index}"
      className = train.attribute(lastIndex).value(index)
      puts "classname --> #{className}"
      results << className
    end
    # puts results
    return results

# WekaPackageManager.loadPackages( false, true, false );
# AbstractClassifier classifier = ( AbstractClassifier ) Class.forName(
#             "weka.classifiers.functions.LibSVM" ).newInstance();

# String options = ( "-S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1" );
# String[] optionsArray = options.split( " " );
#     classifier.setOptions( optionsArray );
# classifier.buildClassifier( train );
    
    # obj = Rjb::import("weka.classifiers.functions.LibSVM")
    # classifiers = obj.new

    #load the data using Java and Weka
    # data = Rjb::import("java.io.FileReader").new(path)
    # data = Rjb::import("weka.core.Instances").new(data)
    
    #Find the frequent itemsets
    # weka.classifiers.functions.LibSVM -S 0 -K 0 -D 3 -G 0.0 -R 0.0 -N 0.5 -M 40.0 -C 1.0 -E 0.001 -P 0.1 -model /Users/hvt/Downloads/weka-3-8-0 -seed 1
    # classifiers.setKernelType(0)
    # classifiers.buildClassifier(data)

    # output = File.open(DATA_PATH + "/weka-svm-output.txt", "w")
    # output.write("")
    # output.write(classifier.toString)
    # output.close
  end

  def build_weka_naivebayes(path = '', test_path)
    dir = "./lib/weka.jar"
    Rjb::load(dir, jvmargs=["-Xmx4000M"])
    obj = Rjb::import("weka.classifiers.bayes.NaiveBayes")
    classifiers = obj.new

    #load the data using Java and Weka
    data = Rjb::import("java.io.FileReader").new(path)
    data = Rjb::import("weka.core.Instances").new(data)
    data.setClassIndex(data.numAttributes() - 1)
    
    #Find the frequent itemsets
    classifiers.buildClassifier(data)

    output = File.open(DATA_PATH + "/weka-naivebayes-output.txt", "w")
    output.write("")
    output.write(classifiers.toString)
    output.close
  end

  def assign_classification_results(data_test, classification_results)
    i = 0
    data_test.each_with_index do |line, index|
      line.Alignment.each do |aln|
        aln.tag_name = classification_results[i]
        i = i+1
      end
    end
    return data_test
  end

  def re_align(aligns, al_index, target_numbers)
    aligns.each_with_index do |al, index|
      break if index == al_index
      al.target_numbers = al.target_numbers.split(",").map{|e| e.to_i + target_numbers.split(",").count - 1 }.join(",")
    end
  end

  def replace_string(str_replace, str_need_replace, sen, indexs, tag_name)
    # puts "========================"
    #  puts "str_replace --> #{str_replace}, str_need_replace -->#{str_need_replace}, sen -->#{sen}, indexs -->#{indexs}---"
    sen_arr = []
    frist_matched = false
    sen.split(" ").each_with_index do |e, index|
      
      if indexs.include?(index.to_s)
        # puts "index --> #{index} --> #{frist_matched}"
        if tag_name.upcase == 'UM' && str_replace.empty?
          sen_arr << {:str => e, :is_replace => true}
          next
        end
        if frist_matched == false
          # puts "shit"
          sen_arr << {:str => str_replace, :is_replace => true}
          # puts "sen_arr --> #{sen_arr.inspect}"
          frist_matched = true
        else
          sen_arr << nil
        end
      else
        sen_arr << {:str => e, :is_replace => false}
      end
    end
    target = []
    target_num = []
    
    sen_arr.compact.each_with_index do |e, index|
      if e[:is_replace]
        #  puts "e --> #{e.inspect}"
        target << e[:str].split(" ")
        e[:str].split(" ").each_with_index  do |s, i|
          # puts "sssss"
          target_num << index + i
          #  puts "target_num --> #{target_num}"
        end
      else
        target << e[:str]
      end
    end
    # puts "target --> #{target.inspect}"
    # puts "----------------------"
    return target.join(" "),target_num.join(",")
    #end
  end


  def get_data_nucle(xml_str)
    # DATA_PATH = './data'
    # xml_str = DATA_PATH + "/nucle3.0.sgml"
    # doc = Nokogiri::XML(File.open(xml_str))
    # doc = Nokogiri::Slop(File.open(xml_str))
    # puts "doc --> #{doc.inspect}"
    # docs = XmlSimple.xml_in(xml_str, { 'KeyAttr' => 'name' })

    content = File.open(xml_str,"r:iso-8859-1:utf-8").read
    content.gsub!(/&(?!(?:amp|lt|gt|quot|apos);)/, '&amp;')
    #docs = REXML::Document.new(content)
    docs = XmlSimple.xml_in(content, { 'KeyAttr' => 'name' })

    data = {}
    
    docs["DOC"].each do |doc|
      paras = []
      doc["TEXT"].first["P"].each do |para|
        paras << para
      end

      is_index_zero = doc["TEXT"].first["TITLE"].nil? ? true : false

      doc["ANNOTATION"].first["MISTAKE"].each_with_index do |mis, an_idx|
        # puts "======"
        # if an_idx == 0
        #   is_index_zero = (mis["start_par"].to_i == 0)
        #   puts "Wrong annotation data #{mis}" if mis["start_par"].to_i > 1
        # end
        para_ixd = is_index_zero ? mis["start_par"].to_i : mis["start_par"].to_i - 1
        para = paras[para_ixd].strip
        # puts "Wrong annotation data 2 #{mis}" if (mis["end_par"].to_i - mis["end_par"].to_i) > 1
        length_align = mis["end_off"].to_i - mis["start_off"].to_i

        source, source_index, mis_source_index = find_sen(para.split("."), mis["start_off"].to_i)
        if mis["start_par"].to_i != mis["end_par"].to_i
          length_align = source.length - mis_source_index
        end

        if !data.empty? && data[doc["nid"]] && data[doc["nid"]][para_ixd] && data[doc["nid"]][para_ixd][source_index]
          pair = data[doc["nid"]][para_ixd][source_index]
        else
          pair = Sentence_Pair.new
          pair.Alignment = []

          if !data.empty? && data[doc["nid"]] && data[doc["nid"]][para_ixd]
            data[doc["nid"]][para_ixd][source_index] = pair
          elsif !data.empty? && data[doc["nid"]]
            data[doc["nid"]][para_ixd] = {source_index => pair}
          else
            data[doc["nid"]] = {para_ixd => {source_index => pair}}
          end
        end
        align = Alignment.new
        str_to_replace = para[mis["start_off"].to_i, length_align]
        # if str_to_replace.nil?
        #   puts "para -->#{para}-"
        #   puts "mis -->#{mis}--"
        #   puts "length_align -->#{length_align}---"
        # end
        pair.source = source
        pair.target = source
        source_word, work_index, x = find_sen(source.split(" "), mis_source_index)
        align.source_numbers = work_index.to_s
        #  puts "str_to_replace -->#{str_to_replace}---source_word>#{source_word}<, work_index >#{work_index}<, x >{x}<"
        str_to_replace.strip.split(" ").each_with_index do |e, index|
          #  puts "e --> #{e} -- index #{index}"
            next if index == 0
            align.source_numbers += ',' + (work_index + index).to_s
          end
        align.tag_name = mis["TYPE"].first
        str_tar = mis["CORRECTION"].first.empty? ? "" : mis["CORRECTION"].first
        align.target_numbers = {:str_target => str_tar, :str_source => str_to_replace}
        pair.Alignment << align
        # puts "align -> #{align}"
        # puts "============>>>>>>"
        # break
      end

      #For sen have not any MISTAKE
      paras.each_with_index do |para, index|
        para.split(".").each_with_index do |sen, idx|
          next if data[doc["nid"]] && data[doc["nid"]][index] && data[doc["nid"]][index][idx]
          pair = Sentence_Pair.new
          pair.Alignment = []
          pair.source = sen
          pair.target = sen
          
          if !data.empty? && data[doc["nid"]] && data[doc["nid"]][index]
            data[doc["nid"]][index][idx] = pair
          elsif !data.empty? && data[doc["nid"]]
            data[doc["nid"]][index] = {idx => pair}
          else
            data[doc["nid"]] = {index => {idx => pair}}
          end
        end
      end

    end
    # puts "DATA --> #{data.inspect}"
    data
  end

  def find_sen(arr_str, index)
    #  puts "arr_str --> #{arr_str}"
    #  puts "index --> #{index}"
    len = 0
    arr_str.each_with_index do |sen, idx|
      #  puts "sen -->#{sen}--#{sen.length}"
      len += sen.length + 1
      if index < len
        #  puts "len -> #{len}"
        #  puts "sen -> #{sen} --> #{sen.length}, idx ==> #{idx}, index - (len - (sen.length + 1)) --> #{index - (len - (sen.length + 1))}"
        return [sen, idx, index - (len - (sen.length + 1))]
      end
    end
    return ["", -1, -1]
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

  def generate_data_manli_from_file(path)
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

  def generate_data_manli(data)
    output = File.open(DATA_PATH + "/input_manli.txt", "w")
    output.write("")
    data.each_with_index do |line, index|
      puts line if line.source.empty? or line.target.empty?
      next if line.source.empty? or line.target.empty?
      output.write(line.source + "\t" + line.target + "\n")
    end
  end

  def generate_data_meteor(data)
    output1 = File.open(DATA_PATH + "/source_meteor.txt", "w")
    output1.write("")
    data.each_with_index do |line, index|
      puts "line --> #{line}"
      output1.write(line.source + "\n")
    end

    output2 = File.open(DATA_PATH + "/target_meteor.txt", "w")
    output2.write("")
    data.each_with_index do |line, index|
      output2.write(line.target + "\n")
    end

    output1.close
    output2.close
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

  def print_data_manli(data)
    output_crp = File.open(DATA_PATH + "/output.crp", "w")
    output_crp.write("")
    output_aln = File.open(DATA_PATH + "/output.aln", "w")
    output_aln.write("")

    data.each_with_index do |line, index|
      output_crp.write(index.to_s + "\n")
      output_crp.write(line.source + "\n")
      output_crp.write(line.target + "\n")

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
    file_arff.write("@relation SWA_classification\n\n")
    file_arff.write("@attribute s_str {#{build_distinct_value('s_str', data_features).join(",")}}\n")
    file_arff.write("@attribute t_str {#{build_distinct_value('t_str', data_features).join(",")}}\n")
    file_arff.write("@attribute st_samestr {0,1}\n")
    file_arff.write("@attribute s_stem {#{build_distinct_value('s_stem', data_features).join(",")}}\n")
    file_arff.write("@attribute t_stem {#{build_distinct_value('t_stem', data_features).join(",")}}\n")
    file_arff.write("@attribute st_samestem {0,1}\n")
    file_arff.write("@attribute s_pos {#{build_distinct_value('s_pos', data_features).join(",")}}\n")
    file_arff.write("@attribute t_pos {#{build_distinct_value('t_pos', data_features).join(",")}}\n")
    # file_arff.write("@attribute s_pos STRING")
    # file_arff.write("@attribute t_pos STRING")
    file_arff.write("@attribute st_precede {0,1}\n")
    file_arff.write("@attribute st_follow {0,1}\n")
    file_arff.write("@attribute class {preserved,bigrammar-vtense,bigrammar-wform,bigrammar-inter,paraphrase,unaligned,mogrammar-prep,mogrammar-det,bigrammar-prep,bigrammar-det,bigrammar-others,typo,spelling,duplicate,moproblematic,biproblematic,unspec}\n\n")
    file_arff.write("@data\n")

    data_features.each do |ft|
      array = [ft.s_str, ft.t_str, ft.st_samestr, ft.s_stem, ft.t_stem, ft.st_samestem, ft.s_pos, ft.t_pos, ft.st_precede, ft.st_follow, ft.tag_name]
      file_arff.write(array.map{|e| (e == nil || e == "") ? "?" : "#{e}"}.join(",") + "\n")
    end
    file_arff.close
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

  # In ra file alignment nhu dinh dang co dua
  def print_alignments(data, filename, file)
    data.each do |line|
      line.Alignment.each do |aln|
        source_phrase = get_string_by_index(aln.source_numbers, line.source)
        target_phrase = get_string_by_index(aln.target_numbers, line.target)
        array = [filename.gsub("\n",""), line.source.gsub("\n",""), line.target.gsub("\n",""), source_phrase.gsub("\n",""), target_phrase.gsub("\n",""), aln.tag_name.gsub("\n","")]
        # puts "print_alignments array --> #{array}"
        file.write (array.join("@") + "\n")
      end
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

      # source_remain.each do |remain|
      #   pairs.Alignment << Alignment.new(remain.to_s,"","unaligned")
      # end
      # target_remain.each do |remain|
      #   pairs.Alignment << Alignment.new("",remain.to_s,"unaligned")
      # end

      aligns = []
      max_s = 0
      max_t = 0
      pairs.Alignment.each_with_index do |aln, i|
        s_nums = aln.source_numbers.split(",").map(&:to_i)
        t_nums = aln.target_numbers.split(",").map(&:to_i)
        if s_nums.include?(max_s)
          aligns << aln
          max_s = s_nums.max
          max_t = t_nums.max
          next
        end

        count_miss_s = s_nums.min - max_s
        count_miss_t = t_nums.min - max_t

        if ( count_miss_s == 1) && (count_miss_t == 1)
          aligns << aln
          max_s = s_nums.max
          max_t = t_nums.max
          next
        else
          if count_miss_s > 1
            ((max_s + 1)..(max_s + count_miss_s - 1)).each do |i|
              aligns << Alignment.new(i.to_s, "", "unaligned")
            end
          end

          if count_miss_t > 1
            ((max_t + 1)..(max_t + count_miss_t - 1)).each do |i|
              aligns << Alignment.new("", i.to_s,"unaligned")
            end
          end
          aligns << aln
          max_s = s_nums.max
          max_t = t_nums.max
        end
      end

      pairs.Alignment = aligns

    end
    return data
  end

  def refine_tag_preserved(data)
    data.each do |line| 

      aln_arrs = []
      aln_delete = []
      line.Alignment.each_with_index do |aln,i|
        if (aln.tag_name == "preserved") and (aln.source_numbers.include? ",") and (aln.target_numbers.include? ",") and (aln.source_numbers.scan(/,/).count == aln.target_numbers.scan(/,/).count)
        #if (aln.tag_name == "preserved") and (aln.source_numbers.scan(/,/).count != aln.target_numbers.scan(/,/).count)
          #puts ("#{line}\n\n")
          #puts ("#{aln}\n\n")
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

  def reduce_tags_exact(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "exact")
          aln_delete << i
          count = count + 1
          break if count >= 67782
        end
        break if count >= 67782
      end
      # delete preserved alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 67782 
      # 69683 SWA 100
      # 69000 Meteor 100
      # 68322 Manli 100
      # 67782 moses 100
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
          break if count >= 1601
        end
        break if count >= 1601
      end
      # delete unaligned alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 1601
      # 1839 SWA 100
      # 1114 Meteor 100
      # 1629 manli 100
      # 1601 moses 100

      # 1579 manli 20 
      # 224 moses 20
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
          break if count >= 410663
        end
        break if count >= 410663
      end
      # delete preserved alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 410663 
      # 58004 SWA 80
      # 11562 SWA 20
      # 69566 SWA 100
      # 11360 meteor 20
      # 68494 meteor 100
      # 11375 manli 20
      # 67825 manli 100
      # 11185 moses 20
      # 67416 moses 100
      # 68935 moses improved 100
      #  104215 quynhanh 100
      # 87523 meteor qa 100
      # 101860 manli qa 100 
      # 394068 meteor fce 100
      # 349390 manli fce 100
      # 410663 FCE 100
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
          break if count >= 1297
        end
        break if count >= 1297
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 1297
      # 312 SWA 80
      # 48 SWA 20
      # 360 SWA 100
      # 1297 quynhanh 100
    end
    return data
  end

  def reduce_tags_mogdet(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "mogrammar-det")
          aln_delete << i
          count = count + 1
          break if count >= 705
        end
        break if count >= 705
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 705
      #  808  quynhanh 100
      # 562 meteor qa 100
      # 705 manli qa 100
    end
    return data
  end

  def reduce_tags_waln(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "waln")
          aln_delete << i
          count = count + 1
          break if count >= 160515
        end
        break if count >= 160515
      end
      # delete wa alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 160515 
      # 12456 meteor 100
      # 13012 manli 100
      # 6728 moses 100 

      # 2643 meteor 20
      # 11945 meteor 100
      # 2325 manli 20
      # 12505 manli 100
      # 1100 moses 20
      # 6358 moses 100
      # 8033 moses improved 100

      # 32360 meteor qa 100
      # 17228 manli qa 100

      # 950116 Nucle meteor
      # 1017552 nucle manli
      # 80493 meteor fce 100
      # 160515 manli fce 100
    end
    return data
  end

  def reduce_tags_Rloc(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "Rloc")
          aln_delete << i
          count = count + 1
          break if count >= 2411
        end
        break if count >= 2411
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 2411
      #  1881 Nucle meteor
      # 2411 Nucle
    end
    return data
  end

  def reduce_tags_ArtOrDet(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "ArtOrDet")
          aln_delete << i
          count = count + 1
          break if count >= 2055
        end
        break if count >= 2055
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 2055
      #  2055 Nucle
    end
    return data
  end

  def reduce_tags_Wcip(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "Wcip")
          aln_delete << i
          count = count + 1
          break if count >= 1096
        end
        break if count >= 1096
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 1096
      #  3336 Nucle 
      # 1096 Nucle manli
    end
    return data
  end

  def reduce_tags_Nn(data)
    count = 0
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name == "Nn")
          aln_delete << i
          count = count + 1
          break if count >= 848
        end
        break if count >= 848
      end
      # delete paraphrase alignments in the original array
      line.Alignment.delete_if.with_index { |_, index| aln_delete.include? index }
      break if count >= 848
      #  848 Nucle manli
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

  def remove_all_but_wa(data)
    data.each do |line|
      aln_delete = []
      line.Alignment.each_with_index do |aln, i|
        if (aln.tag_name != "wa")
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

  # Xoá những cặp câu có source hoặc target rỗng. Vì khi generate data manli
  # mình phải xoá những cặp câu này (để khỏi lỗi). 
  # Dùng với data nucle 
  def remove_blank_senpair(data)
    data1 = []
    data.each_with_index do |line, index|
      next if line.source.empty? or line.target.empty?
      data1 << line
    end
    return data1
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
        # puts "#{alignment1.source}"
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

  def assign_tags_waln(data)
    data.each do |line|
      line.Alignment.each do |aln|
        if (aln.tag_name.empty?)
          aln.tag_name = "waln"
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
      arr_tmp = data1[index].Alignment.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers }} & data2[index].Alignment.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers}}
     # arr_tmp = data1[index].Alignment.select{|e| e[:tag_name] != "preserved"}.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers }} & data2[index].Alignment.map{|e|{:source_numbers => e.source_numbers, :target_numbers => e.target_numbers}}
      # puts "line --> #{alignment1}\n"
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

  def convert_typo_spelling(data)
    data.each do |line|
      line.Alignment.each do |aln|
        if aln.tag_name == "typo" or aln.tag_name == "spelling"
          aln.tag_name = "typo-spelling"
        end
      end
    end
    return data
  end

  def build_output_data(data)
    output = {}
    data.each_with_index do |pair, index_pair|
      output[index_pair] = []
      pair.Alignment.each_with_index do |alg, index_aln|
        output[index_pair] << [
          get_string_by_index(alg.source_numbers, pair.source), 
          get_string_by_index(alg.target_numbers, pair.target), 
          alg.tag_name
          ]
      end
    end
    output
  end

    def build_statistics(data)
    output = {}
    output["Total"] = {:count => 0, :percent => "100%"}
    data.each_with_index do |pair, index_pair|
      output["Total"][:count] += pair.Alignment.select {|alig| alig.tag_name != PRESERVED}.length
    end

    data.each_with_index do |pair, index_pair|
      pair.Alignment.each_with_index do |alg, index_aln|
        if alg.tag_name != PRESERVED
          if output[alg.tag_name].nil?
            output[alg.tag_name] = {:count => 1, :percent => (((1.to_f/output["Total"][:count].to_f)*100.0).round(2)).to_s + "%"}
          else
            output[alg.tag_name][:count] += 1
            percent = ((output[alg.tag_name][:count].to_f/output["Total"][:count].to_f)*100).round(2)
            output[alg.tag_name][:percent] = percent.to_s + "%"
          end
        end
      end
    end
    output
  end

end


# obj = ReadData.new
# obj.main

