def mass_convert(number, part = "sbr", max_number)
  Dir["Volume *.zip"].each do |zip|
    puts zip

    zip_number = zip[/\d+/].to_i
    # puts zip_number

    if (number..max_number).include?(zip_number)
      convert(zip, zip_number, part)
    end
  end
end
