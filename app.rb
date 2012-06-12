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


# Index : affiche la page d'index
get '/' do
  @cartes = Carte.all(:order => [:id.asc])
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


# Insert : insère de nouvelles cartes
get '/insert' do
  Carte.new({url: '31-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  Carte.new({url: '32-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  Carte.new({url: '33-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  Carte.new({url: '34-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  Carte.new({url: '35-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  Carte.new({url: '36-vue-generale-aerienne', titre: 'Vue Générale Aérienne'}).save
  @cartes = Carte.all(:order => [:id.asc])
  erb :index
end