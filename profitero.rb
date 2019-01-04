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

out  = ARGV[1]

html = Curl.get(link)

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
		curl = Curl.get("#{link}")
	else
		curl = Curl.get("#{link}?p=#{x}")
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
	prod = {}
	#threads << Thread.new{
	curl = Curl.get(x)
	data = Nokogiri::HTML.parse(curl.body)
	name = data.xpath("//*[contains(@class, 'product_main_name')]").first.text
	img = data.xpath("//img[@id='bigpic']/@src").to_s
	weight = data.xpath("//span[@class='radio_label']")
	price = data.xpath("//span[@class='price_comb']")
	weight.to_a.each_index do |i|
		if not name.strip == '' or weight[i].text.strip == '' or price[i].text.strip == ''
			prod[:name] = name.strip
			prod[:img] = img
			prod[:weight] = weight[i].text
			prod[:price] = price[i].text.to_f
			print "="
		end
	end
	if prod == {}
		errors << curl.url
	else
		arr << prod
	end
end
print "> DONE!\n"
puts "Parsed: #{urls.count} | Success: #{arr.uniq.count} | Errors: #{errors.count}"
new_arr = []
if errors.count > 0
	puts "Errors:"
	puts errors
	puts "Check it manually for more info..."
	puts "Trying another method for bad URLs..."
	counter = 0
	errors.each do |x|
		prod = {}
		curl = Curl.get(x)
		data = Nokogiri::HTML.parse(curl.body)
		name = data.xpath("//*[contains(@class, 'product_main_name')]").first.text
		img = data.xpath("//img[@id='bigpic']/@src").to_s
		price = data.xpath("//*[contains(@class,'our_price_display fl')]").text
		if not name.strip == '' or price[i].text.strip == ''
			prod[:name] = name.strip
			prod[:img] = img
			prod[:price] = price.to_f
			prod[:weight] = "none"
			#puts prod
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
puts "The End"
