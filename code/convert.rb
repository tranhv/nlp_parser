# Convert from GIZA++ alignment file format to Yawat alignment file format

class Convert
  def parser line
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

    source_match_array.each_with_index do |item,index|
      unless null_value.count == 0
        tmp_index = index - 1
      end

      if item[0] == 'NULL'
        null_value << item
      else
        target_tag = item[1].gsub(/[{()}]/,"")
        result += ' ' + tmp_index.to_s + ':' + target_tag.split(",").map {|e| 
          if e.to_i == 0
            e.to_s
          else
            e.to_i - 1
          end
          }.join(",").strip
        end
      end


      unless null_value.count == 0 
        target_tag_null = null_value[0][1].gsub(/[{()}]/,"").split(",").map { |e| 
          if e.to_i == 0
            e.to_s
          else
            e.to_i - 1
          end
        }
        result += " :" + target_tag_null.join(",") unless target_tag_null.count == 0
      end

      result
    end

#a = "   NULL ({ 7 }) This ({ 1 12 }) paper ({ 2 }) analyzes ({ 3 }) 33 ({4})"
#b = a.gsub(/\(\{(\w*\s*)*\}\)/) {
 # |tmp| tmp.gsub(/(\s*\w*)*/) {
  #        |tmp1| tmp1.strip.gsub(/\s/,",")
  #      }

 # }.strip

#For example , the parsing accuracy for the Brown corpus is significantly lower than that for the Wall Street Journal ( WSJ ) portion of the Penn Treebank , even when re-training the parser with much more in-domain training data than other successful domains . --> target
#1   2       3 4   5       6        7   8   9     10     11 12            13    14   15   16  17  18   19     20      21 22 23 24     25 26  27   28       29 30  31   32          33  34     35   36   37   38        39       40   41   42    43         44      45  
#For example , the parsing accuracy for the Brown corpus is significantly lower than for the WSJ portion of the Penn Treebank , even when re-training the parser with much more in-domain training data than other successful domains .
#1   2       3 4   5       6        7   8   9     10     11 12            13    14   15  16  17  18      19 20  21   22       23 24  25   26          27  28     29   30   31   32        33       34   35   36    37         38      39

#NULL ({ 15 21 23 }) For ({ 1 }) example ({ 2 }) , ({ 3 }) the ({ 4 }) parsing ({ 5 }) accuracy ({ 6 }) for ({ 7 }) the ({ 8 }) Brown ({ 9 }) corpus ({ 10 }) is ({ 11 }) significantly ({ 12 }) lower ({ 13 }) than ({ 14 }) for ({ 16 }) the ({ 17 }) WSJ ({ 22 }) portion ({ 24 }) of ({ 25 }) the ({ 26 }) Penn ({ 27 }) Treebank ({ 28 }) , ({ 29 }) even ({ 30 }) when ({ 31 }) re-training ({ 32 }) the ({ 33 }) parser ({ 34 }) with ({ 35 }) much ({ 36 }) more ({ 37 }) in-domain ({ 38 }) training ({ 39 }) data ({ 40 }) than ({ 41 }) other ({ 42 }) successful ({ 18 19 20 43 }) domains ({ 44 }) . ({ 45 }) --> source
#20 0:0:d 1:1:d 2:2:d 3:3:d 4:4:d 5:5:d 6:6:d 7:7:d 8:8:d 9:9:d 10:10:d 11:11:d 12:12:d 13:13:d 14:15:d 15:16:d 16:17,18,19,21:p 17:23:d 18:24:d 19:25:d 20,21:26,27:d 23,24:29,30:d 25:31:d 26:32:d 27:33:d 28:34:d 29:35:d 30:36:d 31:37:d 32,33:38,39:d 34:40:d 35:41:d 36:42:d 37:43:d :14:unaligned

#line = "NULL ({ 15 21 23 }) For ({ 1 }) example ({ 2 }) , ({ 3 }) the ({ 4 }) parsing ({ 5 }) accuracy ({ 6 }) for ({ 7 }) the ({ 8 }) Brown ({ 9 }) corpus ({ 10 }) is ({ 11 }) significantly ({ 12 }) lower ({ 13 }) than ({ 14 }) for ({ 16 }) the ({ 17 }) WSJ ({ 22 }) portion ({ 24 }) of ({ 25 }) the ({ 26 }) Penn ({ 27 }) Treebank ({ 28 }) , ({ 29 }) even ({ 30 }) when ({ 31 }) re-training ({ 32 }) the ({ 33 }) parser ({ 34 }) with ({ 35 }) much ({ 36 }) more ({ 37 }) in-domain ({ 38 }) training ({ 39 }) data ({ 40 }) than ({ 41 }) other ({ 42 }) successful ({ 18 19 20 43 }) domains ({ 44 }) . ({ 45 }) "

#source_match = source_group_matches.each_slice( 2 ).map { |e| e }
#=> {"NULL"=>"({15,21,23})", "For"=>"({1})", "example"=>"({2})", ","=>"({29})", "the"=>"({33})", "parsing"=>"({5})", "accuracy"=>"({6})", "for"=>"({16})", "Brown"=>"({9})", "corpus"=>"({10})", "is"=>"({11})", "significantly"=>"({12})", "lower"=>"({13})", "than"=>"({41})", "WSJ"=>"({22})", "portion"=>"({24})", "of"=>"({25})", "Penn"=>"({27})", "Treebank"=>"({28})", "even"=>"({30})", "when"=>"({31})", "re-training"=>"({32})", "parser"=>"({34})", "with"=>"({35})", "much"=>"({36})", "more"=>"({37})", "in-domain"=>"({38})", "training"=>"({39})", "data"=>"({40})", "other"=>"({42})", "successful"=>"({18,19,20,43})", "domains"=>"({44})", "."=>"({45})"}
#irb(main):012:0* source_match.keys
#=> ["NULL", "For", "example", ",", "the", "parsing", "accuracy", "for", "Brown", "corpus", "is", "significantly", "lower", "than", "WSJ", "portion", "of", "Penn", "Treebank", "even", "when", "re-training", "parser", "with", "much", "more", "in-domain", "training", "data", "other", "successful", "domains", "."]


def main
  Dir.glob("input/test.UA3.final") {|filename|
    file = File.new(filename)
    puts "Running file: #{File.basename(file)}"

    file_out = File.new("output/#{File.basename(file,".*")}_out.txt", "w+")

    line_count = 0
    File.foreach(file) { |r|
      line_count += 1

      if (line_count % 3) == 0
        file_out.write(parser(r))
        file_out.write("\n")
      end
    }

    file_out.close
  }
end

end

a = Convert.new
a.main
