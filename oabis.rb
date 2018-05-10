require 'socket'
require_relative 'bs'
#require 'omf-aggmgr/ogs_lterf/oai_config'

class OaiBs < Bs
  attr_reader :nomobiles, :serial
  PARAMS_CLASSES = ['WirelessService', 'EpcService', 'ApService', 'AirInterface', 'Reporting',  'PowerControl', 'OAIInterface']

  def initialize( bsconfig)
    super(bsconfig)

    #@mobs = mobs
    @valHash = {"cell_type"=>"CELL_MACRO_ENB",
          "mobile_country_code"=>"208",
          "mobile_network_code"=>"93",
          "eutra_band"=>"7",
          "downlink_frequency"=>"2680000000L",
	  "uplink_frequency_offset"=>"-120000000",
          "N_RB_DL"=>"25",
	  "pdsch_referenceSignalPower" => "-24",
          "rach_numberOfRA_Preambles"=>"64",
          "nb_antennas_tx"=>"1",
          "nb_antennas_rx"=>"1",
          "ue_TimersAndConstants_t311"=>"10000",
          "mme_ip_address"=>"192.168.10.71",
          "ENB_IPV4_ADDRESS_FOR_S1_MME"=>"192.168.10.70/24",
          "ENB_IPV4_ADDRESS_FOR_S1U"=>"192.168.10.70/24",
	  "ENB_INTERFACE_NAME_FOR_S1_MME" => "eth1",
	  "ENB_INTERFACE_NAME_FOR_S1U" => "eth1",
	  "ENB_PORT_FOR_S1U" => "2152"
    }

    @bands = Array.new(14) 
    @fDlLow = Array.new(14)
    @fUlLow = Array.new(14)   
    @nDlOffset = Array.new(14)
    @nUlOffset = Array.new(14)
    @bands.each_with_index do | b, i |
        @bands[i] = i+1
    end
 
    @fDlLow = [2110, 1930, 1805, 2110, 869, 875, 2620, 925, 1844.9, 2110, 1475.9, 728, 746, 758]
    @nDlOffset = [0, 600, 1200, 1950, 2400, 2650, 2750, 3450, 3800, 4150, 4750, 5000, 5180, 5280]
    @fUlLow = [1920, 1850, 1710, 1710, 824, 830, 2500, 880, 1749.9, 1710, 1427.9, 698, 777, 788]
    @nUlOffset = [18000, 18600, 19200, 19950, 20400, 20650, 20750, 21450, 21800, 22150, 22750, 23000, 23180, 23280]

  end
  
