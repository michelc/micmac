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

  def pagination(page_courante, nb_pages)
    " début de liste"
    pagination = "<ul class='pagination'>\n"
    # page avant
    if page_courante > 1 then
      pagination << pagination_lien(page_courante - 1, "«", 0)
    else
      pagination << "  <li><span>«</span></li>"
    end
    # 6 pages autour de la page en cours
    au = page_courante + 3 < nb_pages ? page_courante + 3 : nb_pages
    du = au - 5
    if du < 1
      du = 1
      au = du + 5 < nb_pages ? du + 5 : nb_pages
    end
    (du..au).each do |page|
      pagination << pagination_lien(page, page.to_s, page_courante)
    end
    # page apres
    if page_courante < nb_pages then
      pagination << pagination_lien(page_courante + 1, "»", 0)
    else
      pagination << "  <li><span>»</span></li>"
    end
    # fin de liste
    pagination << "</ul>\n"
    pagination
  end

  def pagination_lien(page, text, page_courante)
    un_lien = "  <li>"
    if page == page_courante
      un_lien << "<strong>#{text}</strong>"
    else
      un_lien << if page == 1 then "<a href='/'>" else "<a href='/page/#{page}'>" end
      un_lien << "#{text}</a>"
    end
    un_lien << "</li>\n"
    un_lien
  end

end


# Index : affiche la page d'index
get '/' do
  @nb_pages = (Carte.all().count / PAGE_SIZE).ceil
  @num_page = 1
  @cartes = Carte.all(:limit => PAGE_SIZE, :order => [:id.asc])
  erb :index
end


# Index/# : affiche une page de 6 cp
get '/page/:page' do
  @nb_pages = (Carte.all().count / PAGE_SIZE).ceil
  @num_page = params[:page].to_i
  redirect "/" unless @num_page.between?(1, @nb_pages)
  row_end = @num_page * PAGE_SIZE
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