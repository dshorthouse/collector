# encoding: utf-8

module Collector
  class AgentClassifier

    def initialize
      @dir = File.join(COLLECTOR.root, 'lib', 'agent_classification')
      @classifier = SnapshotMadeleine.new(@dir) {
        Classifier::Bayes.new 'person', 'people', 'organization'
      }
    end

    def train
      data = YAML.load(File.read(File.join(@dir, 'train.yml')))
      data.each do |key,value|
        value.each do |v|
          @classifier.system.train key.to_sym, v
        end
      end
      @classifier.take_snapshot
    end

    def classify(txt)
      @classifier.system.classify(txt)
    end

  end
end