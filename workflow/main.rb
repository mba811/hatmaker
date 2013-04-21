#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require 'bundle/bundler/setup'
require 'alfred'
require 'oj'
require 'open-uri'

require File.join(File.dirname(__FILE__), 'lib/alfred_workflow')
require File.join(File.dirname(__FILE__), 'lib/hatmaker')
require File.join(File.dirname(__FILE__), 'lib/hatmaker/alfred')
require File.join(File.dirname(__FILE__), 'lib/hatmaker/workflow')

def search(query, feedback)
  workflows = Hatmaker::Workflow.search(query)
  workflows.each do |workflow|
    feedback.add_item({
      :uid      => workflow.uid,
      :title    => workflow.name,
      :subtitle => workflow.description,
      :arg      => workflow.to_json
    })
  end
end

def install(json, feedback, alfred_setting)
  workflow = Oj.load(json)

  File.open('/tmp/workflow.alfredworkflow', 'wb') do |saved_file|
    open(workflow.download_link, 'rb') do |read_file|
      saved_file.write(read_file.read)
    end
  end

  setting = alfred_setting.load
  setting[workflow.name] = workflow.version
  alfred_setting.dump setting

  `open /tmp/workflow.alfredworkflow`
end

def outdated(feedback, alfred_setting)
  setting = alfred_setting.load
  setting.each do |s|
    next unless s.first.is_a? String

    workflows = Hatmaker::Workflow.search(s.first)
    new_release = workflows.find { |w| w.name == s.first && w.version.to_f > s.last.to_f }

    if new_release
      feedback.add_item({
        :uid      => new_release.uid,
        :title    => new_release.name,
        :subtitle => "v#{new_release.version} by #{new_release.author}",
        :arg      => new_release.to_json
      })
    end
  end
end

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  feedback = alfred.feedback

  command   = ARGV[0]
  arguments = ARGV[1]

  case command
  when /search/
    search arguments, feedback
  when /install/
    install arguments, feedback, alfred.setting
  when /outdated/
    outdated feedback, alfred.setting
  end

  if feedback.items.none?
    feedback.add_item({
      :uid      => 'nothingfound',
      :title    => arguments ? "No workflows found with '#{arguments}'" : 'All workflows are up to date!',
      :valid    => 'no'
    })
  end

  puts feedback.to_xml
end

