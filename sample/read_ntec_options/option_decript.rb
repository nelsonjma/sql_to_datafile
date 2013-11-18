require 'rubygems'

def RemoveUnwantedChars(data)

  data = data.gsub('\r\n', ' ')
  data = data.gsub('\t', ' ')
  data = data.gsub('\n', ' ')

  data.strip
end

str_options = '/*qerqwerqwer*/ data=[cenas]; uln=[ [ola], \n [coisas e \n cenas] ];'
puts str_options

# replace all special charaters
str_options = RemoveUnwantedChars(str_options)

# list options
optionslist = str_options.split(%r{\*/|\];})

optionslist.each do |op|
  if op.to_s.index('=') != nil

    puts ''

    # get name
    name = op[0..op.index('=')-1]
    puts 'name: ' + name

    # get option
    optionstr = op[op.index('=')+2..op.length]

    puts 'option unfiltered: ' + optionstr

    if optionstr.index('],') == nil
      puts 'option: ' + optionstr
    else
      option_items =  optionstr.split(%r{\],})

      option_items.each do |item|
        this_item = item.strip

        # remove start [
        this_item = this_item[1..this_item.length]

        # check if exists ] if so then remove it
        if this_item.index(']') != nil
          this_item = this_item[0..this_item.length-2]
        end

        puts 'option list: ' + this_item
      end
    end

  end

end



