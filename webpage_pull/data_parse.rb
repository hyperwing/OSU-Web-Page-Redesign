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
    json_file = File.open('../source/data/media_and_press.json', 'w') {|file| JSON.dump(information, file)}
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
        publish_information[info[0]] = info[1..].concat [href_links]
    end

     # Saves as json 
     json_file = File.open('../source/data/publications.json', 'w') {|file| JSON.dump(publish_information, file)}
     json_file.close

     publish_information
end

# Created 10/10/2019 by Sri Ramya Dandu
# Edited 10/11/2019 by Sri Ramya Dandu: Changed incorrect dates
# All dates of publications
def getDates
    ["Soon", "OCT 2019", "OCT 2019", "FEB 2019", "OCT 2018", "SEP 2017", "2015", "SEP 2014", "AUG 2014",
            "JUN 2014", "2013", "NOV 2012","NOV 2012", "2012", "2011","2011", "JUN 2011", "JUN 2011",
            "JAN 2011", "NOV 2010", "NOV 2010","NOV 2010","NOV 2010","AUG 2010","AUG 2010", "2010",
            "OCT 2009", 'JUL 2009', 'FEB 2009', 'DEC 2008','SEP 2008', 'JUN 2008', 'JUN 2008','JAN 2008',
            'JAN 2008', 'JAN 2008', 'OCT 2007', 'JUN 2007', 'JUN 2007', '2007','2007', 'FEB 2007','FEB 2007',
            'FEB 2007', '2007', '2007', 'OCT 2006', 'OCT 2006', '2006', 'JUN 2006', 'JUN 2006', 'MAY 2006', '2006',
            'SEP 2005', 'SEP 2005', 'JUN 2005', 'JAN 2005', '2004', 'AUG 2004', 'JUL 2004', 'JUL 2004', 'JUN 2004',
            '2004','2003', 'OCT 2003', 'JUL 2003', 'DEC 2002', '2002', 'AUG 2002', 'JUL 2002', '2001', 'NOV 2001',
            'OCT 2001', 'JUL 2001', 'JUN 2001', '2000','DEC 2000', 'JUN 2000', 'NOV 2000','1999', 'MAY 1999', 'SEP 1999',
            'MAR 1999', '1998', 'NOV 1998', 'APR 1998', 'MAR 1998', 'OCT 1997', 'JUN 1997', 'JUN 1997','1997', '1996',
            'AUG 1996', '1994', '1994', 'OCT 1994']

end

# Main orchestrator for caching
#===============================================================
agent = Mechanize.new
main_page = agent.get("https://web.cse.ohio-state.edu/~davis.1719/")

# Caches all media and press
returned = media_press_cache main_page
publication_page main_page
