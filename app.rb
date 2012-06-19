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
  property :titre,        String,     :length => 255,
                                      :required => true,
                                      :message => "Le titre est obligatoire"
  property :url,          String,     :length => 100,
                                      :required => true,
                                      :unique => true,
                                      :messages => {
                                        :presence  => "L'URL est obligatoire",
                                        :is_unique => "Cette URL est déjà utilisée"
                                      }
end

DataMapper.auto_upgrade!


PAGE_SIZE = 6

# ---------- Helpers ----------

helpers do

  def admin_link(text, action, id = nil)
    if !development?
      # administration autorisé en mode développement uniquement
      ""
    elsif id
      "<a href='/admin/#{action}/#{id}'>#{text}</a>"
    else
      "<a href='/admin/#{action}'>#{text}</a>"
    end
  end

  def pagination(page_courante, nb_pages, reverse)
    pagination = []
    page_racine = reverse ? nb_pages : 1
    # page avant
    pagination << pagination_lien(reverse ? ">" : "<", page_courante - 1, page_racine)
    # 6 pages autour de la page en cours
    au = page_courante + 3 < nb_pages ? page_courante + 3 : nb_pages
    du = au - 5
    if du < 1
      du = 1
      au = du + 5 < nb_pages ? du + 5 : nb_pages
    end
    (du..au).each do |page|
      pagination << pagination_lien(page.to_s, page, page_racine, page_courante)
    end
    # page après
    page_courante = -1 if page_courante == nb_pages
    pagination << pagination_lien(reverse ? "<" : ">", page_courante + 1, page_racine)
    # fin de liste
    reverse ? pagination.reverse : pagination
  end

  def pagination_lien(texte, destination, page_racine, page_courante = 0)
    case destination
    when 0 then
      # pas de page de destination => pas de lien
      un_lien = { text: texte, href: nil }
    when page_courante then
      # page de destination est la page en cours => pas de lien
      un_lien = { text: texte, href: nil, here: true }
    when page_racine then
      # page de destination est la page par défaut => lien vers racine
      un_lien = { text: texte, href: "/" }
    else
      # lien vers la page de destination
      un_lien = { text: texte, href: "/page/#{destination}" }
    end
    un_lien
  end

  def get_page(num_page)
    nb_cartes = Carte.all().count
    nb_pages = (nb_cartes / PAGE_SIZE.to_f).ceil
    if (num_page == -1)
      # page racine
      num_page = nb_pages
      row_end = nb_cartes
    else
      # autre page
      redirect "/" unless num_page.between?(1, nb_pages)
      row_end = num_page * PAGE_SIZE
    end
    row_start = row_end - PAGE_SIZE
    cartes = Carte.all(:offset => row_start, :limit => PAGE_SIZE, :order => [:id.asc])
    @cartes = cartes.to_a.reverse
    @pagination = pagination(num_page, nb_pages, true)
    erb :index
  end

  def cartes_utilisables
    # les cartes présentes dans le répertoire
    cartes_dossier = Dir.entries("public/cartes") - [".", ".."]
    cartes_dossier.keep_if { |filename| !filename.end_with?("-900.jpg") }
    cartes_dossier.map! { |filename| filename.sub('.jpg', "") }
    # les cartes déjà en base de données
    cartes_base = []
    Carte.all(fields: [:url], order: :url.asc).each { |carte| cartes_base << carte.url }
    # les cartes utilisables
    cartes_dossier - cartes_base
  end

  def select_options(list, selected_value)
    html = "<option id=''></option>"
    list.each do |item|
      html << "\n<option "
      html << "selected " if item == selected_value
      html << "id='#{item}'>#{item}</option>"
    end
    html
  end

end


before '/admin/*' do
  halt [ 401, 'Not Authorized' ] unless development?
end


# Index : affiche la page d'index
get '/' do
  get_page(-1)
end


# Index/# : affiche une page de 6 cartes postales
get '/page/:page' do
  get_page(params[:page].to_i)
end


# Carte.New : formulaire pour créer une carte
get '/admin/new' do
  @carte = Carte.new
  @urls_utilisables = cartes_utilisables()
  erb :new
end


# Carte.Create : enregistre une nouvelle carte
post '/admin' do
  @carte = Carte.new(params[:carte])
  @urls_utilisables = cartes_utilisables()
  # Vérifie que la carte existe
  carte_src = params[:carte][:url]
  unless carte_src.empty?
    snapshot = "public/cartes/#{carte_src}.jpg"
    unless File.file?(snapshot)
      status 400
      @carte.errors.add(:url, "#{carte_src}.jpg n'existe pas")
      return erb :new
    end
    fullsize = "public/cartes/#{carte_src}-900.jpg"
    unless File.file?(fullsize)
      status 400
      @carte.errors.add(:url, "#{carte_src}-900.jpg n'existe pas")
      return erb :new
    end
  end
  # Enregistre la carte
  if @carte.save
    status 201
    redirect "/"
  else
    status 400
    erb :new
  end
end


# Carte.Edit : formulaire pour modifier une carte
get '/admin/edit/:id' do
  @carte = Carte.get(params[:id])
  @carte_src = @carte.url
  erb :edit
end


# Carte.Update : met à jour une carte
put '/admin/:id' do
  @carte = Carte.get(params[:id])
  @carte_src = @carte.url
  if @carte.update(params[:carte])
    status 201
    redirect "/"
  else
    status 400
    erb :edit
  end
end


# Carte.Delete : formulaire confirmation suppression d'une carte
get '/admin/delete/:id' do
  @carte = Carte.get(params[:id])
  @carte_src = @carte.url
  erb :delete
end


# Carte.Destroy : supprime une carte
delete '/admin/:id' do
  @carte = Carte.get(params[:id])
  @carte_src = @carte.url
  if (@carte.destroy)
    status 200
    redirect "/"
  else
    status 400
    erb :delete
  end
end


# Carte : affiche une page de détail
get '/carte/:url' do
  # Carte postale correspondant à l'URL
  @carte = Carte.first({url: params[:url]})
  # URL carte précédente (insérée en base après celle-ci)
  avant = Carte.first({:fields => [:url],
                       :order => :id.asc,
                       :id.gt => @carte.id})
  # (ou la dernière carte insérée)
  avant = Carte.first({:fields => [:url],
                       :order => :id.asc}) unless avant
  @avant = avant[:url]
  # URL carte suivante (insérée en base avant celle-ci)
  apres = Carte.last({:fields => [:url],
                      :order => :id.asc,
                      :id.lt => @carte.id})
  # (ou la première carte insérée)
  apres = Carte.last({:fields => [:url],
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