# encoding: UTF-8

require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sinatra/reloader' if development?


configure do
  set :protection, :except => :frame_options
end


DataMapper::Logger.new("debug.log", :debug) if development?
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/cartes.db")

class Carte
  include DataMapper::Resource

  property :id,           Serial
  property :titre,        String,     :length => 255, :required => true
  property :url,          String,     :length => 100, :required => true
end

DataMapper.auto_upgrade!


PAGE_SIZE = 6.0

# ---------- Helpers ----------

helpers do

  def pagination(nb_pages)
    pagination = ""
    nb_pages.times do |page|
      pagination << " <a href='/page/#{page + 1}'>#{page + 1}</a>"
    end
    pagination
  end

end


# Index : affiche la page d'index
get '/' do
  @nb_pages = (Carte.all().count / PAGE_SIZE).ceil
  @cartes = Carte.all(:limit => PAGE_SIZE, :order => [:id.asc])
  erb :index
end


# Index/# : affiche une page de 6 cp
get '/page/:page' do
  @nb_pages = (Carte.all().count / PAGE_SIZE).ceil
  page = Integer(params[:page])
  redirect "/" unless page.between?(1, @nb_pages)
  row_end = page * PAGE_SIZE
  row_start = row_end - PAGE_SIZE
  @cartes = Carte.all(:offset => row_start, :limit => PAGE_SIZE, :order => [:id.asc])
  erb :index
end


# Carte : affiche une page de détail
get '/carte/:url' do
  # Carte postale correspondant à l'URL
  @carte = Carte.first({url: params[:url]})
  # URL carte précédente
  avant = Carte.last({:fields => [:url],
                      :order => :id.asc,
                      :id.lt => @carte.id})
  # (ou la dernière carte)
  avant = Carte.last({:fields => [:url],
                      :order => :id.asc}) unless avant
  @avant = avant[:url]
  # URL carte suivante
  apres = Carte.first({:fields => [:url],
                       :order => :id.asc,
                       :id.gt => @carte.id})
  # (ou la première carte)
  apres = Carte.first({:fields => [:url],
                       :order => :id.asc}) unless apres
  @apres = apres[:url]
  # Affiche la vue détail
  erb :carte
end


# Export_yaml : exporte la table cartes au format Yaml
get '/export_yaml' do
  cartes = Carte.all(:order => [:id.asc])
  File.open("public/data.yaml.txt", "w") do |f|
    f.write(YAML::dump(cartes))
  end
  "export => #{cartes.count}"
end


# Import_yaml : importe la table cartes
get '/import_yaml' do
  Carte.destroy
  cartes = YAML::load(File.open("public/data.yaml.txt", "r"))
  cartes.each do |data|
    Carte.new(data).save
  end
  "import => #{cartes.count}"
end