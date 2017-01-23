#require './read_data.rb' -- test
require "json"
require 'nokogiri'


class Test
  def main
    # read = ReadData.new
    # read.main
    read_xml
  end

  def read_json
    file = File.read("./data/sample_json.json")
    data = JSON.parse(file)
    puts "data"
    puts "#{data.inspect}"
    
  end

  def read_xml
xml_str = "./data/test.xml"

    doc = File.open(xml_str) { |f| Nokogiri::XML(f) }

    #puts "Doc --> #{doc.xpath("//p").inspect}"

    doc.xpath("//p").each_with_index do |p|
      p.children.each_with_index do |tag|
        puts "tag --> #{tag}"
        puts "tag class --> #{tag.class}\n\n"
      end
    end
  end
end

obj = Test.new
obj.main