require 'fileutils'
require 'open-uri'

def get_names(series_name)
  search_page = open("http://www.animenewsnetwork.com/encyclopedia/search/name?q=#{sanitize(series_name)}")
  search_text = search_page.read
  pages = []
  index = 0
  url_part = "/encyclopedia/anime.php?id="
  while index < search_text.size
    index = search_text.index(url_part, index)
    break unless index
    id = search_text[index + url_part.size, 7].split('"')[0]
    index = search_text.index(">", index) + 1
    stop_index = search_text.index("</a>", index)
    name = search_text[index, stop_index - index]
    break unless name
    name.gsub!(/<..?>/, "")
    pages << [id, name]
  end
  if pages.size == 1
    id = pages[0][0]
  else
    id = pages[get_user_search_input(series_name, pages)][0]
  end
  file = open("http://www.animenewsnetwork.com/encyclopedia/anime.php?id=#{id}&page=25")
  text = file.read
  index = 0
  names = {}
  while index < text.size
    index = text.index("<td class=\"n\">", index)
    break unless index
    num = text[index + 14, 5].split('.')[0]
    if num.to_i == 0 && num != "0"
      index += 10
      next
    end
    index = text.index("<div>", index)
    name = text[index + 5, 200].split(/<[^ ]/)[0]
    if /Episode \d/.match(name)
      index = text.index("<div>", index + 5)
      name = text[index + 5, 200].split(/<[^ ]/)[0]
    end
    break if name.size == 0
    names[num] = sanitize_title(name) unless names[num]
  end
  names
end

def sanitize(name)
  name = name.gsub(/\W/, '+')
end

def sanitize_title(title)
  title = title.gsub(' / ', ' - ')
  title.gsub!('/', ' - ')
  title.gsub!(':', ' -')
  title.gsub!('&amp;', '&')
  title
end

def get_user_search_input(name, pages)
  puts "Search for #{name} found multiple anime:"
  pages.each_with_index do |p, i|
    break if i > 15
    puts "#{i + 1}. #{p[1]}"
  end
  puts "Please type the number of the choice you think is correct."
  tries = 0
  while tries < 5
    input = gets
    if input.to_i > 0 && input.to_i <= pages.size
      return input.to_i - 1
    else
      tries += 1
      puts "Error: please type a number"
    end
  end
  puts "Error: too many failed search attempts."
end

# puts get_names("Shirobako").inspect

def rename_folder(path)
  FileUtils.cd(path)
  files = Dir["*"]
  files = files.select{ |x| !Dir.exist?(x) }
  num_hash = {}
  files.each do |file|
    parts = file.split(/[._'"\[\]\{\} -]/)
    nums = []
    parts.each do |s|
      nums << s.to_i.to_s if s.to_i != 0 || s == "0"
    end
    num_hash[file] = nums.uniq
  end
  num_hash, errors = correct_episode_numbers(num_hash)
  if errors.empty?
    names = @mode == 'numbers' ? {} : get_names(File.basename(path))
    puts names
    name = File.basename(path)
    files.each do |file|
      extension = file.split('.').last
      number = num_hash[file].length < 2 ? "0#{num_hash[file]}" : num_hash[file]
      number = number.length < 3 && num_hash.size >= 100 ? "0#{number}" : number
      key = number.to_i.to_s rescue number
      if names[key]
        FileUtils.mv(file, "#{number} - #{names[key]}.#{extension}") unless file == "#{number} - #{names[key]}.#{extension}" || number.start_with?("ignore")
      elsif @mode != 'names only'
        FileUtils.mv(file, "#{name} #{number}.#{extension}") unless file == "#{name} #{number}.#{extension}" || number.start_with?("ignore")
      end
    end
  else
    puts "Error renaming files in \"#{path}\""
    puts errors.first
  end
end

def correct_episode_numbers(num_hash)
  counts = Hash.new(0)
  errors = []
  num_hash.each_pair do |k, v|
    if v.size == 0
      puts "Missing episode number in \"#{k}\". Please enter the episode number."
      input = gets.strip
      num_hash[k] = input
    elsif v.size > 1
      puts "Too many numbers in \"#{k}\". Please enter the episode number."
      input = gets.strip
      num_hash[k] = input
    else
      num_hash[k] = v.first
    end
    counts[num_hash[k]] += 1
  end
  duplicates = []
  counts.each_pair do |k, v|
    if v > 1
      num_hash.each_pair do |k1, v1|
        duplicates << k1 if v1 == k
      end
    end
  end
  duplicates.each do |d|
    puts "Duplicate episode numbers. Please type the correct episode number/name for #{d}."
    num_hash[d] = gets.delete("\n")
  end
  #errors << "Duplicate episode numbers." if num_hash.values.uniq.size != num_hash.values.size
  return num_hash, errors
end

def get_numbers(file)
  parts = file.split(/[._'"\[\]\{\} -]/)
  nums = []
  parts.each do |s|
    nums << s if s.to_i != 0 || s == "0"
  end
end

paths = File.open('input.txt') do |file|
  file.readlines
end
path = paths[0]
path << "/" unless path.end_with? "/"

# paths.each do |p|
#   paths2 = Dir["#{p}*"]
#   paths2.each do |p2|
#     next unless Dir.exist?(p2)
#     puts "Folder: #{p2}. Rename files in this folder? (y/n)"
#     input = gets
#     if (input.downcase.start_with?("y"))
#       rename_folder(p2)
#     else
#       next
#     end
#   end
# end

@mode = "names"

puts "Type folder name or command"
while folder = gets.strip
  break if folder.downcase == 'quit' || folder.downcase == 'exit'
  if folder == 'numbers'
    @mode = 'numbers'
    puts "mode changed"
  elsif folder == 'names'
    @mode = 'names'
    puts "mode changed"
  elsif folder == 'names only'
    @mode = 'names only'
    puts "mode changed"
  elsif Dir.exist?("#{path}#{folder}/")
    rename_folder("#{path}#{folder}/")
  else
    puts "Folder not found"
  end
  puts "Type folder name or command"
end


