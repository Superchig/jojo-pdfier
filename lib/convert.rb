def convert(volume)
  TMP_IMGS_DIR = "tmp_imgs"
  EXT = "jpg"
  init_dir = Dir.pwd
  pages_location = "#{Dir.home}/tmp/volume_#{options[:volume_number]}"

  if File.extname(volume) == ".zip"
    `unzip -d #{pages_location} "#{ARGV[0]}"`
    puts "Unzipped #{ARGV[0]}"
    Dir.chdir(pages_location)
    puts Dir.pwd
    FileUtils.remove_dir("__MACOSX") if Dir.exist?("__MACOSX")
  elsif File.directory?(volume)
    Dir.chdir(volume)
  else
    $stderr.puts "Image jpgs must be in a directory or zip file."
    exit(1)
  end

  extracted_dirs = Pathname.new(pages_location)
                     .children.select { |c| c.directory? }
                     .map { |p| p.to_s }
  until extracted_dirs.empty?
    extracted_dirs.each do |dir_name|
      Dir.foreach(dir_name) do |item|
        next if item == "." || item == ".."

        FileUtils.mv("#{dir_name}/#{item}", ".")
      end
      puts "Moved files out of #{dir_name}."

      Dir.rmdir(dir_name)
      puts "Deleted empty #{dir_name}."
    end

    extracted_dirs = Pathname.new(pages_location)
                       .children.select { |c| c.directory? }
                       .map { |p| p.to_s }
  end

  Dir.mkdir(TMP_IMGS_DIR) unless Dir.exist?(TMP_IMGS_DIR)

  imgs = `ls -v *.#{EXT}`.split("\n")
  formatted_img_num = 0
  imgs.each do |img|
    img_dimensions = `identify #{img}`.split(" ")[2]

    # Jojolion colored img_dimensions == "1773x1400" or "1774x1400"
    # Steel Ball Run img_dimensions == "1520x1200"
    if img_dimensions == "1520x1200"
      `convert -crop 50%x100% +repage #{img} #{TMP_IMGS_DIR}/tmp_img.#{EXT}`

      # Switches image order because manga is designed to be read right to left
      File.rename("#{TMP_IMGS_DIR}/tmp_img-1.#{EXT}", "#{TMP_IMGS_DIR}/formatted_img-#{formatted_img_num}.#{EXT}")
      File.rename("#{TMP_IMGS_DIR}/tmp_img-0.#{EXT}", "#{TMP_IMGS_DIR}/formatted_img-#{formatted_img_num += 1}.#{EXT}")
    else
      File.rename(img, "#{TMP_IMGS_DIR}/formatted_img-#{formatted_img_num}.#{EXT}")
    end

    formatted_img_num += 1


    puts "Converted #{img}..."
  end

  formatted_imgs = Dir.glob("#{TMP_IMGS_DIR}/formatted_img-*")
                     .sort_by { |f| f.split("-").last.to_i }.join(" ")
  # formatted_imgs = `ls -v #{TMP_IMGS_DIR}/formatted_img-*`.split("\n").join(" ")

  puts "Converting JoJo volume..."
  `convert #{formatted_imgs} #{init_dir}/#{options[:output_file]}_volume_#{options[:volume_number]}.pdf`
  # puts `ls -v #{TMP_IMGS_DIR}`
  unless $? == 0
    puts "Something went wrong with converting the formatted images to a pdf!"
    return 1
  end

  puts "JoJo volume converted."
  Dir.chdir(init_dir)
end