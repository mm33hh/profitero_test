require 'curb'
require 'nokogiri'
require 'csv'

if ARGV[0] == nil or ARGV[1] == nil 
	abort("[!] Link and output path required! Link goes first, output file - second! It's important!")
end

if  ARGV[1].split('.')[1] != 'csv'
	abort("[!] Output file must be .csv")
end

#We need '/' at the end of the argument, so lets check
if ARGV[0].split('').last != '/' 
	link = "#{ARGV[0]}/"
else 
	link = ARGV[0]
end

if ARGV[0].include?("nuevos-productos")
	link = ARGV[0]
end
#To hide our activity lets fake user-agents and use proxy to hide ip
if ARGV.include?('--proxy')
	proxy = File.readlines('./proxy.txt')
else
	proxy = []
end

if ARGV.include?('--verbose')
	ver = true
else
	ver = false
end

out  = ARGV[1]

#Get fake User-Agents
agents = File.readlines('./user-agents.txt')

html = Curl.get(link) do |c|
	c.proxy_url = proxy.sample
	c.headers['User-Agent'] = agents.sample.strip
	c.verbose = ver
end

parsed_data = Nokogiri::HTML.parse(html.body)

#Let's see how many pages we need to parse

tags = parsed_data.xpath('//*[contains(@class, "pagination clearfix li_fl")]/li')
pages = []
tags.each do |x|
	if x.inner_html.include?("?p=")
		pages << x.inner_html.split('"')[1].split("=")[1].to_i
	end
end
#Parse each page 
if pages.max != nil
	max_page = pages.max
else 
	max_page = 1
end
puts "[i] Found #{max_page} pages of products. Let's begin..."
urls = []
[*1..max_page].each do |x|
	if link.include?("nuevos-productos")
		#All links (does not matter if it has several pages or not) can get /?p= parameter, but Novedades returns 404 error
		curl = Curl.get("#{link}") do |c|
			c.proxy_url = proxy.sample
			c.headers['User-Agent'] = agents.sample.strip
			c.verbose = ver
		end
	else
		curl = Curl.get("#{link}?p=#{x}") do |c|
			c.proxy_url = proxy.sample
			c.headers['User-Agent'] = agents.sample.strip
			c.verbose = ver
		end
	end
	data = Nokogiri::HTML.parse(curl.body)
	#We need to get all the products from each page
	links = data.xpath("//*[contains(@class, 'product_img_link product-list-category-img')]/@href")
	links.each{|e| urls << e}
end
errors = []
arr = []
puts "[i] We got #{urls.count} URLS to parse..."
print "Go! "
urls.each do |x|
	curl = Curl.get(x) do |c|
		c.proxy_url = proxy.sample
		c.headers['User-Agent'] = agents.sample.strip
		c.verbose = ver
	end
	data = Nokogiri::HTML.parse(curl.body)
	name = data.xpath("//*[contains(@class, 'product_main_name')]").first.text
	img = data.xpath("//img[@id='bigpic']/@src").to_s
	weight = data.xpath("//span[@class='radio_label']")
	price = data.xpath("//span[@class='price_comb']")
	if not weight.text.empty? && price.text.empty?
		weight.to_a.each_index do |i|
			prod = {}
			prod[:name] = name.strip.gsub('"')
			prod[:img] = img
			prod[:weight] = weight[i].text
			prod[:price] = price[i].text.to_f
			print "="
			arr << prod
		end
	else
		errors << curl.url
	end
	
end
print "> DONE!\n"
puts "Parsed Links: #{urls.count} | Products: #{arr.uniq.count} | Errors: #{errors.count}"
new_arr = []
if errors.count > 0
	puts "Errors:"
	puts errors
	puts "Check it manually for more info..."
	puts "Trying another method for bad URLs..."
	counter = 0
	errors.each do |x|
		prod = {}
		curl = Curl.get(x) do |c|
			c.proxy_url = proxy.sample
			c.headers['User-Agent'] = agents.sample.strip
			c.verbose = ver
		end
		data = Nokogiri::HTML.parse(curl.body)
		name = data.xpath("//*[contains(@class, 'product_main_name')]").first.text
		img = data.xpath("//img[@id='bigpic']/@src").to_s
		price = data.xpath("//*[contains(@class,'our_price_display fl')]").text
		if not price.empty?
			prod[:name] = name.strip.gsub('"')
			prod[:img] = img
			prod[:price] = price.to_f
			prod[:weight] = "none"
			new_arr << prod
			counter += 1
		end
	end
	if errors.count == counter
		puts "Nice...we got them all"
	else 
		puts "Still got some errors..."
		puts errors.pop(counter - errors.count)
		puts "Check them manually..."
	end

end
puts "Writing output to #{out}"
all_info = (arr << new_arr).flatten!
CSV.open("#{out}", 'w') do |c|
		 c << ['Name','Price','Image']
		all_info.each do |x|
			if x[:weight] != 'none'
				c << ["#{x[:name]} - #{x[:weight]}", x[:price], x[:img]]
			else
				c << [x[:name], x[:price], x[:img]]
			end
		end
end
