require 'webrick'
require 'sinatra/base'
require 'yaml'
require "rexml/document"
require  './oaibs'
class LteService  < Sinatra::Application
	@@valHash = {'ip'=>'node060',
		'type' => 'default',
		'key'  => 'key',
		'version' => '0.1',
		'sshusers' => 'root',
		'sshpass' => 'passwd',
		'oaipwd'  => 'passwd',
		'default' => 'default'
	}
	def initialize()
		puts "mpika"
		thing = YAML.load_file('lterf.yaml')
    @config = thing['lterf']
    @bsversion = Array.new
    puts thing['lterf']['bs']
    if @config['bs']['type'].kind_of?(Array)
      @bstype = @config['bs']['type']
      @bstype_no = @config['bs']['type'].length
      @bsversion = @config['bs']['version']
       
      (0..(@bstype_no-1)).each do |i|
       # debug(serviceName, "Loading #{(@bstype[i].to_s.downcase).capitalize} base station module")
        require "./#{@bstype[i].to_s.downcase}bs"
      end
    else
      @bstype = @config['bs']['type'].to_s.downcase
      @bsversion = @config['bs']['version'].to_s.downcase
      @bstype_no = 1

     # debug(serviceName, "Loading #{@bstype.capitalize} base station module")
      require "./#{@bstype}bs" 
    end
    p @bstype
    p @bsversion
    #puts "bstypess is : #{@bstype} \n\n"
    #@bstype = @config['bs']['type'].to_s.downcase
    raise("'type' cannot be empty in 'bs' section in lterf.yaml") if @bstype.empty?

    # load database
#    dbFile = "#{LTERF_DIR}/#{@config['database']['dbFile']}"
    #debug(serviceName, "Loading database file #{dbFile}")
 #   DataMapper.setup(:default, "sqlite://#{dbFile}")
  #  DataMapper.auto_upgrade!
    
    #(0..(@bstype_no-1)).each do |i|
    #  debug(serviceName, "Loading #{(@bstype[i].to_s.downcase).capitalize} base station module")
    #  require "omf-aggmgr/ogs_lterf/#{@bstype[i].to_s.downcase}bs"
    #end
    @bs = []
    #@epc = []

    #puts "type is :#{@config['bs']['type'][1]}"  

    if @config['bs']['ip'].kind_of?(Array)
      @bs_no = @config['bs']['ip'].length
    else
      @bs_no = 1
    end

   # puts "#{@bstype[0].to_s.downcase}\n\n"
   # str = @bstype[0].to_s.dowcase
   # puts "#{str.Kind_of}\n\n"
    @num = -1
    (0..(@bstype_no-1)).each do | i | #for each type of BS

      if @bstype_no > 1 #2 or more types of BS and 2 or more BSs
 
          #alternate_config = configure_file(@config['bs'], i, -1)
          #@bs.push(Kernel.const_get("#{(@bstype[i].to_s.downcase)}Bs").new(@mobs, alternate_config))
          @bs.push(Kernel.const_get("#{(@bstype[i].to_s.downcase)}Bs").new(@@valHash))
          @num = @num + 1  

      elsif @bs_no > 1 # 1 type of BS and 1 or more numbers of BSs

           (0..(@bs_no-1)).each do | j | #for each BS      
           #alternate_config = configure_file(@config['bs'], -1, j)
           #@bs.push(Kernel.const_get("#{@bstype[i]}Bs").new(@mobs, alternate_config))
           @bs.push(Kernel.const_get("#{@bstype[i]}Bs").new(@@valHash))
           @num = @num + 1
         end

      else
         #alternate_config = configure_file(@config['bs'], -1, -1)
         #@bs.push(Kernel.const_get("#{@bstype[i]}Bs").new(@mobs, alternate_config))
         @bs.push(Kernel.const_get("#{@bstype[i]}Bs").new(@@valHash))
         @num = @num + 1
      end  
     super   
    end
=begin
    initMethods

    @epcconfig = @config['epc']
    @epctype = @epcconfig['type']

    require "omf-aggmgr/ogs_lterf/#{@epctype}epc"

    @epc = Kernel.const_get("#{@epctype.capitalize}Epc").new(@mobs, @epcconfig)
    initEpcMethods
    createDataPath(@config['datapath'])
    @ltecontent = ApnContent.new();   

    initDatapathMethods
