require 'rubygems'


def funcA
  i=0

  while i <=10
    puts 'func A at: ' + Time.now.to_s + "\n"
    sleep(2)
    i=i+1
  end

  return 69
end

def funcB
  (0..10).each do
    puts 'func B at: ' + Time.now.to_s + "\n"
    sleep(2)
  end

  return 70
end

puts 'Start Threads at: ' + Time.now.to_s


############# thread list #############
ths = []

############# return data list #############
thsReturn = []



############# generate threads that will return results to array list #############
100.times do |i|
  ths[i] = Thread.new{thsReturn.push(funcA)}
  ths[i] = Thread.new{thsReturn.push(funcB)}
end


############ Wait threads to end #############
while true
  # variable the control thread ends
  isthalive = false

  # check if all threads are alive
  ths.each do |th|
    isthalive = true if th.alive?
  end

  # if all threads are thead then end waiting
  break if !isthalive
end


############### Show results from threads #################
thsReturn.each do |ret|
  puts ret
end

puts 'The end at: ' + Time.now.to_s
