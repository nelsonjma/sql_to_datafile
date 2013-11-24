def add(a)
  a + 1
end

a = 4

a = add(a)

puts a



def multi_return
  return 1, 'a'
end

a, b = multi_return

puts a.to_s + b


c = 5
c+= -1
puts c