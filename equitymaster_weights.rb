require 'open-uri'
require 'nokogiri'
require 'csv'
require 'rubyfish'
require 'json'

##url from which the weights are fetched
URL = "https://www.equitymaster.com/india-markets/nse-replica.asp"

##csv file to which weights are written
CSV_FILE_NAME = "baba_weights.csv"

##company names used in baba's actual program internally
COMPANY_NAMES = ["TCS", "ONGC", "RELIANCE", "ITC", "INFY", "SBIN", "HDFCBANK", "COALINDIA", "ICICIBANK", "HDFC", "SUNPHARMA", "HINDUNILVR", "TATAMOTORS", "BHARTIARTL", "LT", "WIPRO", "NTPC", "HCLTECH", "AXISBANK", "MARUTI", "KOTAKBANK", "M&M", "BAJAJ-AUTO", "POWERGRID", "ASIANPAINT", "BHEL", "SSLT", "ULTRACEMCO", "LUPIN", "HEROMOTOCO", "TECHM", "GAIL", "DRREDDY", "NMDC", "BPCL", "CIPLA", "CAIRN", "BANKBARODA", "TATASTEEL", "INDUSINDBANK", "PNB", "ZEEL", "HINDALCO", "AMBUJACEM", "GRASIM", "ACC", "DLF", "IDFC", "TATAPOWER", "JINDALSTEL", "IDEA", "YESBANK", "BOSCHLTD", "VEDL", "ADANIPORTS","IOC","AUROPHARMA","INFRATEL","IBULHSGFIN","TATAMTRDVR","EICHERMOT"]

##threshold for the jaro_distance
JARO_THRESH = 0.64

##@used_in : _parse_table
##@return [Nokogiri::Element] : the nokogiri element of the url or nil
def _load_url
	begin
		Nokogiri::HTML(open(URL))
	rescue => e
		puts e
		nil
	end
end


##@used_in: public method - direct call from anywhere.
##@return[Hash] : {"weights_hash" => {"company_name_as_per_companies_array"} => {"company_name_from_equity_masters_table" => "", "company_name_as_per_companies_array" => "", "jaro_score" => "", "weightage" => ""}, "ignored_companies_hash" => {"company_name_from_equity_masters_table"} => same_value_structure_as_per_weights_hash}
def _parse_table
	weights_hash = {}
	ignored_companies_hash = {}
	##THESE COMPANIES FOR SOME REASON LAND UP GETTING IGNORED, PROBABLY BECAUSE THE TOP MATCH COMES FOR OTHER COMPANIES FROM THE SAME NAME, so I had to hard code them.
	companies_that_dont_work_by_jaro = {"mm" => "M&M","tatamotorsdvr" => "TATAMTRDVR", "bhartiinfratel" => "INFRATEL"}
	if el = _load_url
		el.css("table").each_with_index {|tb,tb_index|
			if tb_index == 5
				weights = tb.css("tr").map{|row|
					if row.css("td").size > 0
						company_name_in_table = row.css('td')[0].text.strip.downcase.gsub(/\s|[[:punct:]]/) { |match| "" }

						##if condition handling the companies that dont work by jaro
						if companies_that_dont_work_by_jaro[company_name_in_table]
							[{"company" => companies_that_dont_work_by_jaro[company_name_in_table], "company_name_in_table" => company_name_in_table, "weightage" => row.css('td')[7].text.to_f},{"jaro_score" => 1.0}]
						else
							levenstein_hash = Hash[COMPANY_NAMES.map{|c|
								[{"company" => c, "company_name_in_table" => company_name_in_table},RubyFish::Jaro.distance(c.downcase,company_name_in_table)]
							}]
							levenstein_hash = levenstein_hash.delete_if{|key,value| value < JARO_THRESH}.sort_by { |k,v| -v }

							if levenstein_hash.empty?
								ignored_companies_hash[company_name_in_table] = {}
								[nil,nil]
							else
								[levenstein_hash[0][0].merge({"weightage" => row.css('td')[7].text.to_f}),{"jaro_score" => levenstein_hash[0][1]}]
							end
						end
					else
						[nil,nil]
					end

				}.flatten.compact

				##at this stage the hash looks like:
				##key ->
				##{"company" => c, "company_name_in_table" => c_tbl, "weightage" => weightage}
				##value ->
				##{"jaro_score" => jaro_score}

				weights.each_slice(2) do |pair|
					##if the weights_hash does not already have the "company",
					##then the key will be company_name
					##value will be  => key + value
					
					if weights_hash[pair[0]["company"]].nil?
						
						weights_hash[pair[0]["company"]] = pair[0].merge(pair[1])
					else
						##if the jaro_score of the current entry in the weights_hash is less than or equal to the jaro_score of the current_slice, i.e pair, then add an entry into the ignored companies, with the following structure
						##key -> company_name_in_table(the equitmaster.com table)
						##value -> the value from the weights_hash hash, since it has the entire merged hash as done above.
						##then replace the current entry in the weights_hash, with the new slice, as done above.
						if weights_hash[pair[0]["company"]]["jaro_score"] <= pair[1]["jaro_score"]
							
							ignored_companies_hash[pair[0]["company_name_in_table"]] = weights_hash[pair[0]["company"]]
							
							weights_hash[pair[0]["company"]] = pair[0].merge(pair[1])
						else
							##in this case, we have to transfer to the ignored_companies, directly.
							##eg: suppose the topmost scoring company was innitially the right company and went into the weigths hash.
							##then later on another entry comes for it, with a lower score(its the wrong company)
							##in that case this else is hit, and that company would need to be sent to the ignored companies.
							ignored_companies_hash[pair[0]["company_name_in_table"]] = pair[0].merge(pair[1])
							
						end
					end
				end
			end
		}

		ignored_companies_hash.delete("total")

		return {"weights_hash" => weights_hash, "ignored_companies_hash" => ignored_companies_hash}
	else
		puts "Could not open the weightages website!"
		sleep(10000)
	end
end

wh = _parse_table
puts JSON.pretty_generate(wh)
hash_to_write_to_csv = Hash[(wh["weights_hash"].keys + wh["ignored_companies_hash"].values.map{|c| c["company_name_in_table"]}).zip(wh["weights_hash"].keys.map{|c| wh["weights_hash"][c]["weightage"]})]
f = CSV.open(CSV_FILE_NAME, "w+") {|csv| hash_to_write_to_csv.to_a.each {|elem| csv << elem} }
