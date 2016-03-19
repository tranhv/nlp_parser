# Document convert NLP
# Convert NLP
class FindNil

  def main
    line_count = 0
    paras = []
    para_start = false
    para_end = false
    para = {}
    index = 0

    file_out = File.new("output/out_nil.txt", "w+")

    Dir.glob("input/Annotation-4-with-preprocess.txt") {|filename|
      file = File.new(filename)
      puts "Running file: #{File.basename(file)}"

      File.foreach(file) { |r|
        line_count += 1
        next if line_count <= 3

        if ((line_count - 4) % 5 == 0)
          para_start = true
          index = 1
          para = {}
          para[index] = r
          next
        end

        if para_start
          index += 1
          para[index] = r
        end

        if index == 3 and para_start
          paras << para
          para_start = false
        end
      }
    }
    nil_first = 0
    nil_second = 0
    paras.each { |para| 
      nil_first_tmp, nil_second_tmp = find_nil_para(para)
      if nil_first_tmp.count != 0 or nil_second_tmp.count != 0
        nil_first += nil_first_tmp.count
        nil_second += nil_second_tmp.count
        file_out.write("--------------------------\n")
        file_out.write(para)
        file_out.write("nil_first --> #{nil_first_tmp.inspect}\n")
        file_out.write("nil_second --> #{nil_second_tmp.inspect}\n")
      end
    }

    file_out.write("Total first --> #{nil_first}\n")
    file_out.write("Total second --> #{nil_second} \n")
    file_out.write("Total --> #{nil_second + nil_first}\n")
    file_out.close
  end


  def find_nil_para para
    first = para[1]
    second = para[2]
    aline = para[3]

    count_first = []
    count_second = []
    
    aline.split(" ").each do |e|
      count_second_tmp,count_first_tmp = parse_term(e)
      count_first << count_first_tmp
      count_second << count_second_tmp
    end

    puts "para ==> #{para}"
    puts "count_second ==> #{count_second}"

    count_second.flatten!.sort! { |a, b| a <=> b} unless count_second.count == 0
    count_first.flatten!.sort! { |a, b| a <=> b} unless count_first.count == 0


    remain_first = (0..(first.split(" ").count - 1)).to_a - count_first
    remain_second = (0..(second.split(" ").count - 1)).to_a - count_second

    
    #puts "count_first --> #{count_first.inspect}"
    #puts "remain_first --> #{remain_first.inspect}"

    #puts "count_second --> #{count_second.inspect}"
    #puts "remain_second --> #{remain_second.inspect}"
    return remain_first,remain_second
  end

  def parse_term term
    alines = term.split('#')
    second = alines[1].split(",").map{|e| e.to_i}
    first = alines[2].split(",").map{|e| e.to_i}
    return second, first
  end

end

a = FindNil.new
a.main
