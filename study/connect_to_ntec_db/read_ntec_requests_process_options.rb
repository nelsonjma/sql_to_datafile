require 'rubygems'
require 'sqlite3'

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

  def process
    aux_option = remove_unwanted_chars(@_option)

    # unprocessed option list
    option_list = aux_option.split(%r{\*/|\];})

    option_list.each do |op|
      if op.to_s.index('=') != nil

        ntec_option = NtecOption.new
        ntec_option.options = []

        # get option name
        ntec_option.name = op[0..op.index('=')-1].strip

        # get unprocessed option
        unprocessed_option = op[op.index('=')+2..op.length]

        # process option
        if (unprocessed_option.index('],')) == nil
          ntec_option.options.push(unprocessed_option.strip) # return just one item...
        else
          # split option list [A], [b], [C]
          option_items =  unprocessed_option.split(%r{\],})

          option_items.each do |item|
            aux_item = item.strip

            if aux_item != ''
              # remove start [
              aux_item = aux_item[1..aux_item.length]

              # check if exists ] if so then remove it
              if aux_item.index(']') != nil
                aux_item = aux_item[0..aux_item.length-2]
              end

              ntec_option.options.push(aux_item)
              end
            end
        end

        @ntec_option_list.push(ntec_option)
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

  def remove_unwanted_chars(data)

    data = data.gsub("\r\n", ' ')
    data = data.gsub("\t", ' ')
    data = data.gsub("\n", ' ')

    data.strip
  end

end




db = SQLite3::Database.open 'configs.db'

# usar para correr queries
db.results_as_hash = true

schedule_interval = '30'

sql = ''
sql += ' select '
sql += '  p.name, '
sql += '  p.xml_folder_path, '
sql += '  f.title, '
sql += '  f.options '
sql += ' from '
sql += '  page p, '
sql += '  frame f '
sql += ' where p.id = f.id_page '
sql += ' and f.schedule_interval = ' + schedule_interval
sql += ' and f.is_active = 1 '
sql += ' limit 2 '

data = db.execute sql

data.each do |r|
  puts "#{r['name']} | #{r['xml_folder_path']} | #{r['title']}"

  options = NtecOptions.new(r['options'])
  puts options.get_first('conn')
  puts options.get_first('sql')
  puts options.get_first('xml_file')

end
