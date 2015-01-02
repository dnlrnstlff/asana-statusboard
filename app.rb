require 'rubygems'

require 'json'
require 'net/https'
require 'open-uri'
require 'openssl'

require 'sinatra'
require 'haml'
require 'sass'

$stdout.sync = true

def asana_data(api_key, path)
  uri = URI.parse("https://app.asana.com/api/1.0/" + path)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  header = {
    "Content-Type" => "application/json"
  }
  req = Net::HTTP::Get.new(uri.path + "?archived=false", header)
  req.basic_auth(api_key, '')
  return http.start { |http| http.request(req) }
end

def asana_projects(api_key, workspace_id)
  all_projects = []
  all_res = []

  res = asana_data(api_key, "workspaces/" + workspace_id + "/projects")
  body = JSON.parse(res.body)

  if body['errors'] then
    puts "Server returned an error: #{body['errors'][0]['message']}"
  else
    # put all project IDs in an array
    body.fetch("data").each do |projects|
      all_projects.push(projects.fetch("id"))
    end

    all_projects.each do |project|
      res = asana_data(api_key, "projects/" + project.to_s)
      json = JSON.parse(res.body)
      project = json.fetch("data")
      all_res.push(project)
    end
    return all_res
  end
end

get '/:api_key/:workspace_id' do
  api_key = params[:api_key]
  workspace_id = params[:workspace_id]
  @projects = asana_projects(api_key, workspace_id)
  haml :index, :format => :html5
end
