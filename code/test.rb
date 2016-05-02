require './read_data.rb'

class Test
  def main
    read = ReadData.new
    read.main
  end
end

obj = Test.new
obj.main