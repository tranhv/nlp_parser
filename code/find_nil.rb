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


  def find_nil_para para
    
  end

end

a = FindNil.new
a.main
