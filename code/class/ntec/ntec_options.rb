require 'rubygems'

class NtecOption
  attr_accessor :name, :options
end

class NtecOptions
  attr_accessor :_option, :ntec_option_list

  def initialize(option)
    @_option = option
    @ntec_option_list = []

    self.process
  end

  #################### PRIVATE ####################
  # remove \n\r \n \t
  def remove_unwanted_chars(data)

    data = data.gsub("\r\n", ' ')
    data = data.gsub("\t", ' ')
    data = data.gsub("\n", ' ')

    data.strip
  end

  # option list [A], [b], [C]
  def process_item_list(item)
    aux_item = item.strip

    # remove start [
    if aux_item.start_with?('[')
      aux_item = aux_item[1..aux_item.length]
    end

    # remove end ]
    if aux_item.end_with?(']')
      aux_item = aux_item[0..aux_item.length-2]
    end

    aux_item
  end

  ################## PUBLIC ##################
  # transform the string in ntec options array
  def process
    aux_option = remove_unwanted_chars(@_option)

    # unprocessed option list
    option_list = aux_option.split(%r{\*/|\];})

    option_list.each do |op|
      begin
        if op.to_s.index('=[') != nil
          ntec_option = NtecOption.new
          ntec_option.options = []

          # get option name
          ntec_option.name = op[0..op.index('=[')-1].strip

          # get unprocessed option
          unprocessed_option = op[op.index('=[')+2..op.length]

          # process option
          if (unprocessed_option.to_s.index('],')) == nil
            ntec_option.options.push(unprocessed_option.strip) # return just one item...
          else
            # split option list [A], [b], [C]
            option_items =  unprocessed_option.split(%r{\],})

            option_items.each do |item|
              aux_item = item.strip

              if aux_item != ''
                processed_item = process_item_list(aux_item)
                ntec_option.options.push(processed_item)
              end
            end
          end
          @ntec_option_list.push(ntec_option)
        end

      rescue Exception => e
        puts 'Error processing option: ' + e.message
      end

    end
  end

  def get_first(name)
    pos = ntec_option_list.find_index{|item| item.name.downcase == name.downcase}

    if pos != nil && pos < ntec_option_list.count && ntec_option_list[pos].options.count > 0
      return ntec_option_list[pos].options[0]
    end

    ''
  end

  def get_all(name)
    pos = ntec_option_list.find_index{|item| item.name.downcase == name.downcase}

    if pos != nil && pos < ntec_option_list.count
      return ntec_option_list[pos].options
    end

    []
  end

  private :remove_unwanted_chars, :process_item_list
end


