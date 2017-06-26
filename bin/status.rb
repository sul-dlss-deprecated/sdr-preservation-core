class Status

  def report_context
    environment = ENV['ROBOT_ENVIRONMENT'].capitalize
    context = "\n#{environment} Status on #{`hostname -s`.chomp} as of #{Time.now.strftime('%Y-%m-%d')}\n"
    context
  end

  def environment_suffix
    case ENV['ROBOT_ENVIRONMENT'].upcase
      when 'PRODUCTION'
        '-prod'
      when 'TEST'
        '-test'
      when 'DEVELOPMENT'
        '-dev'
    end
  end

  def sprintf_directive(value,column)
    case value
      when String,Symbol
        "%#{column}s"
      when Integer
        "%#{column}d"
      when Float
        "%#{column}.0f"
    end
  end

  def report_table(title,headers,body,columns)
    width = columns.inject(0){|sum,x| sum + x.abs } + (columns.size - 1)*2
    s = "\n#{Time.now.strftime('%H:%M')} - #{title}\n"
    s << "#{'='*width}\n"
    header_fmt = (0...columns.length).to_a.map{|i| sprintf_directive(headers[i],columns[i])}.join('  ')
    s << (sprintf "#{header_fmt}\n", *headers)
    dash_format = columns.map{|column| "%#{column}s"}.join('  ')
    dash_values = columns.map{|column| '-'*column.abs}
    s << (sprintf "#{dash_format}\n", *dash_values)
    body.each do |row|
      row_format = (0...columns.length).to_a.map{|i| sprintf_directive(row[i],columns[i])}.join('  ')
      #puts row_format
      #puts row.inspect
      s << (sprintf "#{row_format}\n", *row)
    end
    s << "#{'-'*width}\n"
    s
  end

end