#  def initializeConfigFile(values)
#	createFile(values)
# 	scp("/tmp/enb.band7.#{@host}.conf","/tmp/enb_lterf.conf","upload")
#  end
  def info(string)
  	puts(string)
  end
  def sshOAI(command)
	return sshNoPwd(command)
  end

  def set(param, value)
  	resp = {}
    
    	begin
     		puts "Setting #{param} to #{value}"
      		puts convert(param,value)
      		createFile(convert(param,value))
      		scp("/tmp/enb.band7.#{@host}.conf","/tmp/enb_lterf.conf","upload")
      		resp = get(param)
    	rescue
      		info ("Cannot set this parameter")
    	end
    	return resp
  end

  def softExecOAI
      	info "Generating and transfering the configuration file"
	createFile(@valHash)
 	scp("/tmp/enb.band7.#{@host}.conf","/tmp/enb_lterf.conf","upload")
      	info "Starting LTE softmodem application"
     	(sshOAI("/usr/bin/nohup #{@oaipwd} -O /tmp/enb_lterf.conf > /dev/null 2>&1 & ")) ? (return true) : (return true)  
  end


  def execOAI
      	info "Generating and transfering the configuration file"
	createFile(@valHash)
 	scp("/tmp/enb.band7.#{@host}.conf","/tmp/enb_lterf.conf","upload")
      	info "Flashing target firmware version to the USRP device"
      	sshOAI("/usr/lib/uhd/utils/b2xx_fx3_utils -W /usr/share/uhd/images/usrp_b200_fw.hex")
      	info "Running uhd-usrp-probe"
      	sshOAI("/usr/bin/uhd_usrp_probe")
      	info "Starting LTE softmodem application"
      	(sshOAI("/usr/bin/nohup #{@oaipwd} -O /tmp/enb_lterf.conf > /dev/null 2>&1 & ")) ? (return true) : (return true)  
  end

  def stopOAI
      	info "Stopping LTE softmodem application"
      	sshOAI("/bin/ps aux | /bin/grep -ie '[l]te-softmodem' | /usr/bin/awk '{print $2}' | sudo /usr/bin/xargs kill -9")
      	sshOAI("/bin/ps aux | /bin/grep -ie 'run_oai' | /usr/bin/awk '{print $2}' | /usr/bin/xargs kill -9")
      	return true
  end

  def checkStatus
	info "Checking the LTE softmodem status"
      	ret = sshOAI("/bin/ps aux | /bin/grep -ie '[l]te-softmodem' | /usr/bin/awk '{print $2}'")
	if ret.nil?
		return "OAI is not running"
	else
		return "OAI is running"
	end
  end

  def get(query)
    	resp = {}         
    	begin
      		result = convert(query,nil)
      		resp["oai"] = { query => result.strip }
    	rescue
      		info ("Cannot get this parameter")
    	end
    	return resp
  end

  def earFCNDl(freq, band)
     	index = @bands.index(band)
     	earfcndl = (freq.to_i - @fDlLow[index] + (0.1* @nDlOffset[index]))/0.1
     	return earfcndl.to_i
  end

  def earFCNUl(freq, band)     
     	index = @bands.index(band)
     	earfcnul = (freq.to_i - @fUlLow[index] + (0.1* @nUlOffset[index]))/0.1
     	return earfcnul.to_i
  end

  def earFcnToFreqDl (earfcn, band)
     	index = @bands.index(band)
     	fdl = @fDlLow[index] + 0.1*(earfcn - @nDlOffset[index])
     	return fdl.to_i
  end

  def earFcnToFreqUl (earfcn, band)
     	index = @bands.index(band)
     	ful = @fUlLow[index] + 0.1*(earfcn - @nUlOffset[index])
     	return ful.to_i
  end

  def freqDlMHz (freq)
        return (freq.to_i)/1000000
  end

  def freqDlHz (freq)
        freq = (freq.to_i)*1000000
	freq = freq.to_s + "L"
	return freq
  end

  def freqUlHz (freq)
        freq = (freq.to_i)*1000000
	return freq
  end

  def freqUlMHz (freqDl, freqUlOffset)
        freqDl = freqDl.to_i
	# TODO: special handling for band 13!!
	freq = freqDl - freqUlOffset.to_i
	return (freq)/1000000
  end

  def freqUlOffset (freqDl, freqUl)
	#TODO: special handling for band 13
	offset = freqDl - freqUl
	puts offset
	return offset
  end

  def restart
    	info "Restarting OAI Cell... "
    	begin
		stopOAI
		softExecOAI
    	rescue => ex
      		result = "Failed: '#{ex}'"
    	end
  end
  
  def scp(file_path,remote_path,action)
        ret = nil
        ret = scpNoPwd(file_path,remote_path,action)
        ret
  end

  def upload_settings(file_path)
	require 'json'
	file = File.read(file_path)
	@valHash = JSON.parse(file)
	true
  end

  def save_settings(file_path)
	require 'json'
	File.open(file_path, "w") do |f| 
		f.write(@valHash.to_json)
	end
	true	
  end

  def reset_to_defaults(file_path)
    	ret = nil
    	ret = reset_to_defaults_NoPwd(file_path)
    	ret
  end

  def convert(param,val)
    	res = Array.new()  
	puts "Inside convert function"    
	case param
    		when "eNBType" 
      			if val.nil?
        			return @valHash["cell_type"] 
      			else
        			@valHash["cell_type"]=val
        			return @valHash
      			end
    		when "trackingAreaCode"
      			if val.nil?
        			res=@valHash["mobile_country_code"]
        			res=res+@valHash["mobile_network_code"]
        			return res
      			else
         			mcc = val[0..1]||val
         			mnc = val[-3..-1] ||val
			        @valHash["mobile_country_code"]=mcc
         			@valHash["mobile_network_code"]=mnc
         			return @valHash            
      			end  
   	 	when "freqBandIndicator"
      			if val.nil?
        			return @valHash["eutra_band"]
      			else
        			@valHash["eutra_band"]=val 
        			return @valHash
      			end
    		when "earFcnDl"
      			#TODO convert earfcl to frequency
      			if val.nil? 
        			val1 = @valHash["downlink_frequency"]
				val1 = freqDlMHz(val1)
				# Now we are holding the Dl Freq in MHz
				band = @valHash["eutra_band"].to_i
				#get earfcnDl
				val1 = earFCNDl(val1, band)
				return val1.to_s
      			else 
				# val is holding the earfcn, make it a frequency
				band = @valHash["eutra_band"].to_i
				freq = earFcnToFreqDl(val.to_i, band)
				freq = freqDlHz(freq)
        			@valHash["downlink_frequency"]=freq.to_s
        			return @valHash
      			end
    		when "earFcnUl"
      			if val.nil? 
        			val1 = @valHash["downlink_frequency"]
				val2 = @valHash["uplink_frequency_offset"]
				# compute uplink frequency
				ulfreq = freqUlMHz(val1, val2)
				# Now we are holding the Dl Freq in MHz
				band = @valHash["eutra_band"].to_i
				#get earfcnDl
				val1 = earFCNUl(ulfreq, band)
				return val1.to_s
      			else 
				# val is holding the earfcn, make it a frequency
				band = @valHash["eutra_band"].to_i
				freq = earFcnToFreqUl(val.to_i, band)
				# freq is holding the UL freq in MHz
				freqUl = freqUlHz(freq)
				freqDl = @valHash["downlink_frequency"].to_i
				offset = freqUlOffset(freqDl, freqUl)
        			@valHash["uplink_frequency_offset"]=offset.to_s
      		  		return @valHash
      			end
    		when "RefSignalPower"
      			if val.nil?
        			return @valHash["pdsch_referenceSignalPower"]
      			else
        			@valHash["pdsch_referenceSignalPower"]=val
        			return @valHash
      			end
    		when "DlBandwidth"
      			if val.nil?
        			val1 = @valHash["N_RB_DL"]
				if val1.eql?("25")
	   				val1 = 2
				elsif val1.eql?("50")
	   				val1 = 3
				elsif val1.eql?("100")
	   				val1 = 4
				end
				return val1.to_s
      			else
        			#@valHash["N_RB_DL"]=val 
				if val.to_i.eql?(2)
	  				@valHash["N_RB_DL"] ="25"
				elsif val.to_i.eql?(3)
	  				@valHash["N_RB_DL"] = "50"
				elsif val.to_i.eql?(4)
	  				@valHash["N_RB_DL"] = "100"
				end
        			return @valHash
      			end
    		when "UlBandwidth"
      			if val.nil?
        			val1 = @valHash["N_RB_DL"]
				if val1.eql?("25")
	   				val1 = 2
				elsif val1.eql?("50")
	   				val1 = 3
				elsif val1.eql?("100")
	   				val1 = 4
				end
				return val1.to_s
      			else
        			#@valHash["N_RB_DL"]=val 
				if val.to_i.eql?(2)
	 		 		@valHash["N_RB_DL"] = 25  
				elsif val.to_i.eql?(3)
	  				@valHash["N_RB_DL"] = 50
				elsif val.to_i.eql?(4)
	  				@valHash["N_RB_DL"] = 100
				end
        			return @valHash
      			end
   		 when "NumOfRACHPreambles"   
      			if val.nil?
        			return @valHash["rach_numberOfRA_Preambles"]
      			else
        			@valHash["rach_numberOfRA_Preambles"]=val
        			return @valHash
      			end
    		when "TxMode"
      			if val.nil?
        			return @valHash["nb_antennas_rx"]
      			else
         			@valHash["nb_antennas_rx"]=val  
         			@valHash["nb_antennas_tx"]=val 
        			return @valHash
      			end
    		when "ueInactivityTimer"
      			if val.nil?          
        			return @valHash["ue_TimersAndConstants_t311"]
      			else
        			@valHash["ue_TimersAndConstants_t311"]=val
        			return @valHash
      			end
    		when "pgwIpAddress"
      			if val.nil?       
        			return @valHash["mme_ip_address"]
      			else
        			@valHash["mme_ip_address"]=val
        			return @valHash
      			end
    		when "epcIpAddress"
      			if val.nil?       
        			return @valHash["mme_ip_address"]
      			else
        			@valHash["mme_ip_address"]=val
        			return @valHash
      			end
		when "enbIpv4AddressS1MME"
      			if val.nil?       
        			return @valHash["ENB_IPV4_ADDRESS_FOR_S1_MME"]
      			else
				if val =~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
        				@valHash["ENB_IPV4_ADDRESS_FOR_S1_MME"]=val
        				return @valHash
				elsif val =~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/
					val = val +"/24"
        				@valHash["ENB_IPV4_ADDRESS_FOR_S1_MME"]=val
        				return @valHash
				else
					raise "Address is not in the correct format"
				end
      			end
		when "enbIpv4AddressS1U"
      			if val.nil?       
        			return @valHash["ENB_IPV4_ADDRESS_FOR_S1U"]
      			else
				if val =~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
        				@valHash["ENB_IPV4_ADDRESS_FOR_S1U"]=val
        				return @valHash
				elsif val =~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/
					val = val +"/24"
        				@valHash["ENB_IPV4_ADDRESS_FOR_S1U"]=val
        				return @valHash
				else
					raise "Address is not in the correct format"
				end
      			end
		when "enbIpv4InterfaceS1MME"
      			if val.nil?       
        			return @valHash["ENB_INTERFACE_NAME_FOR_S1_MME"]
      			else
        			@valHash["ENB_INTERFACE_NAME_FOR_S1_MME"]=val
        			return @valHash
      			end
		when "enbIpv4InterfaceS1U"
      			if val.nil?       
        			return @valHash["ENB_INTERFACE_NAME_FOR_S1U"]
      			else
        			@valHash["ENB_INTERFACE_NAME_FOR_S1U"]=val
        			return @valHash
      			end
		when "enbPortS1U"
      			if val.nil?       
        			return @valHash["ENB_PORT_FOR_S1U"]
      			else
        			@valHash["ENB_PORT_FOR_S1U"]=val
        			return @valHash
      			end
		end
  end # end of convert function


