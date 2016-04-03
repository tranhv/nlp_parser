# Merge full_aln.txt and full_crp.txt
# Input: Corpus *.aln, *.crp
# Output: full.txt

class Merge_aln_crp
  INPUT_PATH = "./input"
  OUTPUT_PATH = "./output"

  #return array with 
  def get_alns
    array_alns = []
    File.open(INPUT_PATH + "/full_aln.txt", 'r').each do |line|
      #next if line.split(" ").count == 2 or line.strip == ''
      array_alns << line
    end
    return array_alns
  end

  def get_crp
    array_crps = []
    arr = []
    flag_para = false
    alns = get_alns
    index_aln = 0
    File.open(INPUT_PATH + "/full_crp.txt", 'r').each_with_index do |line, index|
      #next if line.match(/^</) or line.strip.match(/\A\d+\z/)
      
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

  def get_anotation
    array_anos = []
    arr = []
    flag_para = false
    File.open(INPUT_PATH + "/Annotation-5-with-preprocess.txt", 'r').each_with_index do |line, index|
      next if index < 3
      
      if (index - 3) % 5 == 0
        arr = []
        arr << line
        next
      end

      if (index - 4)%5 == 0
        arr << line
        next
      end

      if index%5 == 0
        arr << line
        array_anos << arr
      end
    end
    return array_anos
  end

  def write_merge(out_path)
    crp_alns = get_crp
    anos = get_anotation

    file_merge_ano_crp_aln = File.open(out_path,"w")
    file_merge_ano_crp_aln.write("")

    anos.each_with_index do |ano, index|
      crp_alns.each do |crp|
        if crp[1] == ano[0] and crp[2] == ano[1]
          file_merge_ano_crp_aln.write(ano.join(""))
          file_merge_ano_crp_aln.write(crp[3].to_s)
          file_merge_ano_crp_aln.write("\n")
          break
        end
      end

    end
    file_merge_ano_crp_aln.close
  end
  
  def main

    write_merge("#{OUTPUT_PATH}/file_merge_ano_crp_aln.txt")

    puts "get_crp #{get_crp.count}"
    puts "get_alns #{get_alns.count}"
    puts "ano #{get_anotation.count}"

  #   file1 = File.open(INPUT_PATH + "/full_aln.txt", 'r').readlines
  #   file2 = File.open(INPUT_PATH + "/full_crp.txt", 'r').readlines

  
  
  # join_file = File.open("./output/full.txt","w")
  # join_file.write("")

  # out_path = "#{OUTPUT_PATH}/full.txt"
  #   join_file = File.open(out_path,"a+")

  #   file1.each_with_index do |line1, index|

  #     puts "index: #{index}"
  #     puts "line1: #{line1}"
  #     line2 = file2[index]
  #     puts "line2: #{line2}"

  #       #join_files(line1, line2, out_path)

  #   end

  #   join_file.close

  end

end


obj = Merge_aln_crp.new
obj.main
