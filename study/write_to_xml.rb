require 'rubygems'
require 'nokogiri'

class XmlElement
  attr_accessor :name, :value

  def initialize(name, value)
    @name = name
    @value = value
  end
end

element = []
element.push(XmlElement.new('data', '1'))
element.push(XmlElement.new('data', '2'))
element.push(XmlElement.new('data', '3'))


builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.root {
    element.each do |elem|
      xml.table {
        xml.send(elem.name, elem.value.to_s)
      }
    end
  }
end

puts builder.to_xml