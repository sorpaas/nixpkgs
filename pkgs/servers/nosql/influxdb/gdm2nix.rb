#!/usr/bin/env ruby
#
#
require "json"

redirects = {
  "collectd.org" => "github.com/collectd/go-collectd",
  "golang.org/x/crypto" => "github.com/golang/crypto",
  "golang.org/x/tools" => "github.com/golang/tools",
  "gopkg.in/fatih/pool.v2" => "github.com/fatih/pool",
}

deps = File.read("Godeps").lines.map do |line|
  (name, rev) = line.split(" ")

  host = redirects.fetch(name, name)

  url = "https://#{host}.git"

  xxx = JSON.load(`nix-prefetch-git #{url} #{rev}`)
  
  <<-EOS
  {
    goPackagePath= "#{name}";
    fetch= {
      type= "git";
      url= "#{url}";
      rev= "#{rev}";
      sha256= "#{xxx['sha256']}";
    };
  }
  EOS
end

File.write("deps.nix", "[\n#{deps.join('')}\n]")
