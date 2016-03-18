# Document convert NLP
# Convert NLP
class FindNil
  def parser line
    
  end

  def main
    line_count = 0
    paras = []
    para_start = false
    para_end = false
    para = {}
    index = 0

    Dir.glob("input/test.txt") {|filename|
      file = File.new(filename)
      puts "Running file: #{File.basename(file)}"

      #file_out = File.new("output/#{File.basename(file,".*")}_out.txt", "w+")

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
      
      puts paras.count
      puts paras.inspect
  end

[{
  1=>"This paper analyzes the effect of the structural variation of sentences on parsing performance .\n", 
  2=>"This paper analyzes the effects of structural variation of sentences on parsing performances .\n", 
  3=>"-1#0#0#exact -1#1#1#exact -1#2#2#exact -1#3#3#exact -1#4,5#4,5,6#para -1#6#7#exact -1#7#8#exact -1#8#9#exact -1#9#10#exact -1#10#11#exact -1#11#12#exact -1#12#13#stem -1#13#14#exact \n"
  }, 
  {1=>"We examine the performance of both shallow and deep parsers for two sentence constructions : imperatives and questions .\n", 
    2=>"We examined the performances of both shallow and deep parsers for two sentence constructions : imperatives and questions .\n", 
    3=>"-1#0#0#exact -1#1#1#stem -1#2#2#exact -1#3#3#stem -1#4#4#exact -1#5#5#exact -1#6#6#exact -1#7#7#exact -1#8#8#exact -1#9#9#exact -1#10#10#exact -1#11#11#exact -1#12#12#exact -1#13#13#exact -1#14#14#exact -1#15#15#exact -1#16#16#exact -1#17#17#exact -1#18#18#exact \n"}]


  def find_nil_para para
    first = para[1]
    second = para[2]
    aline = para[3]
    aline.split(" ").each do |e|
    end

  end

  def parse_term term
    alines = term.split('#')
    alines[1].split(",").map{|e| e.to_i}, alines[2].split(",").map{|e| e.to_i}
  end

end

a = FindNil.new
a.main
