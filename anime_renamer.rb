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
    break if name.size == 0
    names[num] = sanitize_title(name)
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
  num_hash = {}
  files.each do |file|
    parts = file.split(/[._'"\[\]\{\} -]/)
    nums = []
    parts.each do |s|
      nums << s if s.to_i != 0 || s == "0"
    end
    num_hash[file] = nums
  end
  num_hash, errors = correct_episode_numbers(num_hash)
  if errors.empty?
    names = get_names(File.basename(path))
    puts names
    name = File.basename(path)
    files.each do |file|
      extension = file.split('.').last
      number = num_hash[file][0].length < 2 ? "0#{num_hash[file][0]}" : num_hash[file][0]
      key = number.to_i.to_s rescue number
      if names[key]
        FileUtils.mv(file, "#{number} - #{names[key]}.#{extension}") unless file == "#{number} - #{names[key]}.#{extension}" || number.start_with?("ignore")
      else
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
    next if v.size == 1
    if v.size == 0
      puts "Missing episode number in \"#{k}\". Please enter the episode number."
      input = gets.strip
      v << input
    end
    if v.size > 2
      puts "Too many numbers in \"#{k}\". Please enter the episode number."
      input = gets.strip
      v << input
    end
    if v.size == 2
      if k.include? "#{v[0]}.#{v[1]}"
        v.replace(["#{v[0]}.#{v[1]}"])
      elsif k.include? "#{v[0]}-#{v[1]}"
        v.replace(["#{v[0]}-#{v[1]}"])
      else
        v.each do |x|
          counts[x] += 1
        end
      end
    end
  end
  common = -1
  count = 1
  counts.each_pair do |k, v|
    if v > 1 && count > 1 && k != common
      errors << "Episode number #{k} appears multiple times."
    end
    if v > count
      common = k
      count = v
    end
  end
  if count > 1
    num_hash.each_pair do |k, v|
      v2 = v.uniq
      v.delete(common)
      v.replace(v2) if v.empty?
      errors << "Episode numbering error type 1." if v.size != 1
    end
  end
  errors << "Duplicate episode numbers." if num_hash.values.uniq.size != num_hash.values.size
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

paths.each do |p|
  paths2 = Dir["#{p}*"]
  paths2.each do |p2|
    next unless Dir.exist?(p2)
    puts "Folder: #{p2}. Rename files in this folder? (y/n)"
    input = gets
    if (input.downcase.start_with?("y"))
      rename_folder(p2)
    else
      next
    end
  end
end

# paths.each do |p|
#   rename_folder(p)
# end


