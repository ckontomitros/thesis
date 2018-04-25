require 'webrick'
require 'sinatra/base'
require 'yaml'
require "rexml/document"
class LteService  < Sinatra::Application
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
  def self.addXMLElement(parent, name, value)
    el = parent.add_element(name)
    el.add_text(value)
  end

  def self.addXMLElementFromFile(parent, xml_doc)
    parent.add_element(xml_doc)
  end

  def self.addXMLElementFromArray(parent,name,value)
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

  def self.addXMLElementsFromHash(parent, elems, isatt=true)
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
		query = params['node']
		thing = YAML.load_file('omf-aggmgr.yaml')
		puts thing[:xmpp].inspect
		kati="You have to include the AP ID number in the query."
		unless query
			kati
		else
			params.delete('node')
			unless params.empty?
				msgEmpty = "Den egine kati"
				replyXML = self.buildXMLReply("Lterf", msgEmpty, msgEmpty) { |root, dummy|
          			nodeEl = root.add_element "node#{query}"
          			

          		}
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
				"HTML5/XML response to be built..."
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
