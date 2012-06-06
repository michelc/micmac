# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?


class Carte
  attr_accessor :url, :titre

  def initialize(url, titre)
    @url = url
    @titre = titre
  end
end


# Index : affiche la page d'index
get '/' do
  @cartes = quick_and_dirty_db()
  erb :index
end


# Index : affiche la page d'index
get '/carte/:url' do
  cartes = quick_and_dirty_db()
  # @carte = cartes.select {|c| c.url == params[:url] }[0]
  @carte = cartes.find {|c| c.url == params[:url] }
  erb :carte
end


def quick_and_dirty_db()
  # Initialise la liste des cartes postales
  cartes = []
  # Insére les différentes cartes postales
  cartes << Carte.new("01-ardeche", "L'Ardèche à Saint-Privat")
  cartes << Carte.new("02-ardeche", "L'Ardèche à Saint-Privat")
  cartes << Carte.new("03-vue-generale", "Vue Générale")
  cartes << Carte.new("04-rue-principale", "Rue Principale")
  cartes << Carte.new("05-le-barrage", "Le Barrage sur le Luol")
  cartes << Carte.new("06-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte.new("07-pont-luol", "Pont sur le Luol")
  cartes << Carte.new("08-usine-charnivet", "Usine du Charnivet")
  cartes << Carte.new("09-rue-principale", "Rue Principale")
  cartes << Carte.new("10-vue-generale", "Vue Générale")
  cartes << Carte.new("11-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte.new("12-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte.new("13-vue-generale", "Vue Générale")
  cartes << Carte.new("14-vue-generale", "Vue Générale")
  cartes << Carte.new("15-rue-village", "Rue Village")
  cartes << Carte.new("16-eglise", "L'Eglise")
  cartes << Carte.new("17-vue-generale-aerienne", "Vue Générale Aérienne")
  cartes << Carte.new("18-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte.new("19-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte.new("20-marche-aux-fruits", "Le Marché aux Fruits")
  cartes << Carte.new("21-vergers", "Vergers vers les Cigales")
  # Renvoie la liste des cartes postales
  cartes
end