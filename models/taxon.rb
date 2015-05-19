class Taxon < ActiveRecord::Base
  has_many :determinations, :through => :taxon_determiners, :source => :agent
  has_many :taxon_determiners
end