def createFile(values) 
	inHash = values
	File.open("/tmp/enb.band7.#{@host}.conf", 'w') {|file| file.write(
"Active_eNBs = ( \"eNB_Eurecom_LTEBox\");
# Asn1_verbosity, choice in: none, info, annoying
Asn1_verbosity = \"none\";

eNBs =
(
 {
   # real_time choice in {hard, rt-preempt, no}
    real_time       =  \"no\";
    ////////// Identification parameters:
    eNB_ID    =  0xe00;

    cell_type = \"#{inHash["cell_type"]}\";

    eNB_name  =  \"eNB_Eurecom_LTEBox\";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code  =  \"1\";

    mobile_country_code =  \"#{inHash["mobile_country_code"]}\";

    mobile_network_code =  \"#{inHash["mobile_network_code"]}\";
    
     //////// Physical parameters:

    component_carriers = (
                         {
                           frame_type                                         = \"FDD\";
                           tdd_config                                         = 3;
                           tdd_config_s                                       = 0;
                           prefix_type                                        = \"NORMAL\";
                           eutra_band                                         = #{inHash["eutra_band"]};
                           downlink_frequency                                 = #{inHash["downlink_frequency"]};
                           uplink_frequency_offset                            = #{inHash["uplink_frequency_offset"]};
                           Nid_cell                                           = 0;
                           N_RB_DL                                            = #{inHash["N_RB_DL"]};
                           Nid_cell_mbsfn                                     = 0;
                           nb_antennas_tx                                     = #{inHash["nb_antennas_tx"]};
                           nb_antennas_rx                                     = #{inHash["nb_antennas_rx"]};
                           tx_gain                                            = 110;
                           rx_gain                                            = 120;
                           prach_root                                         = 0;
                           prach_config_index                                 = 0;
                           prach_high_speed                                   = \"DISABLE\";
                           prach_zero_correlation                             = 1;
                           prach_freq_offset                                  = 2;
                           pucch_delta_shift                                  = 1;
                           pucch_nRB_CQI                                      = 1;
                           pucch_nCS_AN                                       = 0;
                           pucch_n1_AN                                        = 32;
                           pdsch_referenceSignalPower                         = #{inHash["pdsch_referenceSignalPower"]};
                           pdsch_p_b                                          = 0;
                           pusch_n_SB                                         = 1;
                           pusch_enable64QAM                                  = \"DISABLE\";
                           pusch_hoppingMode                                  =\"interSubFrame\";
                           pusch_hoppingOffset                                = 0;
                           pusch_groupHoppingEnabled                          = \"ENABLE\";
                           pusch_groupAssignment                              = 0;
                           pusch_sequenceHoppingEnabled                       = \"DISABLE\";
                           pusch_nDMRS1                                       = 0;
                           phich_duration                                     = \"NORMAL\";
                           phich_resource                                     = \"ONESIXTH\";
                           srs_enable                                         = \"DISABLE\";
                       /*  srs_BandwidthConfig                                =;
                           srs_SubframeConfig                                 =;
                           srs_ackNackST                                      =;
                           srs_MaxUpPts                                       =;*/
                              
                            pusch_p0_Nominal                                   = -98;
                           pusch_alpha                                        = \"AL1\";
                           pucch_p0_Nominal                                   = -108;
                           msg3_delta_Preamble                                = 6;
                           pucch_deltaF_Format1                               = \"deltaF2\";
                           pucch_deltaF_Format1b                              = \"deltaF3\";
                           pucch_deltaF_Format2                               = \"deltaF0\";
                           pucch_deltaF_Format2a                              = \"deltaF0\";
                           pucch_deltaF_Format2b                              = \"deltaF0\";

                           rach_numberOfRA_Preambles                          = #{inHash["rach_numberOfRA_Preambles"]};
                           rach_preamblesGroupAConfig                         = \"DISABLE\";
/*
                           rach_sizeOfRA_PreamblesGroupA                      = ;
                           rach_messageSizeGroupA                             = ;
                           rach_messagePowerOffsetGroupB                      = ;
*/
                           rach_powerRampingStep                              = 2;
                           rach_preambleInitialReceivedTargetPower            = -100;
                           rach_preambleTransMax                              = 10;
                           rach_raResponseWindowSize                          = 10;
                           rach_macContentionResolutionTimer                  = 48;
                           rach_maxHARQ_Msg3Tx                                = 4;

                           pcch_default_PagingCycle                           = 128;
                           pcch_nB                                            = \"oneT\";
                           bcch_modificationPeriodCoeff                       = 2;
                           ue_TimersAndConstants_t300                         = 1000;
                           ue_TimersAndConstants_t301                         = 1000;
                           ue_TimersAndConstants_t310                         = 1000;
                           ue_TimersAndConstants_t311                         = #{inHash["ue_TimersAndConstants_t311"]};
                           ue_TimersAndConstants_n310                         = 20;
                           ue_TimersAndConstants_n311                         = 1;
                           nb_antenna_ports                                   = 1;
                           ue_TransmissionMode                                = 1;

                         }
                         );
                   ////////// MME parameters:
    mme_ip_address      = ( { ipv4       = \"#{inHash["mme_ip_address"]}\";
                              ipv6       = \"192:168:30::17\";
                              active     = \"yes\";
                              preference = \"ipv4\";
                            }
                          );

    NETWORK_INTERFACES :
    {
        ENB_INTERFACE_NAME_FOR_S1_MME            = \"#{inHash["ENB_INTERFACE_NAME_FOR_S1_MME"]}\";
        ENB_IPV4_ADDRESS_FOR_S1_MME              = \"#{inHash["ENB_IPV4_ADDRESS_FOR_S1_MME"]}\";

        ENB_INTERFACE_NAME_FOR_S1U               = \"#{inHash["ENB_INTERFACE_NAME_FOR_S1U"]}\";
        ENB_IPV4_ADDRESS_FOR_S1U                 = \"#{inHash["ENB_IPV4_ADDRESS_FOR_S1U"]}\";
         ENB_PORT_FOR_S1U                         = \"#{inHash["ENB_PORT_FOR_S1U"]}\"; # Spec 2152
    };

    log_config :
    {
        global_log_level                      =\"debug\";
        global_log_verbosity                  =\"medium\";
        hw_log_level                          =\"debug\";
        hw_log_verbosity                      =\"medium\";
        phy_log_level                         =\"debug\";
        phy_log_verbosity                     =\"medium\";
        mac_log_level                         =\"debug\";
        mac_log_verbosity                     =\"high\";
        rlc_log_level                         =\"info\";
        rlc_log_verbosity                     =\"medium\";
        pdcp_log_level                        =\"info\";
        pdcp_log_verbosity                    =\"medium\";
        rrc_log_level                         =\"debug\";
        rrc_log_verbosity                     =\"medium\";
   };

  }
);") }  

	end
end
