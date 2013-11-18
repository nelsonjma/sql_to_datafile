require 'rubygems'
require 'nokogiri'

file = File.open('config.xml')
document = Nokogiri::XML(file)
file.close


# Get just one element
puts document.xpath('//config/path').first.child

puts '----------------------------------'

listData = []

# Get multiple elements
document.xpath('//config/path').each do |p|
  #puts p.node_name.to_s + ' --> ' + p.child.to_s + ' --> ' +  p.path
  listData.push(p.child)
end

listData.each do |element|
  puts element
end

