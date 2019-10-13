# File created 10/10/2019 by Sharon Qiu
# Edited 10/10/2019 by Sri Ramya Dandu
# Edited 10/11/2019 by Sri Ramya Dandu
# Caches pages as well as necessary information on page.

require 'json'
require 'mechanize'

# Created 10/10/2019 by Sharon Qiu
# Caches media and press info in a json object
# Hashmap cached contains:
#   Key = type –media, print, or tv etc– (str)
#   value = hashmap of whatever media was found
def media_press_cache(page)
    information = Hash.new
    media_press = page.css('li')
    media_press.each do |current_list|
        categories = current_list.css('b')
        categories.each do |bolded| # Checks if it's the correct category
            if bolded.text == "TV/Video" || bolded.text == "Radio"
                information[bolded.text] = hash_lists_media_press(bolded.text, current_list)
            elsif bolded.text == "Print" #print UL has extra li end tags, so parsed uniquely
                current_list = current_list.parent
                information[bolded.text] = hash_lists_media_press(bolded.text, current_list)
            end
        end
    end

    # Saves as json 
    json_file = File.open('media_and_press.json', 'w') {|file| JSON.dump(information, file)}
    json_file.close
end

# Created 10/10/2019 by Sharon Qiu
# Hashes list given
# Assumes media or press info
# returns a hashmap with:
#   Key = name of article/media (str)
#   value = link(s) in an array
def hash_lists_media_press(type, current_list)
    media_and_links = Hash.new
    print_found = false # Handling for print

    # Parse through each list item for links and name of media
    if type == "TV/Video" || type == "Radio"
        current_list.css('li').each do |list_item|
            hrefs_array = Array.new
            href_exists = list_item.css('a') # Check if an href exists
            if href_exists != nil
                href_exists.each {|href| hrefs_array.push ("https://web.cse.ohio-state.edu/~davis.1719/" + href["href"])} # Add's all href's to array
            end
            media_and_links[list_item.to_html.to_s.gsub(/[\n]*/,'')] = hrefs_array
        end
    else # If it's print
        current_list.css('li').each do |list_item|
            # To find when to start concatenating links
            category = list_item.css('b').text
            print_found = true if category.include? "Print"

            # Concatenate print items
            if print_found
                hrefs_array = Array.new
                href_exists = list_item.css('a') # Check if an href exists
                if href_exists != nil
                    href_exists.each {|href| hrefs_array.push ("https://web.cse.ohio-state.edu/~davis.1719/" + href["href"])} # Add's all href's to array
                end
                media_and_links[list_item.to_html.to_s.gsub(/[\n]*/,'')] = hrefs_array
                
            end
        end
    end
    media_and_links
end

# Created 10/10/2019 by Sri Ramya Dandu
# Edited 10/11/2019 by Sri Ramya Dandu: Handles the exception cases and duplicate titles 
# Scrapes the publication page and returns a hash 
# Key: title
# Value: array of info
def publication_page (page)


    publish_information = Hash.new {|h,k| h[k] = []}
    publication_link = page.link_with(href: /publications.html/).click

    publication_link.css('li').each do |item|
        href_links = []
        # Removes indescriptive title of links 
        info = item.text.gsub(/PDF,/,'').gsub(/\[|PDF|HTML|\]/,'').strip.split "\n"

        # handles 3 cases where html set up does not align
        if (info[1] == 'Bumping LDA"' || info[1] == 'Kalman Filters"')
            info[0] += ' ' + info[1]
            info.delete info[1]
        elsif info[1].include?'with Applications to 3D Tracking"' 
            title_substr = info[1].split('"').first
            info[0] += ' ' + title_substr
            info[1] = info[1].split('"').last
        end
        info[0] = info[0].gsub /"/, ''

         # Check if an href exists
        href_exists = item.css('a')
        if href_exists != nil
            href_exists.each do |href| 
                link = href["href"]
                if !link.start_with? "http"
                    href_links << ("https://web.cse.ohio-state.edu/~davis.1719/" + link)
                else 
                    # Add's links to non-osu websites
                    href_links << link
                end
            end
        end
        
        # Diferentiate duplicate titles with space at the end 
        info[0] += ' ' if publish_information.has_key? info[0]

        # Organize the array such that the last element is always an array of links
        # Key of hash is title 
        publish_information[info[0]] = info[1..-1].concat [href_links]
    end

     # Saves as json 
     json_file = File.open('../source/data/publications.json', 'w') {|file| JSON.dump(publish_information, file)}
     json_file.close

     publish_information
end

# Main orchestrator for caching
#===============================================================
agent = Mechanize.new
main_page = agent.get("https://web.cse.ohio-state.edu/~davis.1719/")

# Caches all media and press
media_press_cache main_page
#publication_page main_page
