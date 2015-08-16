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
  title.gsub!(/[|\\*"<>?]/, '')
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
  path = File.basename(File.realpath('.'))
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
  num_hash = correct_episode_numbers(num_hash)
  names = @mode == 'numbers' ? {} : get_names(File.basename(path))
  puts names
  name = File.basename(path)
  files.each do |file|
    extension = file.split('.').last
    number = num_hash[file].length < 2 ? "0#{num_hash[file]}" : num_hash[file]
    number = number.length < 3 && num_hash.size >= 100 ? "0#{number}" : number
    key = number.to_i.to_s rescue number
    if names[key]
      FileUtils.mv(file, "#{number} - #{names[key]}.#{extension}") unless File.exist?("#{number} - #{names[key]}.#{extension}") || number.start_with?("ignore")
    elsif @mode != 'titles only'
      FileUtils.mv(file, "#{name} #{number}.#{extension}") unless File.exist?("#{name} #{number}.#{extension}") || number.start_with?("ignore")
    end
  end
end

def correct_episode_numbers(num_hash)
  counts = Hash.new(0)
  num_hash.each_pair do |k, v|
    if v.class != Array
    elsif v.size == 0
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
    next if k.start_with?("ignore")
    if v > 1
      num_hash.each_pair do |k1, v1|
        duplicates << k1 if v1 == k
      end
    end
  end
  duplicates.each do |d|
    puts "Duplicate episode numbers. Please type the correct episode number/name for #{d}."
    num_hash[d] = gets.strip
  end
  return correct_episode_numbers(num_hash) unless duplicates.empty?
  return num_hash
end

def get_numbers(file)
  parts = file.split(/[._'"\[\]\{\} -]/)
  nums = []
  parts.each do |s|
    nums << s if s.to_i != 0 || s == "0"
  end
end

def input_loop
  puts "Type directory name or command"
  loop do
    FileUtils.cd(@path)
    print " #{File.basename(File.realpath('.'))} > "
    input = gets.strip
    break if input.downcase == 'quit' || input.downcase == 'exit'
    if input.start_with?("cd ")
      path = input[3, input.size - 3]
      if Dir.exist?(path)
        @path = File.realpath(path)
      else
        puts "#{path} doesn't exist!"
      end
    elsif input == 'ls'
      puts Dir['*'].sort
    elsif input.start_with?("mv ")
      path = input[3, input.size - 3]
      if Dir.exist?(path)
        puts "Can't move directories."
      elsif File.exist?(path)
        puts "Where to move to?"
        path2 = gets.strip
        if File.exist?(path2)
          puts "A file with that name already exists! Aborting file move."
        else
          FileUtils.mv(path, path2)
        end
      else
        puts "#{path} doesn't exist!"
      end
    elsif input == 'numbers'
      @mode = 'numbers'
      puts "mode changed"
    elsif input == 'titles'
      @mode = 'titles'
      puts "mode changed"
    elsif input == 'titles only'
      @mode = 'titles only'
      puts "mode changed"
    elsif Dir.exist?(input)
      rename_folder(input)
    else
      puts "Folder not found"
    end
  end
end

if File.exist?("input.txt")
  paths = File.open('input.txt') do |file|
    file.readlines
  end
else
  paths = ['/']
end
@path = paths[0] || "/"
@path << "/" unless @path.end_with? "/"
@path = "/" unless Dir.exist?(@path)

@mode = "titles"

input_loop

