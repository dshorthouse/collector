# encoding: utf-8
require 'byebug'

# WIP - Disambiguate / Cluster agents based on co-recorders, taxa identified, date ranges
# Given a Hash: { "Sperling" :  { "9868" : ["Frania", "Maddison", "Shaw"] }, { "9915" : ["Maddison"] }, { "10352" : ["Powell", "Rubinoff", "Shaw"] } }
# Merge agent.ids 9868, 9915, 10352 and (somehow) choose the best agent.family and agent.given to represent the cluster

module Collector
  module Disambiguator
    
    def self.collect_similar_family
      dups = {}
      duplicates = Agent.group(:family).count.map{ |k,v| k if v > 1 }.compact
      duplicates.each do |d|
        dups[d] = {}
        Agent.where(family: d).find_each do |a|
          dups[d][a.id] = a.recordings_with.map{ |k| k[:family] }
        end
      end
    end

  end
end