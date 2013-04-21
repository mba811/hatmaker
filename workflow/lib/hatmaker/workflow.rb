class Hatmaker::Workflow
  attr_reader :author, :description, :download_link, :uid, :name, :version

  def initialize(params)
    @author        = params['author']
    @description   = params['description']
    @download_link = params['download_link']
    @name          = params['name']
    @version       = params['version']

    @uid           = "#{@author}_#{@name}"
  end

  def to_json
    Oj.dump(self)
  end

  def self.search(query)
    query = Regexp.escape(query)

    @workflows ||= self.all
    @workflows.select { |w| w.name =~ /#{query}/i }
  end

  private

  def self.all
    AlfredWorkflow.all
  end
end
