def mv_files_up(dir_name)
  Dir.foreach(dir_name) do |item|
    next if item == "." || item == ".."

    FileUtils.mv("#{dir_name}/#{item}", ".")
  end
  puts "Moved files out of #{dir_name}."

  Dir.rmdir(dir_name)
  puts "Deleted empty #{dir_name}."
end
