require 'rubygems'

class LoggingData
  attr_accessor :page, :frame, :output

  def initialize(page, frame)
    @page = page
    @frame = frame
  end

end

class LogMe
  attr_accessor :logging_data, :starttime

  def initialize
    @logging_data = []
    @starttime = Time.now().strftime('%H:%M:%S')
  end

  def add_item(page, frame)
    @logging_data.push(LoggingData.new(page, frame))

    return @logging_data.length-1
  end

  def add_output_msg_by_index(index, msg)
    if index < @logging_data.length
      @logging_data[index].output = msg
    end
  end

  def add_output_msg_by_name(page, frame, msg)
    index = @logging_data.index{|data| data.page == page && data.frame == frame}

    if index != nil
      @logging_data[index].output = msg
    end
  end

  def show_report
    system 'clear' unless system 'cls'
    puts 'start time: '  + @starttime

    @logging_data.each do |data|
      puts " #{data.page} == #{data.frame} ==> #{data.output} "
    end
  end
end
