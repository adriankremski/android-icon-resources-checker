require 'fastimage'

$target_dir = Dir.pwd
$path = ARGV[0] == nil ? '.' : ARGV[0]
Dir.chdir $path 

class Resource
  @@dirs = ["drawable-mdpi", "drawable-hdpi", "drawable-xhdpi", "drawable-xxhdpi", "drawable-xxxhdpi"]
  @@size_multipliers = {@@dirs[0]=>1, @@dirs[1]=>1.5, @@dirs[2]=>2, @@dirs[3]=>3, @@dirs[4]=>4}

  attr_accessor :bucket_resources, :name, :mdpi_size, :full_path
  
  def initialize(name, full_path)
    @name = name
    @full_path = full_path
    @bucket_resources = {}
  end

  def is_bucket_resource_width_valid(bucket_name, width)
    init_mdpi_size if @mdpi_size.nil?
    return false if @mdpi_size.nil?
    width == @mdpi_size[0] * @@size_multipliers[bucket_name]
  end

  def get_multiplied_width(bucket_name)
    init_mdpi_size if @mdpi_size.nil?
    return -1 if @mdpi_size.nil?
    @mdpi_size[0] * @@size_multipliers[bucket_name]
  end

  def get_multiplied_height(bucket_name)
    init_mdpi_size if @mdpi_size.nil?
    return -1 if @mdpi_size.nil?
    @mdpi_size[1] * @@size_multipliers[bucket_name]
  end

  def is_bucket_resource_height_valid(bucket_name, height)
    init_mdpi_size if @mdpi_size.nil?
    return false if @mdpi_size.nil?
    height == @mdpi_size[1] * @@size_multipliers[bucket_name]
  end
  
  def self.drawable_directories
    @@dirs
  end

  private

  def init_mdpi_size 
    @mdpi_size = FastImage.size("#{$path}/#{@@dirs[0]}/#{@name}")
  end
end

class BucketResource
  attr_accessor :name
  
  def initialize(name)
    @name = name
  end
end

def get_directories
  directories = []
  Dir.foreach($path) do |entry|
    next if (entry == '..' || entry == '.' || !(/drawable-.*/ =~ entry))
    directories << entry if File.directory?(entry)
  end
  directories
end

def get_resources_from_directories(directories) 
  resources = {}
  directories.each do |directory|
    Dir.foreach(directory) do |entry|
      next if (entry == '..' || entry == '.' || File.directory?(entry) || !(/.*png/ =~ entry) || /.*\.9\.png/ =~ entry)
      full_path = "#{Dir.pwd}/#{directory}/#{entry}"
      resources[entry] = Resource.new(entry, full_path) if resources[entry].nil?
      resources[entry].bucket_resources[directory] = BucketResource.new(directory)
    end
  end
  resources
end

def generate_www_content(resources)
  webpageContent = ""
  resources.keys.each do |key|
    resource = resources[key]
    webpageContent += "<h1>#{resource.name}<h1>"
    webpageContent += "<table>"
    webpageContent += put_inside_tags("<tr>", generate_images_www_content(resource), "</tr>")
    webpageContent += put_inside_tags("<tr>", generate_directories_www_content, "</tr>")
    webpageContent += put_inside_tags("<tr>", generate_sizes_www_content(resource), "</tr>")
    webpageContent += "</table>"
  end
  webpageContent
end

def put_inside_tags(openingTag, content, closingTag)
  "#{openingTag}#{content}#{closingTag}"
end

def generate_images_www_content(resource)
  imagesContent = ""
  Resource.drawable_directories.each do |drawable_dir|
    if has_bucket_resource(resource, drawable_dir)
      imagesContent += put_inside_tags("<td>", "<img src='#{resource.full_path}'/>", "</td>")
    else
      imagesContent += put_inside_tags("<td>", "<img src=''/>", "</td>")
    end
  end
  imagesContent
end

def has_bucket_resource(resource, drawable_dir)
  !resource.bucket_resources[drawable_dir].nil?
end

def generate_sizes_www_content(resource)
  sizesContent = ""
  Resource.drawable_directories.each do |drawable_dir|
    sizesContent += put_inside_tags("<td>", generate_bucket_resource_size_www_content(resource, drawable_dir), "</td>")
  end
  sizesContent
end

def generate_bucket_resource_size_www_content(resource, drawable_dir)
  size = FastImage.size("#{$path}/#{drawable_dir}/#{resource.name}")
  if has_bucket_resource(resource, drawable_dir)
    if is_size_valid(resource, drawable_dir, size) then
      "<span class='goodSize'>#{size}</span>"
    else
      goodSize = "(#{resource.get_multiplied_width(drawable_dir)}),#{size[1]}(#{resource.get_multiplied_height(drawable_dir)})"
      "<span class='wrongSize'>#{size[0]}#{goodSize}</span>"
    end
  else
    goodSize = "0(#{resource.get_multiplied_width(drawable_dir)}),0(#{resource.get_multiplied_height(drawable_dir)})"
    "<span class='wrongSize'>[#{goodSize}]</span>"
  end
end

def is_size_valid(resource, drawable_dir, size)
  widthValid = resource.is_bucket_resource_width_valid(drawable_dir, size[0])
  heightValid  = resource.is_bucket_resource_height_valid(drawable_dir, size[1])
  widthValid && heightValid
end

def generate_directories_www_content
  directoriesContent = ""
  Resource.drawable_directories.each do |drawable_dir|
    directoriesContent += put_inside_tags("<td>", "#{drawable_dir}", "</td>")
  end
  directoriesContent
end

def save_results_to_file(results)
  wwwCode = "<!DOCTYPE html>
          <html lang=\"en\">
            <head>
              <link rel=\"stylesheet\" type=\"text/css\" href=\"mystyle.css\">
              <meta charset=\"utf-8\">
            </head>
            <body role=\"document\">
              #{results}
            </body>
          </html>"

  Dir.chdir $target_dir
  File.open("index.html", 'w') { |file| file.write(wwwCode) }
end

save_results_to_file(generate_www_content(get_resources_from_directories(get_directories)))

