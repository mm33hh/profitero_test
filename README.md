## Test task. Web scraper with random User-Agent header and random proxy.
```ruby 
ruby profitero.rb <url> <output file> --proxy --verbose
```

To use with proxy put list of your proxies to proxy.txt if you don't want to, just don't pass the argument. "--verbose" argument switches curb gem to verbose mode. You can parse any category and any sub-category from the provided website.

As I noticed some of the product pages are not coded as the vast majority of product pages on the website, so if script catches any errors while parsing, it checks it for both page styles. As well we can parse https://www.petsonic.com/nuevos-productos (New Products)...that was a little bit tricky

Some videos:
https://youtu.be/6dM0hnaDFZA
https://youtu.be/ybwhpVz60yE
