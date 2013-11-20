require 'rubygems'
require 'nokogiri'

# installed gems
#mini_portile-0.5.2.gem
#mini_portile-0.5.2
#nokogiri-1.6.0-x86-mingw32.gem

#sample
#<config>
#  <path>c:\demo\data.txt</path>
#  <path>c:\demo\data.txt</path>
#  <path>c:\demo\data.txt</path>
#  <path>c:\demo\data.txt</path>
#</config>

class ReadXml
  attr_accessor :document, :xml_file

  def initialize(xml_file)
    @xml_file = xml_file
    @document = nil

    get_xml_data
  end

  # get the xml file content to memory
  def get_xml_data
    begin
      file = File.open(@xml_file)
      @document = Nokogiri::XML(file)
      file.close
    rescue Exception => e
      throw e.message
    end
  end

  # path example => //config/path
  def first_element(path)
    if @document == nil
      return ''
    end

    @document.xpath(path).first.child
  end

  # path example => //config/path
  def all_elements(path)
    elements = []

    if @document == nil
      return elements
    end

    @document.xpath(path).each do |elem|
      elements.push(elem.child)
    end

    elements
  end

  # clean global objects
  def dispose
    @document = nil
    @xml_file = nil
  end

  private :get_xml_data
end