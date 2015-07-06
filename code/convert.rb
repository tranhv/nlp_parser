
class Convert

def parser line
  source = line.gsub("NULL","").gsub(/\s*\(\{(\w*\s*)*\}\)\s*/," ").strip

  #  "NULL ({7}) This ({1,12}) paper ({2}) analyzes ({3}) 33 ({4})"
  # ["NULL", "({7})", "This", "({1,12})", "paper", "({2})", "analyzes", "({3})", "33", "({4})"]
  source_group_matches = line.gsub(/\(\{(\w*\s*)*\}\)/) {
  |tmp| tmp.gsub(/(\s*\w*)*/) {
          |tmp1| tmp1.strip.gsub(/\s/,",")
        }

  }.strip.split(" ")


end

a = "   NULL ({ 7 }) This ({ 1 12 }) paper ({ 2 }) analyzes ({ 3 }) 33 ({4})"
b = a.gsub(/\(\{(\w*\s*)*\}\)/) {
  |tmp| tmp.gsub(/(\s*\w*)*/) {
          |tmp1| tmp1.strip.gsub(/\s/,",")
        }

  }.strip

#Note that , since the training of the MST parser ( second order ) on Brown overall , Brown questions , and QuestionBank could not be completed in our experimental environment , the corresponding parsing accuracies denoted by bracketed hyphens in Table \REF could not be measured , Consequently , we could not plot complete graphs of second order MST for Brown questions and QuestionBank in Figure \REF . --> target

#"Note that , since training MST parser ( second order ) on Brown overall , Brown questions , and QuestionBank could not be completed in our experimental environments , the parsing accuracies represented by the bracketed hyphens in Table \\REF could not be measured and we could not draw full graphs of second order MST for Brown questions and QuestionBank in Figure \\REF ." --> source
#NULL ({ 5 7 8 48 50 }) Note ({ 1 }) that ({ 2 }) , ({ 3 }) since ({ 4 }) training ({ 6 }) MST ({ 9 }) parser ({ 10 }) ( ({ 11 }) second ({ 12 }) order ({ 13 }) ) ({ 14 }) on ({ 15 }) Brown ({ 16 }) overall ({ 17 }) , ({ 18 }) Brown ({ 19 }) questions ({ 20 }) , ({ 21 }) and ({ 22 }) QuestionBank ({ 23 }) could ({ 24 }) not ({ 25 }) be ({ 26 }) completed ({ 27 }) in ({ 28 }) our ({ 29 }) experimental ({ 30 }) environments ({ 31 }) , ({ 32 }) the ({ 33 }) parsing ({ 34 35 }) accuracies ({ 36 }) represented ({ 37 }) by ({ 38 }) the ({ }) bracketed ({ 39 }) hyphens ({ 40 }) in ({ 41 }) Table ({ 42 }) \REF ({ 43 }) could ({ 44 }) not ({ 45 }) be ({ 46 }) measured ({ 47 }) and ({ 49 }) we ({ 51 }) could ({ 52 }) not ({ 53 }) draw ({ 54 }) full ({ 55 }) graphs ({ 56 }) of ({ 57 }) second ({ 58 }) order ({ 59 }) MST ({ 60 }) for ({ 61 }) Brown ({ 62 }) questions ({ 63 }) and ({ 64 }) QuestionBank ({ 65 }) in ({ 66 }) Figure ({ 67 }) \REF ({ 68 }) . ({ 69 }) 

def main
  Dir.glob("input/test.final") {|filename|
  file = File.new(filename)
  puts "Running file: #{File.basename(file)}"
  
  file_out = File.new("output/#{File.basename(file,".*")}_out.txt", "w+")
  
  line_count = 0
  File.foreach(file) { |r|
    line_count += 1

    if (line_count % 3) == 0
      puts r.inspect
      parser(r)
    end
  }
}
end

end

a = Convert.new
a.main
