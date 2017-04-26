require 'open-uri'
require 'nokogiri'
require 'csv'
#require 'rubyfish'
#require 'json'

COMPANIES_HASH_FILE_NAME = "companies_hash.txt"
URL = "http://www.indiainfoline.com/marketstatistics/index-movers/nse/nifty"
CSV_FILE_NAME = "baba_weights.csv"


def convert_current_hash_to_simple_text_file
	hash_correlate = {"TCS"=>"TCS", "O N G C"=>"ONGC", "Reliance Inds."=>"RELIANCE", "ITC"=>"ITC", "Infosys"=>"INFY", "St Bk of India"=>"SBIN", "HDFC Bank"=>"HDFCBANK", "Coal India"=>"COALINDIA", "ICICI Bank"=>"ICICIBANK", "H D F C"=>"HDFC", "Sun Pharma.Inds."=>"SUNPHARMA", "Hind. Unilever"=>"HINDUNILVR", "Tata Motors"=>"TATAMOTORS", "Bharti Airtel"=>"BHARTIARTL", "Larsen & Toubro"=>"LT", "Wipro"=>"WIPRO", "NTPC"=>"NTPC", "HCL Technologies"=>"HCLTECH", "Axis Bank"=>"AXISBANK", "Maruti Suzuki"=>"MARUTI", "Kotak Mah. Bank"=>"KOTAKBANK", "M & M"=>"M&M", "Bajaj Auto"=>"BAJAJ-AUTO", "Power Grid Corpn"=>"POWERGRID", "Asian Paints"=>"ASIANPAINT", "B H E L"=>"BHEL", "Sesa Sterlite"=>"SSLT", "UltraTech Cem."=>"ULTRACEMCO", "Lupin"=>"LUPIN", "Hero Motocorp"=>"HEROMOTOCO", "Tech Mahindra"=>"TECHM", "GAIL (India)"=>"GAIL", "Dr Reddy's Labs"=>"DRREDDY", "NMDC"=>"NMDC", "B P C L"=>"BPCL", "Cipla"=>"CIPLA", "Cairn India"=>"CAIRN", "Bank of Baroda"=>"BANKBARODA", "Tata Steel"=>"TATASTEEL", "IndusInd Bank"=>"INDUSINDBANK", "Punjab Natl.Bank"=>"PNB", "Zee Entertainmen"=>"ZEEL", "Hindalco Inds."=>"HINDALCO", "Ambuja Cem."=>"AMBUJACEM", "Grasim Inds"=>"GRASIM", "ACC"=>"ACC", "DLF"=>"DLF", "I D F C"=>"IDFC", "Tata Power Co."=>"TATAPOWER", "Jindal Steel"=>"JINDALSTEL", "Idea Cellular"=>"IDEA", "Yes Bank"=>"YESBANK", "Bosch" => "BOSCHLTD", "Vedanta" => "VEDL", "Adani Ports" => "ADANIPORTS"}

	array_of_lines = []
	hash_correlate.each do |key,value|

		array_of_lines.push(key.to_s + "," + value.to_s)

	end

	joined_lines = array_of_lines.join("\n")
	q = IO.write(COMPANIES_HASH_FILE_NAME,joined_lines)
	puts "finished conversion."
	return hash_correlate


end

def read_companies_hash

	hash_correlate = {}
	begin
		q = IO.read(COMPANIES_HASH_FILE_NAME)	
		lines = q.split(/\n/)
		lines.each do |line|
			name_symbol_array = line.split(/,/)
			hash_correlate[name_symbol_array[0].to_s] = name_symbol_array[1].to_s
		end
	rescue
		puts "\n FILE DOES NOT EXIST \n \n The file containing the companies names and symbols is not present on this computer. If you are running the program for the first time, press Y otherwise press N \n \n"
		a = gets.chomp
		if a.strip=~/Y/
			puts "press enter to build the file from whatever we had existing, but please check the generated file for correctness, after you press enter. name of file to check: \'companies_hash.txt\' it is in the same directory as the ruby program,"
			gets.chomp
			hash_correlate = convert_current_hash_to_simple_text_file
		elsif a.strip=~/N/
			puts "something has gone wrong, since the file should have been there, so we are exiting the program, call bucky, press enter to exit"
			gets.chomp
			exit
		else 
			puts "you entered something other than Y OR N , please rerun the program,
			 now exiting, press enter to exit."
			gets.chomp
			exit
		end
	end
	if hash_correlate.empty?
		puts "the file was there, but there was nothign in it, this box will close in 10 seconds, something went wrong,program will exit, call bucky, press enter to exit."
		gets.chomp
		exit
	end


	return hash_correlate

end



hash_correlate = read_companies_hash

url = URL

hash_of_weightages = {}

j = Nokogiri::HTML(open(url))

tables_cells = j.xpath("//div[@id='mkt_tab_content_5']//table//tr")


internal_counter = 0

debug_done = {}

tables_cells.each_with_index do |row|

	company_info = row.text.split(/\n/)
	company_info.reject!{|c| if c == ""
		true
	elsif c.strip == ""
	
		true 
	elsif c.strip =~ /\r/
	
		true
	else
		false
	end
	}

	company_name = nil
	company_weightage = nil

	company_info.each_with_index{|value,k|

				if k == 0
					company_name = value
				elsif k==3
					company_weightage = value
				else

				end

	}

	if !company_name.nil? && !company_weightage.nil?
		if hash_correlate[company_name.strip].nil?
			if company_name.strip != "Company"
				puts "new company found here"
			end
		else
			hash_of_weightages[hash_correlate[company_name.strip]] = 
			company_weightage.to_s.strip!.to_f
		end
	else
		puts "company name or weightage is nil with company"
		puts company_name
	end
	
	internal_counter+=1
end





hash_of_weights = Hash[hash_of_weightages.keys[0..hash_of_weightages.keys.count-1].
zip(hash_of_weightages.values[0..hash_of_weightages.values.count-1])]



f = CSV.open(CSV_FILE_NAME, "w+") {|csv| hash_of_weights.to_a.each {|elem| csv << elem} }



