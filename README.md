## Test task. Web scraper with random User-Agent header and random proxy.
```ruby 
ruby profitero.rb <url> <output file> --proxy --verbose
```

To use with proxy put list of your proxies to proxy.txt if you don't want to, just don't pass the "--proxy" argument. "--verbose" argument switches curb gem to verbose mode. You can parse any category and any sub-category from the provided website.

As I noticed some of the product pages are not coded as the vast majority of product pages on the website, so if script catches any errors while parsing, it checks it for both page styles. As well we can parse https://www.petsonic.com/nuevos-productos (New Products)...that was a little bit tricky

```
$ ruby profitero.rb https://www.petsonic.com/snacks-huesos-para-perros/ snacks-huesos-para-perros.csv
[i] Found 11 pages of products. Let's begin...
[i] We got 241 URLS to parse...
Go! ===============================================================================================================================
===============================================================================================================================
===============================================================================> DONE!
Parsed Links: 241 | Products: 333 | Errors: 2
Errors:
https://www.petsonic.com/nayeco-35-und-nervio-bovino-para-perros.html
https://www.petsonic.com/hobbit-alf-barritas-1kg-redonda-antisarro-fluor-para-perros.html
Check it manually for more info...
Trying another method for bad URLs...
Nice...we got them all
Writing output to snacks-huesos-para-perros.csv
```
Made without any special dependencies!<br />
To do: <br />
- Make it async and faster
- Make it possible to provide more links to parse 
- Output file versioning not to override existing data
- Make it more "stealth" with random referer header (dig deeper to find out what requests accepts this shop)
- Make better looking using tty gem 

