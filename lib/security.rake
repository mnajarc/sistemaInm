namespace :security do
  desc "Run security analysis with Brakeman"
  task :scan do
    system "brakeman -z --no-progress"
  end

  desc "Run bundle audit"
  task :audit do
    system "bundle-audit check --update"
  end

  desc "Run all security checks"
  task all: [ :scan, :audit ]
end