=end
  end

	
	@@oabis=OaiBs.new(@@valHash)



	def buildXMLReply(replyName, result, msg, &block)
    root = REXML::Element.new("#{replyName}")
    if result == :Error
      addXMLElement(root, "ERROR", "Error when accessing the Inventory Database")
    elsif result == nil || result.empty?
      addXMLElement(root, "ERROR", "#{msg}")
    else
      yield(root, result)
    end
    root
  end

  #
  # Create new XML element and add it to an existing XML tree
  #
  # - parent = the existing XML tree to add the new element to
  # - name = the name for the new XML element to add
  # - value =  the value for the new XML element to add
  #
  def addXMLElement(parent, name, value)
    el = parent.add_element(name)
    el.add_text(value)
  end

  def addXMLElementFromFile(parent, xml_doc)
    parent.add_element(xml_doc)
  end

  def addXMLElementFromArray(parent,name,value)
    value.each { |val|
      if val.is_a?(Hash)
          el = parent.add_element(name)
          addXMLElementsFromHash(el,val, false)
      else
          if val.is_a?(Array)
            addXMLElementFromArray(parent,name,val)
          else
            el = parent.add_element(name)
            el.add_text(val)
          end
      end
    }
  end

  def addXMLElementsFromHash(parent, elems, isatt=true)
    m_isatt = isatt
    elems.each_pair { |key,val|
      if val.is_a?(Hash)
        m_isatt=false
      else
        m_isatt=isatt
      end
      if (m_isatt)
        parent.add_attribute(key,val)
      else
        if val.is_a?(Hash)
          el = parent.add_element(key)
          addXMLElementsFromHash(el,val, false)
        else
          if val.is_a?(Array)
            addXMLElementFromArray(parent,key,val)
          else
            el = parent.add_element(key)
            el.add_text(val)
          end
        end
      end
    }
  end
	@@list_methods=Array.new

		
	get '/bs/get' do 
		node_index = params['node']
		thing = YAML.load_file('omf-aggmgr.yaml')
		puts thing[:xmpp].inspect
		kati="You have to include the AP ID number in the query."
		unless node_index
			kati
		else
			params.delete('node')
			unless params.empty?
				msgEmpty = "Den egine kati"
				replyXML = self.buildXMLReply("Lterf", msgEmpty, msgEmpty) { |root, dummy|
					bs = root.add_element "BS"
          			nodeEl = bs.add_element "bs"
          			params.each { |key,value|
            			puts key, value 
	    				element=@bs[node_index.to_i-1].get(key)
	    				#element=@@oabis.get(key)
	    				puts element
	    				self.addXMLElementsFromHash(nodeEl,element)
          				
          			}
          			

          		}
          		puts replyXML
          		content_type "xml"
          		replyXML.to_s
        
				#{}"HTML5/XML response to be built..."
			else
				WEBrick::HTTPStatus::BadRequest = "Missing parameter"
				
			end
		end

	end

	get '/bs/set' do
		query = params['node']
		unless query
			"You have to include the AP ID number in the query."
		else
			params.delete('node')
			unless params.empty?
				msgEmpty = "Den egine kati"
				replyXML = self.buildXMLReply("Lterf", msgEmpty, msgEmpty) { |root, dummy|
					bs = root.add_element "BS"
          			nodeEl = bs.add_element "node#{query}"
          			params.each { |key,value|
          				 v = @@oabis.set(key, value)
	    				addXMLElementsFromHash(nodeEl,v) 
          }

          		}
          		content_type "xml"
          		replyXML.to_s
			else
				WEBrick::HTTPStatus::BadRequest = "Missing parameter"
				
			end
		end	


	end

	get '/epc/get' do
		query = params['node']
		unless query
			"You have to include the AP ID number in the query."
		else
			params.delete('node')
			unless params.empty?
				"HTML5/XML response to be built..."
			else
				WEBrick::HTTPStatus::BadRequest = "Missing parameter"
				
			end
		end	

	end

	get '/epc/set' do
		query = params['node']
		unless query
			"You have to include the AP ID number in the query."
		else
			params.delete('node')
			unless params.empty?
				"HTML5/XML response to be built..."
			else
				WEBrick::HTTPStatus::BadRequest = "Missing parameter"
				
			end
		end
	end

	get '/bs/config/save' do
		query = params['node']
		unless query
			"You have to include the AP number that you want to save its configuration."
		else
			name = params['name']
			unless name
				"You did not include a name to save the configuration."
			else
				"Stuff to be implemented"
				
			end
		end
	end
	get '/bs/config/load' do
		query = params['node']
		unless query
			"You have to include the AP number that you want to load a specific configuration."
		else
			name = params['name']
			unless name
				"You did not include the name of the configuration."
			else
				"Stuff to be implemented"
				
			end
		end
	end

	get '/bs/config/convert' do
		name = params['name']
		unless name
			"You did not include the name of the configuration."
		else
			"Stuff to be implemented"
				
		end
		
	end
	get '/bs/config/list' do
		"List elements to be implemented ..."
	end
	get '/bs/config/delete' do
		name = params['name']
		unless name
			"You have to specify the name of the configuration to be deleted."
		else
			"Stuff to be implemented"
				
		end
		
	end

	

	get '/epc/config/save' do
		name = params['name']
		unless name
			"You did not include a name to save the configuration."
		else
			"Stuff to be implemented"
				
		end
		
	end

	get '/epc/config/list' do
		"List elements to be implemented ..."
	end

	get '/epc/config/save' do
		name = params['name']
		unless name
			"You did not include a name to save the configuration."
		else
			"Stuff to be implemented"
				
		end
		
	end

	get '/epc/config/delete' do
		name = params['name']
		unless name
			"You have to specify the name of the configuration to be deleted."
		else
			"Stuff to be implemented"
				
		end
		
	end

	get '/epc/config/testbed' do
		name = params['name']
		unless name
			"You have to include the name of the testbed to use by appending ?name=indoor or ?name=outdoor to your query."
		else
			"Stuff to be implemented"
				
		end
		
	end

	get '/epc/config/set' do
		query = params['node']
		unless query
			"You have to include the AP ID number in the query."
		else
			params.delete('node')
			unless params.empty?
				"HTML5/XML response to be built..."
			else
				WEBrick::HTTPStatus::BadRequest = "Missing parameter"
				
			end
		end
	end
	self.routes["GET"].each do |route|
  		@@list_methods<<route[0]
	end

	

	get '/' do
		output=''
		@@list_methods.each do |route|
  		output << "#{route} <br />"
  		end
  		return output
  	end
	run! if app_file == $0
end
