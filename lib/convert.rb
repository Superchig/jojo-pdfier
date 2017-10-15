require "optparse"
require "fileutils"
require "pathname"
require_relative "mv_files_up"

# Converts individual volume, whether it's a zip file or a directory
# The part variable means the jojo part
def convert(volume, number, part = "sbr")
  tmp_imgs_dir = "tmp_imgs"
  ext = "jpg"
  init_dir = Dir.pwd
  pages_location = "#{Dir.home}/tmp/volume_#{number}"

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
      mv_files_up(dir_name)
    end

    extracted_dirs = Pathname.new(pages_location)
                       .children.select { |c| c.directory? }
                       .map { |p| p.to_s }
  end

  Dir.mkdir(tmp_imgs_dir) unless Dir.exist?(tmp_imgs_dir)

  imgs = `ls -v *.#{ext}`.split("\n")
  formatted_img_num = 0
  imgs.each do |img|
    img_dimensions = `identify #{img}`.split(" ")[2]

    # Jojolion colored img_dimensions == "1773x1400" or "1774x1400"
    # Steel Ball Run img_dimensions == "1520x1200"
    if img_dimensions == "1520x1200"
      `convert -crop 50%x100% +repage #{img} #{tmp_imgs_dir}/tmp_img.#{ext}`

      # Switches image order because manga is designed to be read right to left
      File.rename("#{tmp_imgs_dir}/tmp_img-1.#{ext}", "#{tmp_imgs_dir}/formatted_img-#{formatted_img_num}.#{ext}")
      File.rename("#{tmp_imgs_dir}/tmp_img-0.#{ext}", "#{tmp_imgs_dir}/formatted_img-#{formatted_img_num += 1}.#{ext}")
    else
      File.rename(img, "#{tmp_imgs_dir}/formatted_img-#{formatted_img_num}.#{ext}")
    end

    formatted_img_num += 1


    puts "Converted #{img}..."
  end

  formatted_imgs = Dir.glob("#{tmp_imgs_dir}/formatted_img-*")
                     .sort_by { |f| f.split("-").last.to_i }.join(" ")
  # formatted_imgs = `ls -v #{tmp_imgs_dir}/formatted_img-*`.split("\n").join(" ")

  puts "Converting JoJo volume..."
  `convert #{formatted_imgs} #{init_dir}/#{part}_volume_#{number}.pdf`
  # puts `ls -v #{tmp_imgs_dir}`
  unless $? == 0
    puts "Something went wrong with converting the formatted images to a pdf!"
    return 1
  end

  puts "JoJo volume converted."
  Dir.chdir(init_dir)
end
