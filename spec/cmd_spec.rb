# frozen_string_literal: true

require 'spec_helper'

describe Sh::Cmd do
  it 'can build a shell command with a block' do
    cmd = Sh::Cmd.new('git') do |c|
      c.arg 'log'
      c.opt '--oneline'
    end

    expect(cmd.to_s).to eq 'git log --oneline'
  end

  it 'can build a shell command with a chain' do
    cmd = Sh::Cmd.new('git').arg('log').opt('--oneline')
    expect(cmd.to_s).to eq 'git log --oneline'
  end

  it 'can string args and opts together in any order' do
    cmd = Sh::Cmd.new('git')
                 .arg('log')
                 .opt('--oneline')
                 .opt('decorate=full')
                 .arg('since...until').opt('--')
                 .arg('pathname')
    expect(cmd.to_s).to eq 'git log --oneline decorate=full since...until -- pathname'
  end

  it 'can take multiple args or opts at once' do
    cmd = Sh::Cmd.new('git')
                 .arg('log')
                 .opt('--oneline', 'decorate=full')
                 .arg('since...until', '--', 'pathname')
    expect(cmd.to_s).to eq 'git log --oneline decorate=full since...until -- pathname'
  end
end
