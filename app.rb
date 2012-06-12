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


class Carte_QD
  attr_accessor :url, :titre

  def initialize(url, titre)
    @url = url
    @titre = titre
  end
end


# Import : importe les cartes dans la bdd
get '/import' do
  cartes = quick_and_dirty_db()
  cartes.each do |carte|
    carte_db = Carte.new
    carte_db.titre = carte.titre
    carte_db.url = carte.url
    carte_db.save
  end
  @cartes = Carte.all(:order => [:id.asc])
  erb :index
end


# Index : affiche la page d'index
get '/' do
  @cartes = quick_and_dirty_db()
  erb :index
end


# Carte : affiche une page de détail
get '/carte/:url' do
  cartes = quick_and_dirty_db()
  # @carte = cartes.select {|c| c.url == params[:url] }[0]
  # @carte = cartes.find {|c| c.url == params[:url] }
  index = cartes.index {|c| c.url == params[:url] }
  @carte = cartes[index]
  # URL carte précédente
  @avant = index == 0 ? cartes.length - 1 : index - 1
  @avant = cartes[@avant].url
  # URL carte suivante
  @apres = index == cartes.length - 1 ? 0 : index + 1
  @apres = cartes[@apres].url
  erb :carte
end


def quick_and_dirty_db()
  # Initialise la liste des cartes postales
  cartes = []
  # Insére les différentes cartes postales
  cartes << Carte_QD.new("01-ardeche", "L'Ardèche à Saint-Privat")
  cartes << Carte_QD.new("02-ardeche", "L'Ardèche à Saint-Privat")
  cartes << Carte_QD.new("03-vue-generale", "Vue Générale")
  cartes << Carte_QD.new("04-rue-principale", "Rue Principale")
  cartes << Carte_QD.new("05-le-barrage", "Le Barrage sur le Luol")
  cartes << Carte_QD.new("06-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte_QD.new("07-pont-luol", "Pont sur le Luol")
  cartes << Carte_QD.new("08-usine-charnivet", "Usine du Charnivet")
  cartes << Carte_QD.new("09-rue-principale", "Rue Principale")
  cartes << Carte_QD.new("10-vue-generale", "Vue Générale")
  cartes << Carte_QD.new("11-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte_QD.new("12-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte_QD.new("13-vue-generale", "Vue Générale")
  cartes << Carte_QD.new("14-vue-generale", "Vue Générale")
  cartes << Carte_QD.new("15-rue-village", "Rue Village")
  cartes << Carte_QD.new("16-eglise", "L'Eglise")
  cartes << Carte_QD.new("17-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte_QD.new("18-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte_QD.new("19-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte_QD.new("20-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte_QD.new("21-vergers", "Vergers vers les Cigales")
  cartes << Carte_QD.new("22-terrain-municipal", "Terrain Municipal")
  cartes << Carte_QD.new("23-entree-propriete", "Entrée des Cigales")
  cartes << Carte_QD.new("24-terrain-sport", "Terrain de Sport")
  cartes << Carte_QD.new("25-terrain-sport", "Terrain de Sport")
  cartes << Carte_QD.new("26-batiment-cigales", "Bâtiment des Cigales")
  cartes << Carte_QD.new("27-route-nationale", "Route Nationale")
  cartes << Carte_QD.new("28-batiment-cigales", "Bâtiment des Cigales")
  cartes << Carte_QD.new("29-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte_QD.new("30-vue-generale-aerienne", "Vue Générale Aérienne")
  # Renvoie la liste des cartes postales
  cartes
end