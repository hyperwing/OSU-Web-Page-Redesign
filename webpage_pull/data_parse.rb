# File created 10/10/2019 by Sharon Qiu
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
    json_file = File.open('webpage_pull/media_and_press.json', 'w') {|file| JSON.dump(information, file)}
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
            media_and_links[list_item.text] = hrefs_array
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
                
                # Strip Print from the item text
                if category.include? "Print"
                    media_and_links[list_item.text.gsub(/Print:[\n]*/,'')] = hrefs_array
                else
                    media_and_links[list_item.text.gsub(/[\|\n]*/,'')] = hrefs_array
                end
            end
        end
    end
    media_and_links
end

# Main orchestrator for caching
#===============================================================
agent = Mechanize.new
main_page = agent.get("https://web.cse.ohio-state.edu/~davis.1719/")

# Caches all media and press
returned = media_press_cache main_page
