#require './read_data.rb'
require "json"

class Test
  def main
    # read = ReadData.new
    # read.main
    read_json
  end

  def read_json
    file = File.read("./data/sample_json.json")
    data = JSON.parse(file)
    puts "data"
    puts "#{data.inspect}"
    
  end
end

obj = Test.new
obj.main