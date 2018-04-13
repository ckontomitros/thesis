require 'sinatra'
require 'webrick'
get '/bs/get' do 
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
